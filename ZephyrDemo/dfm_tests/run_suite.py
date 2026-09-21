#!/usr/bin/env python3
"""Build and run the sequential DFM test variants.

Run without arguments to build and execute the complete M3 suite. Select one
variant or let the harness locate and build one individual test case:

    python dfm_tests/run_suite.py --variants m3_os
    python dfm_tests/run_suite.py --testcase 1016

For a physical board, the harness reads the target console directly while it
flashes each image and waits for its target-side completion marker:

    python dfm_tests/run_suite.py --board my_board --com auto-detect

Physical-board mode requires pyserial. The script discovers west and a Zephyr
workspace automatically, so a virtual environment does not need to be
activated manually.
"""

from __future__ import annotations

import argparse
from collections import Counter
import csv
from dataclasses import dataclass
import datetime as dt
import json
import os
from pathlib import Path
import queue
import re
import secrets
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time
from typing import Any, Callable, Iterable, Sequence, TextIO

try:
    from .log_watchdog import (
        WATCHDOG_TIMEOUT_EXIT_CODE,
        start_watchdog,
        stop_watchdog,
    )
    from .payload_review import (
        REASONING_LEVELS,
        ReviewTarget,
        normalize_model,
        postprocess_suite,
        run_agentic_review,
    )
    from .agent_review_benchmark import run_benchmark
except ImportError:  # Direct invocation: python dfm_tests/run_suite.py
    from log_watchdog import (
        WATCHDOG_TIMEOUT_EXIT_CODE,
        start_watchdog,
        stop_watchdog,
    )
    from payload_review import (
        REASONING_LEVELS,
        ReviewTarget,
        normalize_model,
        postprocess_suite,
        run_agentic_review,
    )
    from agent_review_benchmark import run_benchmark


# Deliberately keep the configuration visible and fixed. The script is a
# reviewed test harness, not a general Zephyr build frontend.
SCRIPT_DIR = Path(__file__).resolve().parent
APP_DIR = SCRIPT_DIR.parent
BUILD_ROOT = APP_DIR / "build" / "dfm_tests"
LOG_PATH = APP_DIR / "dfm_test_run.log"
QEMU_LOG_PATH = APP_DIR / "qemu_last_session.log"
ARTIFACT_ROOT = APP_DIR / "dfm_test_artifacts"
DEFAULT_BOARD = "qemu_cortex_m3"
QEMU_RUN_TARGET = "run"
SDK_VERSION = "1.0.1"  # Matches README.md and the checked-in VS Code tasks.
BUILD_TIMEOUT_SECONDS = 30 * 60
FLASH_TIMEOUT_SECONDS = 10 * 60
RUN_TIMEOUT_SECONDS = 10 * 60
RUN_IDLE_TIMEOUT_SECONDS = 30
DEFAULT_COM_PORT = "auto-detect"
DEFAULT_SERIAL_BAUD_RATE = 115200
BOARD_SERIAL_BAUD_RATES = {
    "b_u585i_iot02a": 4 * DEFAULT_SERIAL_BAUD_RATE,
}
SERIAL_PROBE_SECONDS = 5
SERIAL_PROBE_MAX_BYTES = 1024
SERIAL_IDENTITY_MARKER = b"Percepio"
SERIAL_READ_TIMEOUT_SECONDS = 0.1
GRACEFUL_STOP_SECONDS = 5
FORCED_STOP_SECONDS = 5
WINDOWS_JOB_CHILD_FLAG = "--_windows-job-child"
DETECT_DESCRIPTION_MAX_CHARS = 100
TRACE_EVENT_TEXT_MAX_CHARS = 49
DFM_HEADER_MAGIC = b"PDfm"
DATA_LINE_PATTERN = re.compile(
    r"\[\[ DATA:\s*((?:[0-9A-Fa-f]{2}(?:\s+|(?=\]\])))+)\]\]"
)
DFM_DATA_LINE_PATTERN = re.compile(
    r"^\[\[ DATA:\s*((?:[0-9A-Fa-f]{2}\s*)+)\]\]$"
)
DFM_BLOCK_START_MARKER = "[[ DevAlert Data Begins ]]"
DFM_BLOCK_END_PATTERN = re.compile(
    r"^\[\[ DevAlert Data Ended\. Checksum: (\d+) \]\]$"
)
TARGET_FAILURE_PATTERN = re.compile(
    r"^DFMT:(?:HARNESS_FAIL:[^\r\n]*|CHECK:[^:\r\n]+:FAIL:[^\r\n]*)$",
    re.MULTILINE,
)


def reset_artifact_root() -> None:
    """Replace the artifact root with an empty directory for this invocation."""
    app_dir = APP_DIR.resolve()
    artifact_root = ARTIFACT_ROOT.resolve()

    # Keep recursive removal tied to the one fixed directory beside this
    # harness. Refuse symlinks, junctions, or future path changes that resolve
    # anywhere else.
    if (
        artifact_root.parent != app_dir
        or artifact_root.name != "dfm_test_artifacts"
    ):
        raise RuntimeError(
            f"Refusing to clear unexpected artifact path: {artifact_root}"
        )

    if ARTIFACT_ROOT.exists():
        shutil.rmtree(ARTIFACT_ROOT)
    ARTIFACT_ROOT.mkdir(parents=False)


class WindowsJob:
    """Own a Windows process tree and kill all members when closed."""

    # The structures mirror JOBOBJECT_EXTENDED_LIMIT_INFORMATION from the
    # Windows SDK. They live here to keep the platform-specific code together.
    def __init__(self) -> None:
        import ctypes
        from ctypes import wintypes

        class BasicLimitInformation(ctypes.Structure):
            _fields_ = [
                ("PerProcessUserTimeLimit", ctypes.c_longlong),
                ("PerJobUserTimeLimit", ctypes.c_longlong),
                ("LimitFlags", wintypes.DWORD),
                ("MinimumWorkingSetSize", ctypes.c_size_t),
                ("MaximumWorkingSetSize", ctypes.c_size_t),
                ("ActiveProcessLimit", wintypes.DWORD),
                ("Affinity", ctypes.c_size_t),
                ("PriorityClass", wintypes.DWORD),
                ("SchedulingClass", wintypes.DWORD),
            ]

        class IoCounters(ctypes.Structure):
            _fields_ = [
                ("ReadOperationCount", ctypes.c_ulonglong),
                ("WriteOperationCount", ctypes.c_ulonglong),
                ("OtherOperationCount", ctypes.c_ulonglong),
                ("ReadTransferCount", ctypes.c_ulonglong),
                ("WriteTransferCount", ctypes.c_ulonglong),
                ("OtherTransferCount", ctypes.c_ulonglong),
            ]

        class ExtendedLimitInformation(ctypes.Structure):
            _fields_ = [
                ("BasicLimitInformation", BasicLimitInformation),
                ("IoInfo", IoCounters),
                ("ProcessMemoryLimit", ctypes.c_size_t),
                ("JobMemoryLimit", ctypes.c_size_t),
                ("PeakProcessMemoryUsed", ctypes.c_size_t),
                ("PeakJobMemoryUsed", ctypes.c_size_t),
            ]

        self._ctypes = ctypes
        self._kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        self._kernel32.CreateJobObjectW.argtypes = [
            ctypes.c_void_p,
            wintypes.LPCWSTR,
        ]
        self._kernel32.CreateJobObjectW.restype = wintypes.HANDLE
        self._kernel32.SetInformationJobObject.argtypes = [
            wintypes.HANDLE,
            ctypes.c_int,
            ctypes.c_void_p,
            wintypes.DWORD,
        ]
        self._kernel32.SetInformationJobObject.restype = wintypes.BOOL
        self._kernel32.AssignProcessToJobObject.argtypes = [
            wintypes.HANDLE,
            wintypes.HANDLE,
        ]
        self._kernel32.AssignProcessToJobObject.restype = wintypes.BOOL
        self._kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
        self._kernel32.CloseHandle.restype = wintypes.BOOL

        self._handle = self._kernel32.CreateJobObjectW(None, None)
        if not self._handle:
            raise ctypes.WinError(ctypes.get_last_error())

        information = ExtendedLimitInformation()
        information.BasicLimitInformation.LimitFlags = 0x00002000
        if not self._kernel32.SetInformationJobObject(
            self._handle,
            9,  # JobObjectExtendedLimitInformation
            ctypes.byref(information),
            ctypes.sizeof(information),
        ):
            error = ctypes.WinError(ctypes.get_last_error())
            self.close()
            raise error

    def assign(self, process: subprocess.Popen[str]) -> None:
        if not self._kernel32.AssignProcessToJobObject(
            self._handle, int(process._handle)
        ):
            raise self._ctypes.WinError(self._ctypes.get_last_error())

    def close(self) -> bool:
        if not self._handle:
            return True
        closed = bool(self._kernel32.CloseHandle(self._handle))
        self._handle = None
        return closed


def windows_job_child(command: Sequence[str]) -> int:
    """Wait until the parent assigns this process to its Job Object."""

    if sys.stdin.read(1) != "G":
        return 125
    try:
        return subprocess.call(list(command))
    except OSError:
        return 127


@dataclass(frozen=True)
class Variant:
    name: str
    overlay: str
    test_ids: tuple[str, ...]
    build_label: str
    qemu_supported: bool = True

    @property
    def revision(self) -> str:
        """Short build label stored in DFM Revision metadata."""

        return self.build_label


# Keep this order synchronized with test_runner.c and the test plan.
VARIANTS: tuple[Variant, ...] = (
    Variant(
        "m3_o0",
        "o0.conf",
        ("1001", "1003", "1012"),
        "Build-M3-O0",
    ),
    Variant("m3_og", "og.conf", ("1013",), "Build-M3-Og"),
    Variant(
        "m3_os",
        "os.conf",
        (
            "1002",
            "1004",
            "1005",
            "1006",
            "1007",
            "1008",
            "1009",
            "1011",
            "1014",
            "1016",
            "1017",
            "1018",
            "1019",
            "1021",
            # Keep the robustness case last so a future regression cannot hide
            # the ordinary -Os cases.
            "1010",
        ),
        "Build-M3-Os",
    ),
    Variant(
        "m3_no_coredump",
        "no_coredump.conf",
        ("1015",),
        "Build-M3-NoCD",
    ),
    Variant(
        "m3_small_coredump",
        "small_coredump.conf",
        ("1020",),
        "Build-M3-SmallCD",
    ),
    Variant(
        "m3_stack128",
        "stack128.conf",
        ("1024",),
        "Build-M3-Stack128",
    ),
    Variant(
        "m33_qual",
        "m33.conf",
        ("1022", "1023"),
        "Build-M33-Qual",
        qemu_supported=False,
    ),
)
VARIANTS_BY_NAME = {variant.name: variant for variant in VARIANTS}
TESTCASE_VARIANTS = {
    test_id: variant
    for variant in VARIANTS
    for test_id in variant.test_ids
}
TESTCASE_ALERT_COUNTS = {
    "1001": 1,
    "1002": 1,
    "1003": 1,
    "1004": 1,
    "1005": 1,
    "1006": 2,
    "1007": 2,
    "1008": 1,
    "1009": 1,
    "1010": 0,
    "1011": 1,
    "1012": 1,
    "1013": 1,
    "1014": 1,
    "1015": 1,
    "1016": 2,
    "1017": 1,
    "1018": 1,
    "1019": 2,
    "1020": 2,
    "1021": 2,
    "1022": 1,
    "1023": 1,
    "1024": 1,
}
if TESTCASE_ALERT_COUNTS.keys() != TESTCASE_VARIANTS.keys():
    raise RuntimeError(
        "TESTCASE_ALERT_COUNTS must cover exactly the registered test cases"
    )
REVISION_LABEL_MAX_CHARS = 18

GREEN = "\033[32m"
RED = "\033[31m"
BLUE = "\033[34m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def _color_text(text: str, color: str, stream: object) -> str:
    isatty = getattr(stream, "isatty", None)
    enabled = (
        callable(isatty)
        and bool(isatty())
        and "NO_COLOR" not in os.environ
    )
    return f"{color}{text}{RESET}" if color and enabled else text


class Reporter:
    """Mirror every step and child-process line to console and the run log."""

    def __init__(self, log_file: TextIO) -> None:
        self.log_file = log_file
        self.use_color = sys.stdout.isatty() and "NO_COLOR" not in os.environ
        self._lock = threading.Lock()

    @staticmethod
    def timestamp() -> str:
        return dt.datetime.now().astimezone().isoformat(timespec="seconds")

    def status(self, label: str, message: str, color: str = "") -> None:
        plain = f"{self.timestamp()} [{label}] {message}"
        shown = f"{color}{plain}{RESET}" if self.use_color and color else plain
        with self._lock:
            print(shown, flush=True)
            self.log_file.write(plain + "\n")
            self.log_file.flush()

    def step(self, message: str) -> None:
        self.status("STEP", message, CYAN)

    def passed(self, message: str) -> None:
        self.status("PASS", message, GREEN)

    def failed(self, message: str) -> None:
        self.status("FAIL", message, RED)

    def warning(self, message: str) -> None:
        self.status("WARN", message, YELLOW)

    def test_passed(self, test_id: str, message: str) -> None:
        self.status("TEST PASS", f"{test_id}: {message}", GREEN)

    def test_failed(self, test_id: str, message: str) -> None:
        self.status("TEST FAIL", f"{test_id}: {message}", RED)

    def suite_passed(self, message: str) -> None:
        self.status("SUITE PASS", message, GREEN)

    def suite_failed(self, message: str) -> None:
        self.status("SUITE FAIL", message, RED)

    def info(self, message: str) -> None:
        self.status("INFO", message, BLUE)

    def child_line(
        self, line: str, raw_output_files: Sequence[TextIO] = ()
    ) -> None:
        # Device output remains unprefixed. QEMU output is also copied to the
        # selected device log so Detect can replay the DFM hex records.
        with self._lock:
            print(line, end="", flush=True)
            self.log_file.write(line)
            self.log_file.flush()
            for raw_output_file in raw_output_files:
                raw_output_file.write(line)
                raw_output_file.flush()


@dataclass(frozen=True)
class CommandResult:
    return_code: int
    timed_out: bool
    completion_seen: bool
    cleanup_ok: bool


@dataclass(frozen=True)
class SerialWaitResult:
    completion_seen: bool
    timed_out: bool
    read_failed: bool = False


@dataclass(frozen=True)
class SerialProbeResult:
    marker_seen: bool
    bytes_received: int
    read_error: str | None = None


@dataclass(frozen=True)
class WestCommand:
    command: tuple[str, ...]
    workspace: Path


@dataclass(frozen=True)
class SerializedAlert:
    """The fields needed to validate one DFM alert header."""

    alert_type: int
    description: str


@dataclass(frozen=True)
class DfmTransportBlock:
    """One binary DFM entry and its Serial-cloudport checksum."""

    payload: bytes
    checksum: int
    end_line: int


def crc16_ccitt(data: bytes) -> int:
    """Match Zephyr crc16_ccitt() and Detect txt2bin.py with seed zero."""

    crc = 0
    for byte in data:
        e = (crc ^ byte) & 0xFF
        f = (e ^ (e << 4)) & 0xFF
        crc = (
            (crc >> 8) ^ (f << 8) ^ (f << 3) ^ (f >> 4)
        ) & 0xFFFF
    return crc


def parse_dfm_transport_blocks(
    text: str,
) -> tuple[list[DfmTransportBlock], list[str]]:
    """Extract complete Serial DFM blocks and report damaged framing."""

    blocks: list[DfmTransportBlock] = []
    errors: list[str] = []
    payload: bytearray | None = None
    start_line = 0

    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped == DFM_BLOCK_START_MARKER:
            if payload is not None:
                errors.append(
                    f"line {line_number}: new DFM block started before the "
                    f"block from line {start_line} ended"
                )
            payload = bytearray()
            start_line = line_number
            continue

        data_match = DFM_DATA_LINE_PATTERN.fullmatch(stripped)
        if data_match is not None:
            if payload is None:
                errors.append(
                    f"line {line_number}: DFM data appeared without a "
                    "start marker"
                )
                continue
            payload.extend(bytes.fromhex(data_match.group(1)))
            continue
        if stripped.startswith("[[ DATA:"):
            errors.append(f"line {line_number}: malformed DFM hex data")
            continue

        end_match = DFM_BLOCK_END_PATTERN.fullmatch(stripped)
        if end_match is not None:
            if payload is None:
                errors.append(
                    f"line {line_number}: DFM checksum appeared without a "
                    "start marker"
                )
                continue
            checksum = int(end_match.group(1))
            if not payload:
                errors.append(
                    f"line {line_number}: DFM block from line {start_line} "
                    "contained no data"
                )
            elif checksum > 0xFFFF:
                errors.append(
                    f"line {line_number}: DFM checksum {checksum} exceeds 16 bits"
                )
            else:
                blocks.append(
                    DfmTransportBlock(bytes(payload), checksum, line_number)
                )
            payload = None
            start_line = 0
            continue
        if stripped.startswith("[[ DevAlert Data Ended"):
            errors.append(f"line {line_number}: malformed DFM checksum record")

    if payload is not None:
        errors.append(
            f"line {start_line}: DFM block did not contain an end/checksum marker"
        )
    return blocks, errors


def validate_dfm_transport_checksums(
    log_path: Path,
    reporter: Reporter,
) -> bool:
    """Detect serial-transfer corruption before logs reach Detect Receiver."""

    try:
        text = log_path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        reporter.failed(f"Could not inspect DFM transport checksums: {error}")
        return False

    blocks, parse_errors = parse_dfm_transport_blocks(text)
    for error in parse_errors:
        reporter.failed(f"Malformed DFM transport data: {error}")

    checked = 0
    skipped = 0
    mismatches = 0
    for index, block in enumerate(blocks, start=1):
        if block.checksum == 0:
            skipped += 1
            continue
        checked += 1
        calculated = crc16_ccitt(block.payload)
        if calculated != block.checksum:
            mismatches += 1
            reporter.failed(
                f"DFM transport checksum mismatch in block {index} ending "
                f"at line {block.end_line}: logged {block.checksum}, "
                f"calculated {calculated}, payload {len(block.payload)} bytes"
            )

    if parse_errors or mismatches:
        return False

    reporter.passed(
        f"DFM transport checksums: {checked} verified, "
        f"{skipped} skipped because checksum was 0"
    )
    return True


def read_serialized_alerts(log_path: Path) -> list[SerializedAlert]:
    """Decode DFM alert descriptions from a QEMU Receiver stream.

    Each ``DevAlert Data Begins`` block contains one alert record. The DFM
    header identifies the configured firmware and description field sizes,
    allowing this check to include the source callsite appended by DFM.
    """

    text = log_path.read_text(encoding="utf-8", errors="replace")
    alerts: list[SerializedAlert] = []
    for block in text.split("[[ DevAlert Data Begins ]]")[1:]:
        byte_tokens: list[str] = []
        for match in DATA_LINE_PATTERN.finditer(block):
            byte_tokens.extend(match.group(1).split())
        data = bytes(int(token, 16) for token in byte_tokens)
        header = data.find(DFM_HEADER_MAGIC)
        if header < 0 or len(data) < header + 20:
            continue

        firmware_field_size = data[header + 7]
        max_symbol_count = data[header + 8]
        description_field_size = int.from_bytes(
            data[header + 10 : header + 12], "little"
        )
        description_start = (
            header + 20 + firmware_field_size + (max_symbol_count * 8)
        )
        description_end = description_start + description_field_size
        if description_end > len(data):
            continue

        raw_description = data[description_start:description_end]
        description = raw_description.split(b"\0", 1)[0].decode(
            "utf-8", errors="replace"
        )
        alert_type = int.from_bytes(
            data[header + 16 : header + 20], "little"
        )
        alerts.append(SerializedAlert(alert_type, description))
    return alerts


def selected_alert_counts(test_ids: Sequence[str]) -> Counter[int]:
    """Return the exact serialized alert multiplicity for a target run."""

    return Counter(
        {
            int(test_id): TESTCASE_ALERT_COUNTS[test_id]
            for test_id in test_ids
            if TESTCASE_ALERT_COUNTS[test_id] > 0
        }
    )


def validate_alert_metadata(
    log_path: Path,
    reporter: Reporter,
    expected_counts: Counter[int],
) -> bool:
    """Require the selected alerts and enforce their description limit."""

    try:
        alerts = read_serialized_alerts(log_path)
    except (OSError, ValueError) as error:
        reporter.failed(f"Could not inspect alert descriptions: {error}")
        return False

    actual_counts = Counter(alert.alert_type for alert in alerts)
    counts_ok = actual_counts == expected_counts
    if counts_ok:
        summary = ", ".join(
            f"type {alert_type}={count}"
            for alert_type, count in sorted(expected_counts.items())
        )
        reporter.passed(
            "Serialized DFM alert counts match selection: "
            + (summary or "none expected")
        )
    else:
        for alert_type in sorted(expected_counts.keys() | actual_counts.keys()):
            expected = expected_counts[alert_type]
            actual = actual_counts[alert_type]
            if expected != actual:
                reporter.failed(
                    f"Serialized DFM alert count mismatch for type "
                    f"{alert_type}: expected {expected}, decoded {actual}"
                )

    if not alerts:
        return counts_ok

    too_long_for_trace = [
        alert
        for alert in alerts
        if len(alert.description) > TRACE_EVENT_TEXT_MAX_CHARS
    ]
    too_long_for_detect = [
        alert
        for alert in alerts
        if len(alert.description) > DETECT_DESCRIPTION_MAX_CHARS
    ]
    if too_long_for_trace or too_long_for_detect:
        for alert in too_long_for_trace:
            reporter.failed(
                f"Alert type {alert.alert_type} description has "
                f"{len(alert.description)} characters; the suite's "
                f"TraceRecorder budget is {TRACE_EVENT_TEXT_MAX_CHARS}: "
                f"{alert.description}"
            )
        for alert in too_long_for_detect:
            reporter.failed(
                f"Alert type {alert.alert_type} description has "
                f"{len(alert.description)} characters; Detect accepts "
                f"{DETECT_DESCRIPTION_MAX_CHARS}: {alert.description}"
            )
        return False

    longest = max(alerts, key=lambda alert: len(alert.description))
    reporter.passed(
        f"Alert descriptions fit TraceRecorder and Detect: {len(alerts)} "
        f"headers; longest "
        f"is type {longest.alert_type} at {len(longest.description)}/"
        f"{TRACE_EVENT_TEXT_MAX_CHARS} characters"
    )
    return counts_ok


def validate_target_harness(log_path: Path, reporter: Reporter) -> bool:
    """Reject explicit target-side failures even if the suite recovered."""

    try:
        text = log_path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        reporter.failed(f"Could not inspect target verdicts: {error}")
        return False

    failures = TARGET_FAILURE_PATTERN.findall(text)
    if failures:
        for failure in failures:
            reporter.failed(f"Target reported failure: {failure}")
        return False

    reporter.passed("Target harness reported no failures")
    return True


def report_unrun_test_cases(
    test_ids: Sequence[str], reporter: Reporter, reason: str
) -> None:
    """Make infrastructure failures visible for every affected test case."""

    for test_id in test_ids:
        reporter.test_failed(test_id, f"not run: {reason}")


def report_test_case_results(
    log_path: Path,
    test_ids: Sequence[str],
    reporter: Reporter,
) -> bool:
    """Report an explicit host-side PASS/FAIL line for every selected case."""

    try:
        text = log_path.read_text(encoding="utf-8", errors="replace")
        alerts = read_serialized_alerts(log_path)
    except (OSError, ValueError) as error:
        report_unrun_test_cases(
            test_ids, reporter, f"could not inspect target output: {error}"
        )
        return False

    actual_alert_counts = Counter(alert.alert_type for alert in alerts)
    too_long_description_types = {
        alert.alert_type
        for alert in alerts
        if len(alert.description) > TRACE_EVENT_TEXT_MAX_CHARS
        or len(alert.description) > DETECT_DESCRIPTION_MAX_CHARS
    }
    all_passed = True
    for test_id in test_ids:
        escaped_id = re.escape(test_id)
        started = re.search(
            rf"^DFMT:BEGIN:{escaped_id}:", text, re.MULTILINE
        ) is not None
        completed = re.search(
            rf"^DFMT:(?:RETURNED|RESUMED):{escaped_id}:",
            text,
            re.MULTILINE,
        ) is not None
        failed = re.search(
            rf"^DFMT:(?:HARNESS_FAIL:{escaped_id}:|"
            rf"CHECK:{escaped_id}[A-Z]*:FAIL:)",
            text,
            re.MULTILINE,
        ) is not None
        numeric_id = int(test_id)
        expected_alerts = TESTCASE_ALERT_COUNTS[test_id]
        actual_alerts = actual_alert_counts[numeric_id]
        alert_count_ok = actual_alerts == expected_alerts
        descriptions_ok = numeric_id not in too_long_description_types

        reasons: list[str] = []
        if not started:
            reasons.append("BEGIN marker missing")
        if not completed:
            reasons.append("completion marker missing")
        if failed:
            reasons.append("target reported FAIL")
        if not alert_count_ok:
            reasons.append(
                f"alerts expected={expected_alerts}, decoded={actual_alerts}"
            )
        if not descriptions_ok:
            reasons.append("an alert description exceeds a downstream limit")

        if reasons:
            reporter.test_failed(test_id, "; ".join(reasons))
            all_passed = False
        else:
            reporter.test_passed(
                test_id,
                f"target completed; serialized alerts={actual_alerts}",
            )
    return all_passed


def display_command(command: Sequence[str]) -> str:
    if os.name == "nt":
        return subprocess.list2cmdline(command)
    return shlex.join(command)


def read_pid_file(pid_file: Path | None) -> int | None:
    """Read a freshly created QEMU pidfile, if one is available."""

    if pid_file is None:
        return None
    try:
        pid = int(pid_file.read_text(encoding="ascii").strip())
    except (OSError, ValueError):
        return None
    return pid if pid > 0 else None


def pid_exists(pid: int) -> bool:
    """Check a PID using only standard-library and operating-system tools."""

    if os.name == "nt":
        result = subprocess.run(
            ["tasklist", "/FI", f"PID eq {pid}", "/FO", "CSV", "/NH"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        return any(
            len(row) > 1 and row[1].strip() == str(pid)
            for row in csv.reader(result.stdout.splitlines())
        )

    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def force_stop_pid(pid: int, include_tree: bool) -> None:
    """Force-stop one PID, optionally including its Windows descendants."""

    if not pid_exists(pid):
        return

    if os.name == "nt":
        command = ["taskkill", "/PID", str(pid)]
        if include_tree:
            command.append("/T")
        command.append("/F")
        subprocess.run(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    else:
        try:
            if include_tree:
                os.killpg(pid, signal.SIGKILL)
            else:
                os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def wait_for_pid_exit(pid: int, timeout_seconds: int) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while pid_exists(pid) and time.monotonic() < deadline:
        time.sleep(0.1)
    return not pid_exists(pid)


def process_group_exists(process_group_id: int) -> bool:
    """Check whether a POSIX process group still has any members."""

    if os.name == "nt":
        return False
    try:
        os.killpg(process_group_id, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def wait_for_process_group_exit(
    process_group_id: int, timeout_seconds: int
) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while (
        process_group_exists(process_group_id)
        and time.monotonic() < deadline
    ):
        time.sleep(0.1)
    return not process_group_exists(process_group_id)


def stop_process_tree(
    process: subprocess.Popen[str],
    reporter: Reporter,
    qemu_pid_file: Path | None,
    windows_job: WindowsJob | None,
) -> bool:
    """Stop the command tree and independently verify that QEMU exited."""

    # Zephyr starts QEMU with -pidfile. The file is removed before launch, so
    # this PID cannot be stale from an earlier suite invocation.
    qemu_pid = read_pid_file(qemu_pid_file)
    cleanup_was_needed = (
        process.poll() is None
        or qemu_pid is not None
        or process_group_exists(process.pid)
    )

    if process.poll() is None and qemu_pid is not None and process.stdin:
        # QEMU's multiplexed stdio monitor accepts Ctrl+A, x as a clean exit.
        try:
            process.stdin.write("\x01x")
            process.stdin.flush()
            process.wait(timeout=GRACEFUL_STOP_SECONDS)
        except (BrokenPipeError, OSError, subprocess.TimeoutExpired):
            pass

    job_closed = True
    process_group_stopped = True
    if os.name == "nt":
        # Closing a kill-on-close Job terminates every descendant even if
        # west, CMake, or Ninja has already exited or detached.
        job_closed = windows_job is None or windows_job.close()
        if process.poll() is None:
            force_stop_pid(process.pid, include_tree=True)
    else:
        # The child is the leader of a dedicated session/process group. Signal
        # that group even if the leader has already exited, because an orphaned
        # descendant may still be a member.
        if process_group_exists(process.pid):
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

    if process.poll() is None:
        try:
            process.wait(timeout=FORCED_STOP_SECONDS)
        except subprocess.TimeoutExpired:
            force_stop_pid(process.pid, include_tree=True)
            try:
                process.wait(timeout=FORCED_STOP_SECONDS)
            except subprocess.TimeoutExpired:
                pass

    if os.name != "nt" and process_group_exists(process.pid):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process_group_stopped = wait_for_process_group_exit(
            process.pid, FORCED_STOP_SECONDS
        )

    # taskkill of the top-level west process is not sufficient if an
    # intermediate CMake/Ninja process has already become orphaned. Stop and
    # verify the QEMU PID directly as a second, independent cleanup path.
    if qemu_pid is not None and pid_exists(qemu_pid):
        force_stop_pid(qemu_pid, include_tree=os.name == "nt")

    wrapper_stopped = process.poll() is not None or wait_for_pid_exit(
        process.pid, FORCED_STOP_SECONDS
    )
    qemu_stopped = qemu_pid is None or wait_for_pid_exit(
        qemu_pid, FORCED_STOP_SECONDS
    )

    if qemu_pid_file is not None and qemu_stopped:
        try:
            qemu_pid_file.unlink(missing_ok=True)
        except OSError as error:
            reporter.failed(f"Could not remove QEMU pidfile: {error}")
            qemu_stopped = False

    cleanup_ok = (
        job_closed
        and process_group_stopped
        and wrapper_stopped
        and qemu_stopped
    )
    if not cleanup_ok:
        reporter.failed(
            "Process cleanup incomplete: "
            f"job_closed={job_closed}, "
            f"process_group_stopped={process_group_stopped}, "
            f"wrapper_stopped={wrapper_stopped}, "
            f"qemu_stopped={qemu_stopped}, "
            f"qemu_pid={qemu_pid if qemu_pid is not None else 'unknown'}"
        )
    elif cleanup_was_needed:
        reporter.passed("Process cleanup verified")
    return cleanup_ok


def run_command(
    command: Sequence[str],
    reporter: Reporter,
    timeout_seconds: int,
    completion_marker: str | None = None,
    *,
    cwd: Path,
    environment: dict[str, str],
    raw_output_paths: Sequence[Path] = (),
    idle_timeout_seconds: int | None = None,
    qemu_pid_file: Path | None = None,
) -> CommandResult:
    """Run one command, log all output, enforce timeout, and find a marker."""

    reporter.step(f"Command: {display_command(command)}")
    creation_flags = subprocess.CREATE_NEW_PROCESS_GROUP if os.name == "nt" else 0
    windows_job: WindowsJob | None = None
    launch_command = list(command)

    # On Windows, first launch a tiny copy of this script that waits for a
    # one-byte handshake. Assign that process to a kill-on-close Job Object
    # before allowing it to start west. Every later shell, CMake, Ninja, and
    # QEMU process is then born inside the same owned job without a race.
    if os.name == "nt":
        try:
            windows_job = WindowsJob()
        except OSError as error:
            reporter.failed(f"Could not create Windows Job Object: {error}")
            return CommandResult(1, False, False, False)
        launch_command = [
            sys.executable,
            str(Path(__file__).resolve()),
            WINDOWS_JOB_CHILD_FLAG,
            *command,
        ]

    if qemu_pid_file is not None:
        try:
            qemu_pid_file.unlink(missing_ok=True)
        except OSError as error:
            reporter.failed(f"Could not clear stale QEMU pidfile: {error}")
            if windows_job is not None:
                windows_job.close()
            return CommandResult(1, False, False, False)

    try:
        process = subprocess.Popen(
            launch_command,
            cwd=cwd,
            env=environment,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
            creationflags=creation_flags,
            start_new_session=os.name != "nt",
        )
    except OSError as error:
        if windows_job is not None:
            windows_job.close()
        reporter.failed(f"Could not start command: {error}")
        return CommandResult(127, False, False, False)

    completion_seen = False
    timed_out = False
    cleanup_ok = True
    startup_failed = False
    raw_output_files: list[TextIO] = []

    # This finally block begins immediately after Popen. It therefore owns the
    # child tree even if setup, log opening, output handling, or Ctrl+C fails.
    try:
        if windows_job is not None:
            try:
                # Popen._handle is Python's Windows process handle. Access
                # stays isolated here because no portable public equivalent
                # exists.
                windows_job.assign(process)
                assert process.stdin is not None
                process.stdin.write("G")
                process.stdin.flush()
            except (OSError, BrokenPipeError) as error:
                reporter.failed(
                    "Could not assign command to Windows Job Object: "
                    f"{error}"
                )
                startup_failed = True

        if not startup_failed:
            assert process.stdout is not None
            output_queue: queue.Queue[str | None] = queue.Queue()

            def read_output() -> None:
                for child_line in process.stdout:
                    output_queue.put(child_line)
                output_queue.put(None)

            reader = threading.Thread(target=read_output, daemon=True)
            reader.start()
            started = time.monotonic()
            last_output = started

            # main() truncates the QEMU log once. Each QEMU command appends.
            for raw_output_path in raw_output_paths:
                try:
                    raw_output_files.append(
                        raw_output_path.open("a", encoding="utf-8", newline="\n")
                    )
                except OSError as error:
                    reporter.failed(
                        f"Could not open QEMU output log {raw_output_path}: {error}"
                    )
                    startup_failed = True
                    break

        while not startup_failed:
            now = time.monotonic()
            if now - started > timeout_seconds:
                timed_out = True
                reporter.failed(f"Command timed out after {timeout_seconds} seconds")
                break
            if (
                idle_timeout_seconds is not None
                and now - last_output > idle_timeout_seconds
            ):
                timed_out = True
                reporter.failed(
                    "Command produced no output for "
                    f"{idle_timeout_seconds} seconds"
                )
                break

            try:
                line = output_queue.get(timeout=0.2)
            except queue.Empty:
                if process.poll() is not None and not reader.is_alive():
                    break
                continue

            if line is None:
                break

            last_output = time.monotonic()
            reporter.child_line(line, raw_output_files)
            if completion_marker and completion_marker in line:
                completion_seen = True
                reporter.info(f"Observed completion marker: {completion_marker}")
                # The target intentionally idles after this marker.
                break
    finally:
        for raw_output_file in raw_output_files:
            raw_output_file.close()
        cleanup_ok = stop_process_tree(
            process, reporter, qemu_pid_file, windows_job
        )

    return_code = process.poll()
    if return_code is None:
        return_code = 1
    if startup_failed and return_code == 0:
        return_code = 1
    return CommandResult(return_code, timed_out, completion_seen, cleanup_ok)


def load_pyserial() -> tuple[Any, Any]:
    """Load pyserial only when physical-board mode actually needs it."""

    try:
        import serial
        from serial.tools import list_ports
    except ImportError as error:
        raise RuntimeError(
            "Physical-board mode requires pyserial. Install it with "
            "'python -m pip install pyserial'."
        ) from error
    return serial, list_ports


def serial_port_sort_key(device: str) -> tuple[int, int, str]:
    """Sort COM ports numerically, with the highest COM number first."""

    match = re.fullmatch(r"COM(\d+)", device, re.IGNORECASE)
    if match is not None:
        return (1, int(match.group(1)), device.casefold())
    return (0, 0, device.casefold())


def available_serial_ports(list_ports_module: Any) -> list[str]:
    """Return unique serial devices in the requested descending order."""

    devices = {port.device for port in list_ports_module.comports()}
    return sorted(devices, key=serial_port_sort_key, reverse=True)


def serial_baud_rate_for_board(board: str) -> int:
    """Return the host baud rate matching the checked-in board overlay."""

    board_name = board.split("/", 1)[0].split("@", 1)[0].casefold()
    return BOARD_SERIAL_BAUD_RATES.get(
        board_name, DEFAULT_SERIAL_BAUD_RATE
    )


def open_serial_port(
    serial_module: Any,
    device: str,
    baud_rate: int = DEFAULT_SERIAL_BAUD_RATE,
) -> Any:
    """Open one 8-N-1 target console with short blocking reads."""

    return serial_module.Serial(
        port=device,
        baudrate=baud_rate,
        bytesize=serial_module.EIGHTBITS,
        parity=serial_module.PARITY_NONE,
        stopbits=serial_module.STOPBITS_ONE,
        timeout=SERIAL_READ_TIMEOUT_SECONDS,
        write_timeout=1,
    )


def probe_serial_port(
    serial_module: Any,
    device: str,
    reporter: Reporter,
    *,
    variant_name: str,
    image_log_path: Path,
    baud_rate: int = DEFAULT_SERIAL_BAUD_RATE,
    timeout_seconds: float = SERIAL_PROBE_SECONDS,
    prepare_probe: Callable[[str], None] | None = None,
) -> SerialCapture | None:
    """Return a live capture if Percepio occurs in its first 1 KiB.

    ``prepare_probe`` runs after the port and its reader are active. Hardware
    mode uses it to flash the first successfully built image, ensuring that a
    board which did not already contain this application emits the marker. A
    successful capture remains open so the same flash and byte stream can be
    used as the authoritative first test run.
    """

    reporter.info(
        f"Probing {device} at {baud_rate} baud for up to "
        f"{timeout_seconds:g} seconds"
    )
    serial_port = None
    try:
        serial_port = open_serial_port(serial_module, device, baud_rate)
        serial_port.reset_input_buffer()
    except (OSError, serial_module.SerialException) as error:
        if serial_port is not None:
            serial_port.close()
        reporter.warning(f"Could not open {device}: {error}")
        return None

    capture = SerialCapture(
        serial_port,
        device,
        variant_name,
        image_log_path,
        reporter,
        baud_rate,
    )
    try:
        capture.start()
        if prepare_probe is not None:
            prepare_probe(device)
        result = capture.wait_for_identity(timeout_seconds)
    except BaseException:
        capture.close()
        raise

    if result.marker_seen:
        reporter.info(
            f"Selected {device}: found "
            f"{SERIAL_IDENTITY_MARKER.decode('ascii')!r} within "
            f"the first {result.bytes_received} bytes; continuing the "
            "same capture as the first test run"
        )
        return capture
    capture.close()
    if result.read_error is not None:
        reporter.warning(
            f"Read failed while probing {device}: {result.read_error}"
        )
        return None

    reporter.warning(
        f"Rejected {device}: {SERIAL_IDENTITY_MARKER.decode('ascii')!r} "
        f"was not found in {result.bytes_received} byte(s) within "
        f"{timeout_seconds:g} seconds"
    )
    return None


def auto_detect_serial_port(
    serial_module: Any,
    list_ports_module: Any,
    reporter: Reporter,
    *,
    variant_name: str,
    image_log_path: Path,
    baud_rate: int = DEFAULT_SERIAL_BAUD_RATE,
    prepare_probe: Callable[[str], None] | None = None,
) -> SerialCapture:
    """Return the live capture for the first port with the identity marker."""

    cycle = 0
    while True:
        cycle += 1
        devices = available_serial_ports(list_ports_module)
        if not devices:
            reporter.warning(
                "No serial ports found; restarting auto-detection in "
                f"{SERIAL_PROBE_SECONDS} seconds"
            )
            time.sleep(SERIAL_PROBE_SECONDS)
            continue

        reporter.info(
            f"COM auto-detection pass {cycle}: " + ", ".join(devices)
        )
        for device in devices:
            capture = probe_serial_port(
                serial_module,
                device,
                reporter,
                variant_name=variant_name,
                image_log_path=image_log_path,
                baud_rate=baud_rate,
                prepare_probe=prepare_probe,
            )
            if capture is not None:
                return capture

        reporter.warning(
            "No port emitted the Percepio marker; restarting the search "
            "from the highest COM number"
        )


class SerialCapture:
    """Stream a physical target console while tracking suite markers."""

    def __init__(
        self,
        serial_port: Any,
        device: str,
        variant_name: str,
        image_log_path: Path,
        reporter: Reporter,
        baud_rate: int = DEFAULT_SERIAL_BAUD_RATE,
    ) -> None:
        self.serial_port = serial_port
        self.device = device
        self.variant_name = variant_name
        self.image_log_path = image_log_path
        self.reporter = reporter
        self.baud_rate = baud_rate
        self._stop = threading.Event()
        self._complete = threading.Event()
        self._identity_seen = threading.Event()
        self._probe_limit_reached = threading.Event()
        self._thread: threading.Thread | None = None
        self._lock = threading.Lock()
        self._last_output = time.monotonic()
        self._read_error: str | None = None
        self._probe_bytes = bytearray()
        self._image_log: Any = None

    def start(self) -> None:
        self._image_log = self.image_log_path.open("wb")
        self._thread = threading.Thread(
            target=self._read_loop,
            name=f"serial-reader-{self.device}",
            daemon=True,
        )
        self._thread.start()
        self.reporter.info(
            f"Capturing all target output from {self.device} at "
            f"{self.baud_rate} baud"
        )

    def _read_loop(self) -> None:
        variant_bytes = self.variant_name.encode("ascii")
        begin_pattern = re.compile(
            rb"DFMT:SUITE_BEGIN:"
            + re.escape(variant_bytes)
            + rb":([0-9A-Fa-f]{8})"
        )
        expected_completion: bytes | None = None
        search_tail = b""

        while not self._stop.is_set():
            try:
                chunk = self.serial_port.read(256)
            except Exception as error:
                if not self._stop.is_set():
                    with self._lock:
                        self._read_error = str(error)
                return
            if not chunk:
                continue

            with self._lock:
                self._last_output = time.monotonic()
                if len(self._probe_bytes) < SERIAL_PROBE_MAX_BYTES:
                    remaining = SERIAL_PROBE_MAX_BYTES - len(self._probe_bytes)
                    self._probe_bytes.extend(chunk[:remaining])
                    if SERIAL_IDENTITY_MARKER in self._probe_bytes:
                        self._identity_seen.set()
                    if len(self._probe_bytes) == SERIAL_PROBE_MAX_BYTES:
                        self._probe_limit_reached.set()
            self._image_log.write(chunk)
            self._image_log.flush()
            self.reporter.child_line(
                chunk.decode("utf-8", errors="backslashreplace")
            )

            searchable = search_tail + chunk
            marker_message: str | None = None
            if expected_completion is None:
                begin = begin_pattern.search(searchable)
                if begin is not None:
                    run_id = begin.group(1)
                    expected_completion = (
                        b"DFMT:SUITE_COMPLETE:"
                        + variant_bytes
                        + b":"
                        + run_id
                    )
                    marker_message = (
                        "Observed fresh serial suite start: "
                        f"{self.variant_name}:{run_id.decode('ascii')}"
                    )

            if (
                expected_completion is not None
                and expected_completion in searchable
            ):
                self._complete.set()
                marker_message = (
                    "Observed serial completion marker: "
                    + expected_completion.decode("ascii")
                )

            if marker_message is not None:
                self.reporter.info(marker_message)
            search_tail = searchable[-256:]

    def wait_for_identity(self, timeout_seconds: float) -> SerialProbeResult:
        """Wait for the identity marker without stopping the capture thread."""

        deadline = time.monotonic() + timeout_seconds
        while True:
            if self._identity_seen.wait(0.05):
                with self._lock:
                    return SerialProbeResult(True, len(self._probe_bytes))
            with self._lock:
                read_error = self._read_error
                bytes_received = len(self._probe_bytes)
            if read_error is not None:
                return SerialProbeResult(False, bytes_received, read_error)
            if self._probe_limit_reached.is_set():
                return SerialProbeResult(False, bytes_received)
            if time.monotonic() >= deadline:
                return SerialProbeResult(False, bytes_received)

    def wait(
        self,
        timeout_seconds: int,
        idle_timeout_seconds: int,
    ) -> SerialWaitResult:
        started = time.monotonic()
        with self._lock:
            self._last_output = max(self._last_output, started)

        while True:
            if self._complete.wait(0.1):
                return SerialWaitResult(True, False)
            with self._lock:
                read_error = self._read_error
                last_output = self._last_output
            if read_error is not None:
                self.reporter.failed(
                    f"Serial read failed on {self.device}: {read_error}"
                )
                return SerialWaitResult(False, False, True)

            now = time.monotonic()
            if now - started > timeout_seconds:
                self.reporter.failed(
                    f"Serial suite timed out after {timeout_seconds} seconds"
                )
                return SerialWaitResult(False, True)
            if now - last_output > idle_timeout_seconds:
                self.reporter.failed(
                    f"{self.device} produced no output for "
                    f"{idle_timeout_seconds} seconds"
                )
                return SerialWaitResult(False, True)

    def close(self) -> None:
        self._stop.set()
        try:
            self.serial_port.close()
        finally:
            if self._thread is not None:
                self._thread.join(timeout=2)
            if self._image_log is not None:
                self._image_log.close()


def command_works(command: Sequence[str]) -> bool:
    try:
        result = subprocess.run(
            [*command, "--version"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def zephyr_bases() -> Iterable[Path]:
    """Yield likely Zephyr bases without scanning the entire computer."""

    candidates: list[Path] = []
    environment_base = os.environ.get("ZEPHYR_BASE")
    if environment_base:
        candidates.append(Path(environment_base).expanduser())

    for parent in (APP_DIR, *APP_DIR.parents):
        candidates.extend((parent, parent / "zephyr"))

    # These are the conventional layouts used by Zephyr's getting-started
    # guide. The first one also matches this repository's documented layout.
    candidates.extend(
        (
            Path.home() / "zephyrproject" / "zephyr",
            Path.home() / "zephyr-workspace" / "zephyr",
            Path.home() / "zephyr" / "zephyr",
        )
    )

    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.resolve()
        if resolved not in seen and (resolved / "west.yml").is_file():
            seen.add(resolved)
            yield resolved


def discover_west() -> WestCommand:
    """Find a usable west command without activating a virtual environment."""

    bases = list(zephyr_bases())
    base_arguments = ["-z", str(bases[0])] if bases else []

    west_on_path = shutil.which("west")
    if west_on_path:
        command = [west_on_path, *base_arguments]
        if command_works(command):
            workspace = bases[0].parent if bases else APP_DIR
            return WestCommand(tuple(command), workspace)

    current_python = [sys.executable, "-m", "west", *base_arguments]
    if command_works(current_python):
        workspace = bases[0].parent if bases else APP_DIR
        return WestCommand(tuple(current_python), workspace)

    for zephyr_base in bases:
        workspace = zephyr_base.parent
        if os.name == "nt":
            python_path = workspace / ".venv" / "Scripts" / "python.exe"
        else:
            python_path = workspace / ".venv" / "bin" / "python"
        command = [str(python_path), "-m", "west", "-z", str(zephyr_base)]
        if python_path.is_file() and command_works(command):
            return WestCommand(tuple(command), workspace)

    raise RuntimeError(
        "Could not find west. Install it on PATH or use a conventional "
        "<workspace>/.venv and <workspace>/zephyr layout."
    )


def discover_zephyr_sdk(west_workspace: Path) -> Path | None:
    """Use an explicit SDK environment value or a conventional installation."""

    configured = os.environ.get("ZEPHYR_SDK_INSTALL_DIR")
    if configured:
        path = Path(configured).expanduser().resolve()
        if (path / "sdk_version").is_file():
            return path

    candidates = sorted(
        {
            west_workspace.parent / f"zephyr-sdk-{SDK_VERSION}",
            *Path.home().glob("zephyr-sdk-*"),
            *west_workspace.parent.glob("zephyr-sdk-*"),
        },
        reverse=True,
    )
    return next((path.resolve() for path in candidates if (path / "sdk_version").is_file()), None)


def child_environment(sdk_path: Path | None) -> dict[str, str]:
    environment = os.environ.copy()
    # This opt-in is inherited by every suite child. It is consumed by the
    # Detect Client after the target run and is harmless to west/QEMU/flash.
    environment["DETECT_CLIENT_TEXT_OUTPUT"] = "1"
    if sdk_path:
        environment["ZEPHYR_SDK_INSTALL_DIR"] = str(sdk_path)

    # The SDK 1.0.1 QEMU build used by this project needs MinGW runtime DLLs on
    # Windows. Git for Windows is the documented conventional source.
    if os.name == "nt":
        mingw_runtime = Path("C:/Program Files/Git/mingw64/bin")
        if mingw_runtime.is_dir():
            environment["PATH"] = str(mingw_runtime) + os.pathsep + environment.get("PATH", "")
    return environment


def selected_variants(
    names: Sequence[str], include_hardware_only: bool = True
) -> list[Variant]:
    if not names or names == ["all"]:
        return [
            variant
            for variant in VARIANTS
            if include_hardware_only or variant.qemu_supported
        ]
    if "all" in names:
        raise ValueError("'all' cannot be combined with named variants")
    return [VARIANTS_BY_NAME[name] for name in names]


def west_pristine_mode(build_index: int) -> str:
    """Force-clean the first build; let west decide for later variants."""

    if build_index < 0:
        raise ValueError("build index cannot be negative")
    return "always" if build_index == 0 else "auto"


def trace_extensions_for_build(build_dir: Path) -> list[Path]:
    """Return Tracealyzer syscall extensions generated by this exact build."""

    return sorted(build_dir.glob("syscalls-v*.xml"))


def validate_build_labels(variants: Sequence[Variant]) -> None:
    """Keep Revision values safe for the 20-character downstream limit."""

    for variant in variants:
        label = variant.build_label
        if len(label) > REVISION_LABEL_MAX_CHARS:
            raise ValueError(
                f"build label {label!r} exceeds the "
                f"{REVISION_LABEL_MAX_CHARS}-character limit"
            )
        if Path(label).name != label or Path(label).is_absolute():
            raise ValueError(f"build label {label!r} is not a directory name")


def resolve_device_log(path: Path) -> Path:
    """Validate the QEMU device log owned by this harness invocation."""

    resolved = path.expanduser().resolve()
    if not resolved.parent.is_dir():
        raise ValueError(f"device-log directory does not exist: {resolved.parent}")
    if resolved.exists() and not resolved.is_file():
        raise ValueError(f"device log is not a regular file: {resolved}")

    generated_roots = (BUILD_ROOT.resolve(), ARTIFACT_ROOT.resolve())
    if any(
        resolved == root or root in resolved.parents
        for root in generated_roots
    ):
        raise ValueError(
            "device log must be outside build/dfm_tests and "
            f"dfm_test_artifacts: {resolved}"
        )
    if resolved == LOG_PATH.resolve():
        raise ValueError(
            f"device log conflicts with the orchestration log: {resolved}"
        )
    return resolved


def _positive_test_count(value: str) -> int:
    try:
        count = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("N must be an integer") from error
    if count < 1:
        raise argparse.ArgumentTypeError("N must be at least 1")
    return count


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build and run all sequential DFM test variants."
    )
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument(
        "--variants",
        nargs="+",
        choices=("all", *VARIANTS_BY_NAME),
        help="focused variant rerun; default: all",
    )
    selection.add_argument(
        "--testcase",
        choices=tuple(TESTCASE_VARIANTS),
        help="run one test case; its build variant is selected automatically",
    )
    parser.add_argument(
        "--board",
        default=DEFAULT_BOARD,
        help=f"Zephyr board target; default: {DEFAULT_BOARD}",
    )
    source = parser.add_mutually_exclusive_group()
    source.add_argument(
        "--com",
        metavar="PORT",
        help=(
            "physical target serial port; default for non-QEMU boards: "
            f"{DEFAULT_COM_PORT}"
        ),
    )
    source.add_argument(
        "--devicelog",
        type=Path,
        metavar="FILE",
        help=(
            "QEMU device-output log; default for boards containing 'qemu': "
            f"{QEMU_LOG_PATH.name}"
        ),
    )
    parser.add_argument(
        "--runner",
        help="optional west flash runner for a physical board",
    )
    parser.add_argument(
        "--skip-payload-processing",
        action="store_true",
        help=(
            "do not run the full Detect loader or offer Agentic payload review "
            "after the suite"
        ),
    )
    operation = parser.add_mutually_exclusive_group()
    operation.add_argument(
        "--agent-review-only",
        action="store_true",
        help=(
            "run only the Agentic review against existing Detect text "
            "artifacts; do not build, run QEMU, reset artifacts, or load Detect"
        ),
    )
    operation.add_argument(
        "--benchmark-agent-review",
        nargs="?",
        const=3,
        type=_positive_test_count,
        metavar="N",
        help=(
            "benchmark Luna/Terra/Sol at three reasoning levels against the "
            "first N existing tests in clean and fault-injected modes "
            "(default N when flag is present: 3)"
        ),
    )
    parser.add_argument(
        "--model",
        help=(
            "Codex model for ordinary Agentic review, for example 5.6-Sol or "
            "gpt-5.6-sol (default: current Codex configuration)"
        ),
    )
    parser.add_argument(
        "--reasoning-effort",
        type=str.casefold,
        choices=REASONING_LEVELS,
        help=(
            "reasoning level for ordinary Agentic review, for example medium "
            "(default: current Codex configuration)"
        ),
    )
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="answer yes to all post-suite confirmation prompts",
    )
    return parser


@dataclass
class SuiteRunState:
    """Minimal state needed by the post-suite payload pipeline."""

    artifacts_reset: bool = False
    targets: tuple[ReviewTarget, ...] = ()


def existing_review_targets(
    artifact_root: Path,
    *,
    testcase: str | None = None,
    variants: Sequence[str] | None = None,
) -> tuple[str, tuple[ReviewTarget, ...]]:
    """Reconstruct review targets from a completed Detect text export."""

    status_path = artifact_root / "detect-load-status.json"
    try:
        status = json.loads(status_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(
            f"A completed Detect export is required at {status_path}: {error}"
        ) from error
    if not isinstance(status, dict):
        raise ValueError(f"Invalid Detect status object in {status_path}")
    if status.get("state") != "complete" or status.get("exit_code") != 0:
        raise ValueError(
            f"Detect status is not complete and successful: {status_path}"
        )
    raw_tests = status.get("tests")
    if not isinstance(raw_tests, list):
        raise ValueError(f"Detect status has no test inventory: {status_path}")

    selected_variant_names: set[str] | None = None
    if variants and list(variants) != ["all"]:
        selected_variant_names = set(variants)
    targets: list[ReviewTarget] = []
    seen: set[str] = set()
    for raw_test_id in raw_tests:
        test_id = str(raw_test_id)
        variant = TESTCASE_VARIANTS.get(test_id)
        if variant is None or test_id in seen:
            continue
        if testcase is not None and test_id != testcase:
            continue
        if (
            selected_variant_names is not None
            and variant.name not in selected_variant_names
        ):
            continue
        seen.add(test_id)
        targets.append(
            ReviewTarget(
                test_id,
                variant.build_label,
                TESTCASE_ALERT_COUNTS[test_id],
            )
        )
    targets.sort(key=lambda target: int(target.test_id))
    if not targets:
        raise ValueError("No requested tests are present in the Detect export.")
    run_id = str(status.get("run_id") or "existing-payload-data")
    return run_id, tuple(targets)


def _run_existing_review_mode(
    parser: argparse.ArgumentParser,
    args: argparse.Namespace,
) -> int | None:
    """Handle explicit no-build review modes, or return None for a suite run."""

    if not args.agent_review_only and args.benchmark_agent_review is None:
        return None
    if args.skip_payload_processing:
        parser.error(
            "--skip-payload-processing cannot be combined with an existing-"
            "payload review mode"
        )
    if args.benchmark_agent_review is not None and (
        args.testcase is not None or args.variants is not None
    ):
        parser.error(
            "--benchmark-agent-review selects the first N tests itself and "
            "cannot be combined with --testcase or --variants"
        )
    if args.benchmark_agent_review is not None and (
        args.model is not None or args.reasoning_effort is not None
    ):
        parser.error(
            "--benchmark-agent-review uses its fixed model/reasoning matrix; "
            "do not combine it with --model or --reasoning-effort"
        )
    try:
        run_id, targets = existing_review_targets(
            ARTIFACT_ROOT,
            testcase=args.testcase if args.agent_review_only else None,
            variants=args.variants if args.agent_review_only else None,
        )
    except ValueError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 2

    if args.agent_review_only:
        accepted = run_agentic_review(
            APP_DIR,
            ARTIFACT_ROOT,
            run_id,
            targets,
            model=normalize_model(args.model),
            reasoning_effort=args.reasoning_effort,
        )
        return 0 if accepted else 1

    requested = args.benchmark_agent_review
    assert isinstance(requested, int)
    if requested > len(targets):
        print(
            f"FAIL: Benchmark requested {requested} tests, but the existing "
            f"Detect export contains only {len(targets)}.",
            file=sys.stderr,
        )
        return 2
    selected = targets[:requested]
    try:
        accurate, _output_root = run_benchmark(
            APP_DIR,
            ARTIFACT_ROOT,
            run_id,
            selected,
        )
    except KeyboardInterrupt:
        print("\nAgent-review benchmark interrupted by user.", file=sys.stderr)
        return 130
    except (OSError, ValueError) as error:
        print(f"FAIL: Agent-review benchmark setup failed: {error}", file=sys.stderr)
        return 2
    return 0 if accurate else 1


def _run_suite(args: argparse.Namespace, state: SuiteRunState) -> int:
    try:
        testcase = args.testcase
        board = args.board.strip()
        if not board:
            raise ValueError("board name cannot be empty")
        qemu_mode = "qemu" in board.casefold()
        hardware_mode = not qemu_mode
        serial_baud_rate = serial_baud_rate_for_board(board)
        variants = (
            [TESTCASE_VARIANTS[testcase]]
            if testcase is not None
            else selected_variants(
                args.variants or ["all"],
                include_hardware_only=hardware_mode,
            )
        )
        if qemu_mode and any(not variant.qemu_supported for variant in variants):
            names = ", ".join(
                variant.name for variant in variants if not variant.qemu_supported
            )
            raise ValueError(
                f"QEMU board {board} cannot run hardware-only variant(s): {names}"
            )
        validate_build_labels(variants)
        state.targets = tuple(
            ReviewTarget(
                test_id,
                variant.build_label,
                TESTCASE_ALERT_COUNTS[test_id],
            )
            for variant in variants
            for test_id in (
                (testcase,) if testcase is not None else variant.test_ids
            )
        )
        if hardware_mode and args.devicelog is not None:
            raise ValueError(
                "--devicelog is only valid when --board contains 'qemu'"
            )
        if qemu_mode and args.com is not None:
            raise ValueError(
                "--com is only valid when --board selects physical hardware"
            )
        if qemu_mode and args.runner is not None:
            raise ValueError("--runner is only valid for a physical board")
        runner = args.runner.strip() if args.runner else None
        if args.runner is not None and not runner:
            raise ValueError("runner name cannot be empty")
        requested_com = (
            (args.com or DEFAULT_COM_PORT).strip() if hardware_mode else None
        )
        if hardware_mode and not requested_com:
            raise ValueError("COM port cannot be empty")
        device_log = (
            resolve_device_log(args.devicelog or QEMU_LOG_PATH)
            if qemu_mode
            else None
        )
    except ValueError as error:
        print(_color_text(f"FAIL: {error}", RED, sys.stderr), file=sys.stderr)
        return 2

    try:
        reset_artifact_root()
        state.artifacts_reset = True
    except (OSError, RuntimeError) as error:
        print(
            _color_text(
                f"FAIL: Could not reset artifact directory: {error}",
                RED,
                sys.stderr,
            ),
            file=sys.stderr,
        )
        return 2

    # One QEMU device-log selection and one COM-port selection remain fixed
    # for the complete suite invocation.
    if qemu_mode:
        assert device_log is not None
        device_log.write_text("", encoding="utf-8", newline="\n")

    run_cookie = (secrets.randbits(32) or 1) if hardware_mode else 0

    with LOG_PATH.open("w", encoding="utf-8", newline="\n") as log_file:
        reporter = Reporter(log_file)
        reporter.step("Starting DFM test orchestration")
        reporter.info(f"Orchestration log: {LOG_PATH}")
        reporter.info(f"Board: {board}")
        if hardware_mode:
            reporter.info(
                f"Execution mode: physical board; requested COM: {requested_com}"
            )
            reporter.info(f"Serial settings: {serial_baud_rate} baud, 8-N-1")
            reporter.info(f"Flash runner: {runner or 'board default'}")
            reporter.info(f"Run cookie: 0x{run_cookie:08x}")
        else:
            reporter.info(f"Execution mode: QEMU; device log: {device_log}")
        reporter.info(f"Per-image artifacts reset for this run: {ARTIFACT_ROOT}")
        reporter.info(f"Build root: {BUILD_ROOT}")
        reporter.info("Variants: " + ", ".join(v.name for v in variants))
        reporter.info(f"Test case: {testcase or 'all cases in each variant'}")

        try:
            west = discover_west()
        except RuntimeError as error:
            reporter.failed(str(error))
            return 2
        sdk_path = discover_zephyr_sdk(west.workspace)
        environment = child_environment(sdk_path)
        reporter.info(f"West command: {display_command(west.command)}")
        reporter.info(f"West workspace: {west.workspace}")
        reporter.info(f"Zephyr SDK: {sdk_path if sdk_path else 'automatic CMake discovery'}")

        serial_module: Any = None
        list_ports_module: Any = None
        selected_com: str | None = None
        if hardware_mode:
            try:
                serial_module, list_ports_module = load_pyserial()
                assert requested_com is not None
                if requested_com.casefold() == DEFAULT_COM_PORT:
                    reporter.info(
                        "COM auto-detection is deferred until the first "
                        "firmware image has been built"
                    )
                else:
                    selected_com = requested_com
                    reporter.info(
                        f"COM selection locked for this suite: {selected_com}"
                    )
            except RuntimeError as error:
                reporter.suite_failed(str(error))
                return 2

        failed_variants: list[str] = []
        for build_index, variant in enumerate(variants):
            overlay = SCRIPT_DIR / "conf" / variant.overlay
            build_dir = BUILD_ROOT / variant.name
            pristine_mode = west_pristine_mode(build_index)
            selected_test_ids = (
                (testcase,) if testcase is not None else variant.test_ids
            )
            expected_alert_counts = selected_alert_counts(selected_test_ids)
            reporter.step(
                f"Variant {variant.name}; tests: {', '.join(selected_test_ids)}"
            )

            build_command = [
                *west.command,
                "build",
                "--board",
                board,
                f"--pristine={pristine_mode}",
                "--build-dir",
                str(build_dir),
                str(APP_DIR),
                "--",
                f"-DEXTRA_CONF_FILE={overlay.as_posix()}",
                f"-DDFM_TEST_VARIANT={variant.name}",
                f"-DDFM_TEST_CASE_ID={testcase or 0}",
            ]
            if hardware_mode:
                build_command.append(
                    f"-DDFM_TEST_RUN_COOKIE=0x{run_cookie:08x}"
                )
            if sdk_path:
                build_command.append(
                    f"-DZEPHYR_SDK_INSTALL_DIR={sdk_path.as_posix()}"
                )
            build = run_command(
                build_command,
                reporter,
                BUILD_TIMEOUT_SECONDS,
                cwd=west.workspace,
                environment=environment,
            )
            if build.return_code != 0 or build.timed_out:
                reporter.failed(f"Build {variant.name}")
                report_unrun_test_cases(
                    selected_test_ids, reporter, "firmware build failed"
                )
                failed_variants.append(variant.name)
                continue
            reporter.passed(f"Build {variant.name}")
            elf_path = build_dir / "zephyr" / "zephyr.elf"
            config_path = build_dir / "zephyr" / ".config"
            expected_revision = (
                'CONFIG_PERCEPIO_DFM_CFG_FIRMWARE_VERSION='
                f'"{variant.revision}"'
            )
            try:
                config_lines = config_path.read_text(
                    encoding="utf-8", errors="replace"
                ).splitlines()
            except OSError as error:
                reporter.failed(
                    f"Could not verify Revision in {config_path}: {error}"
                )
                report_unrun_test_cases(
                    selected_test_ids,
                    reporter,
                    "firmware configuration could not be verified",
                )
                failed_variants.append(variant.name)
                continue
            if expected_revision not in config_lines:
                reporter.failed(
                    f"Build {variant.name} has wrong DFM Revision; expected "
                    f"{variant.revision}"
                )
                report_unrun_test_cases(
                    selected_test_ids,
                    reporter,
                    "firmware Revision metadata is incorrect",
                )
                failed_variants.append(variant.name)
                continue
            reporter.passed(
                f"DFM Revision verified: {variant.revision}"
            )

            trace_extensions = trace_extensions_for_build(build_dir)
            if not trace_extensions:
                reporter.failed(
                    "Tracealyzer syscall extension was not generated in "
                    f"{build_dir}"
                )
                report_unrun_test_cases(
                    selected_test_ids,
                    reporter,
                    "Tracealyzer syscall extension is missing",
                )
                failed_variants.append(variant.name)
                continue

            artifact_dir = ARTIFACT_ROOT / variant.build_label
            try:
                artifact_dir.mkdir(parents=False, exist_ok=True)
                artifact_elf = artifact_dir / "zephyr.elf"
                artifact_config = artifact_dir / "zephyr.config"
                image_target_log = artifact_dir / (
                    "serial.log" if hardware_mode else "qemu.log"
                )
                shutil.copy2(elf_path, artifact_elf)
                shutil.copy2(config_path, artifact_config)
                for trace_extension in trace_extensions:
                    shutil.copy2(trace_extension, artifact_dir / trace_extension.name)
                # This stable path always describes only the newly copied
                # image. Replace rather than mix the previous run's output.
                image_target_log.write_bytes(b"")
            except OSError as error:
                reporter.failed(
                    f"Could not archive build {variant.name}: {error}"
                )
                report_unrun_test_cases(
                    selected_test_ids,
                    reporter,
                    "build artifacts could not be archived",
                )
                failed_variants.append(variant.name)
                continue
            reporter.info(f"Build ELF: {elf_path}")
            reporter.info(f"Build Kconfig: {config_path}")
            reporter.info(f"Saved ELF: {artifact_elf}")
            reporter.info(f"Saved Kconfig: {artifact_config}")
            reporter.info(
                "Saved Tracealyzer extension(s): "
                + ", ".join(
                    str(artifact_dir / path.name) for path in trace_extensions
                )
            )
            reporter.info(f"Image-only target log: {image_target_log}")

            if hardware_mode:
                assert serial_module is not None
                assert list_ports_module is not None
                flash_command = [
                    *west.command,
                    "flash",
                    "--build-dir",
                    str(build_dir),
                ]
                if runner:
                    flash_command.extend(("--runner", runner))

                capture: SerialCapture | None = None
                auto_detection_run = False
                if selected_com is None:
                    def prepare_serial_probe(device: str) -> None:
                        reporter.step(
                            f"Flashing {variant.name} while {device} is open "
                            "for COM auto-detection"
                        )
                        probe_flash = run_command(
                            flash_command,
                            reporter,
                            FLASH_TIMEOUT_SECONDS,
                            cwd=west.workspace,
                            environment=environment,
                        )
                        if (
                            probe_flash.return_code != 0
                            or probe_flash.timed_out
                            or not probe_flash.cleanup_ok
                        ):
                            raise RuntimeError(
                                f"Could not flash {variant.name} while "
                                f"probing {device}"
                            )
                        reporter.passed(
                            f"Auto-detection flash {variant.name} for {device}"
                        )

                    try:
                        capture = auto_detect_serial_port(
                            serial_module,
                            list_ports_module,
                            reporter,
                            variant_name=variant.name,
                            image_log_path=image_target_log,
                            baud_rate=serial_baud_rate,
                            prepare_probe=prepare_serial_probe,
                        )
                    except RuntimeError as error:
                        reporter.suite_failed(str(error))
                        report_unrun_test_cases(
                            selected_test_ids,
                            reporter,
                            "firmware could not be flashed for COM detection",
                        )
                        return 2
                    selected_com = capture.device
                    auto_detection_run = True
                    reporter.info(
                        f"COM selection locked for this suite: {selected_com}"
                    )

                assert selected_com is not None
                if capture is None:
                    serial_port: Any = None
                    try:
                        serial_port = open_serial_port(
                            serial_module, selected_com, serial_baud_rate
                        )
                        serial_port.reset_input_buffer()
                        capture = SerialCapture(
                            serial_port,
                            selected_com,
                            variant.name,
                            image_target_log,
                            reporter,
                            serial_baud_rate,
                        )
                        capture.start()
                    except (OSError, serial_module.SerialException) as error:
                        reporter.failed(
                            f"Could not open locked COM port {selected_com}: {error}"
                        )
                        report_unrun_test_cases(
                            selected_test_ids,
                            reporter,
                            f"COM port {selected_com} could not be opened",
                        )
                        if capture is not None:
                            capture.close()
                        elif serial_port is not None:
                            serial_port.close()
                        failed_variants.append(variant.name)
                        continue

                assert capture is not None
                try:
                    if auto_detection_run:
                        reporter.passed(
                            f"Flash {variant.name} completed during COM "
                            "auto-detection; continuing the same target run"
                        )
                    else:
                        flash = run_command(
                            flash_command,
                            reporter,
                            FLASH_TIMEOUT_SECONDS,
                            cwd=west.workspace,
                            environment=environment,
                        )
                        flash_ok = (
                            flash.return_code == 0
                            and not flash.timed_out
                            and flash.cleanup_ok
                        )
                        if not flash_ok:
                            reporter.failed(f"Flash {variant.name}")
                            report_unrun_test_cases(
                                selected_test_ids,
                                reporter,
                                "firmware flash failed",
                            )
                            failed_variants.append(variant.name)
                            continue
                        reporter.passed(f"Flash {variant.name}")

                    serial_run = capture.wait(
                        RUN_TIMEOUT_SECONDS,
                        RUN_IDLE_TIMEOUT_SECONDS,
                    )
                    run_ok = (
                        not serial_run.timed_out
                        and not serial_run.read_failed
                        and serial_run.completion_seen
                    )
                finally:
                    capture.close()
            else:
                assert device_log is not None
                run_command_line = [
                    *west.command,
                    "build",
                    "--build-dir",
                    str(build_dir),
                    "--target",
                    QEMU_RUN_TARGET,
                ]
                marker = f"DFMT:SUITE_COMPLETE:{variant.name}"
                run = run_command(
                    run_command_line,
                    reporter,
                    RUN_TIMEOUT_SECONDS,
                    marker,
                    cwd=west.workspace,
                    environment=environment,
                    raw_output_paths=(device_log, image_target_log),
                    idle_timeout_seconds=RUN_IDLE_TIMEOUT_SECONDS,
                    qemu_pid_file=build_dir / "qemu.pid",
                )
                run_ok = (
                    not run.timed_out
                    and run.completion_seen
                    and run.cleanup_ok
                )

            target_ok = validate_target_harness(image_target_log, reporter)
            checksum_ok = validate_dfm_transport_checksums(
                image_target_log, reporter
            )
            metadata_ok = validate_alert_metadata(
                image_target_log, reporter, expected_alert_counts
            )
            test_cases_ok = report_test_case_results(
                image_target_log, selected_test_ids, reporter
            )
            if not run_ok:
                reporter.failed(f"Run {variant.name}: sequence did not complete")
            if not target_ok:
                reporter.failed(
                    f"Run {variant.name}: target harness reported failure"
                )
            if not checksum_ok:
                reporter.failed(
                    f"Run {variant.name}: DFM transport checksum verification failed"
                )
            if not metadata_ok:
                reporter.failed(
                    f"Run {variant.name}: incomplete or incompatible alert metadata"
                )
            if not test_cases_ok:
                reporter.failed(
                    f"Run {variant.name}: one or more test cases failed"
                )
            if (
                not run_ok
                or not target_ok
                or not checksum_ok
                or not metadata_ok
                or not test_cases_ok
            ):
                failed_variants.append(variant.name)
                continue
            reporter.passed(
                f"Run {variant.name}: sequence complete; manual verdict pending"
            )

        if failed_variants:
            reporter.suite_failed(
                "Failed variants: " + ", ".join(failed_variants)
            )
            return 1

        reporter.suite_passed(
            "All selected test cases and variants completed; "
            "manual payload review pending"
        )
        return 0


def main(argv: Sequence[str] | None = None) -> int:
    # Set this in the suite process itself, in addition to child_environment(),
    # so every later child (loader, Receiver, Client, Dispatcher and scripts)
    # inherits one consistent mode flag.
    os.environ["DETECT_CLIENT_TEXT_OUTPUT"] = "1"
    parser = create_parser()
    args = parser.parse_args(argv)
    existing_review_result = _run_existing_review_mode(parser, args)
    if existing_review_result is not None:
        return existing_review_result
    state = SuiteRunState()
    interrupted = False
    try:
        watchdog, watchdog_expired, watchdog_waiter = start_watchdog(LOG_PATH)
    except OSError as error:
        print(f"FAIL: Could not start log watchdog: {error}", file=sys.stderr)
        return 2
    try:
        try:
            result = _run_suite(args, state)
        except KeyboardInterrupt:
            interrupted = True
            if watchdog_expired.is_set():
                print(
                    "\nSUITE FAIL: dfm_test_run.log did not change for "
                    "15 minutes; watchdog stopped the test suite.",
                    file=sys.stderr,
                )
                return WATCHDOG_TIMEOUT_EXIT_CODE
            result = 130
            print("\nSUITE FAIL: Interrupted by user.", file=sys.stderr)
    finally:
        stop_watchdog(watchdog, watchdog_waiter)

    if args.skip_payload_processing or not state.artifacts_reset:
        return result

    full_selection = args.testcase is None and (
        args.variants is None or args.variants == ["all"]
    )
    return postprocess_suite(
        app_dir=APP_DIR,
        artifact_root=ARTIFACT_ROOT,
        suite_exit_code=result,
        interrupted=interrupted,
        full_selection=full_selection,
        targets=state.targets,
        assume_yes=args.yes,
        model=normalize_model(args.model),
        reasoning_effort=args.reasoning_effort,
    )


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == WINDOWS_JOB_CHILD_FLAG:
        raise SystemExit(windows_job_child(sys.argv[2:]))
    raise SystemExit(main())
