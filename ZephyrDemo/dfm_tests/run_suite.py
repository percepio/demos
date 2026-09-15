#!/usr/bin/env python3
"""Build and run the sequential DFM test variants.

Run without arguments to build and execute the complete M3 suite. Select one
variant or let the harness locate and build one individual test case:

    python dfm_tests/run_suite.py --variants m3_os
    python dfm_tests/run_suite.py --testcase 1016

For a physical board, a separately captured serial log lets the harness flash
each image and observe its target-side completion marker:

    python dfm_tests/run_suite.py --board my_board --serial-log serial.log

The script uses only the Python standard library. It discovers west and a
Zephyr workspace automatically, so a virtual environment does not need to be
activated manually.
"""

from __future__ import annotations

import argparse
from collections import Counter
import csv
from dataclasses import dataclass
import datetime as dt
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
from typing import Iterable, Sequence, TextIO


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
GRACEFUL_STOP_SECONDS = 5
FORCED_STOP_SECONDS = 5
WINDOWS_JOB_CHILD_FLAG = "--_windows-job-child"
DETECT_DESCRIPTION_MAX_CHARS = 100
DFM_HEADER_MAGIC = b"PDfm"
DATA_LINE_PATTERN = re.compile(
    r"\[\[ DATA:\s*((?:[0-9A-Fa-f]{2}(?:\s+|(?=\]\])))+)\]\]"
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
    "1024": 1,
}
if TESTCASE_ALERT_COUNTS.keys() != TESTCASE_VARIANTS.keys():
    raise RuntimeError(
        "TESTCASE_ALERT_COUNTS must cover exactly the registered test cases"
    )
REVISION_LABEL_MAX_CHARS = 18

GREEN = "\033[32m"
RED = "\033[31m"
CYAN = "\033[36m"
RESET = "\033[0m"


class Reporter:
    """Mirror every step and child-process line to console and the run log."""

    def __init__(self, log_file: TextIO) -> None:
        self.log_file = log_file
        self.use_color = sys.stdout.isatty() and "NO_COLOR" not in os.environ

    @staticmethod
    def timestamp() -> str:
        return dt.datetime.now().astimezone().isoformat(timespec="seconds")

    def status(self, label: str, message: str, color: str = "") -> None:
        plain = f"{self.timestamp()} [{label}] {message}"
        shown = f"{color}{plain}{RESET}" if self.use_color and color else plain
        print(shown, flush=True)
        self.log_file.write(plain + "\n")
        self.log_file.flush()

    def step(self, message: str) -> None:
        self.status("STEP", message, CYAN)

    def passed(self, message: str) -> None:
        self.status("PASS", message, GREEN)

    def failed(self, message: str) -> None:
        self.status("FAIL", message, RED)

    def info(self, message: str) -> None:
        self.status("INFO", message)

    def child_line(
        self, line: str, raw_output_files: Sequence[TextIO] = ()
    ) -> None:
        # Child output remains unprefixed. For QEMU runs it is also copied to
        # qemu_last_session.log so Detect can replay the DFM hex records.
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
class SerialLogCursor:
    """Identity and end position of a Serial Monitor log."""

    device: int
    inode: int
    offset: int


@dataclass(frozen=True)
class SerialWaitResult:
    completion_seen: bool
    timed_out: bool


@dataclass(frozen=True)
class WestCommand:
    command: tuple[str, ...]
    workspace: Path


@dataclass(frozen=True)
class SerializedAlert:
    """The fields needed to validate one DFM alert header."""

    alert_type: int
    description: str


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

    too_long = [
        alert
        for alert in alerts
        if len(alert.description) > DETECT_DESCRIPTION_MAX_CHARS
    ]
    if too_long:
        for alert in too_long:
            reporter.failed(
                f"Alert type {alert.alert_type} description has "
                f"{len(alert.description)} characters; Detect accepts "
                f"{DETECT_DESCRIPTION_MAX_CHARS}: {alert.description}"
            )
        return False

    longest = max(alerts, key=lambda alert: len(alert.description))
    reporter.passed(
        f"Alert descriptions fit Detect: {len(alerts)} headers; longest "
        f"is type {longest.alert_type} at {len(longest.description)}/"
        f"{DETECT_DESCRIPTION_MAX_CHARS} characters"
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


def serial_log_cursor(log_path: Path) -> SerialLogCursor:
    """Capture where new physical-target output should begin."""

    status = log_path.stat()
    return SerialLogCursor(status.st_dev, status.st_ino, status.st_size)


def wait_for_serial_suite(
    log_path: Path,
    cursor: SerialLogCursor,
    variant_name: str,
    image_log_path: Path,
    reporter: Reporter,
    timeout_seconds: int,
    idle_timeout_seconds: int,
) -> SerialWaitResult:
    """Follow a Serial Monitor log until one fresh suite run completes.

    The Serial Monitor owns the source file and may keep it open while this
    function reads appended bytes. Reopening the file for every read also lets
    the monitor replace or truncate it during an automatic reconnect.
    """

    variant_bytes = variant_name.encode("ascii")
    begin_pattern = re.compile(
        rb"DFMT:SUITE_BEGIN:"
        + re.escape(variant_bytes)
        + rb":([0-9A-Fa-f]{8})"
    )
    expected_completion: bytes | None = None
    search_tail = b""
    identity = (cursor.device, cursor.inode)
    offset = cursor.offset
    started = time.monotonic()
    last_output = started

    reporter.info(
        f"Following serial log from byte {offset}: {log_path}"
    )
    with image_log_path.open("wb") as image_log:
        while True:
            now = time.monotonic()
            if now - started > timeout_seconds:
                reporter.failed(
                    f"Serial suite timed out after {timeout_seconds} seconds"
                )
                return SerialWaitResult(False, True)
            if now - last_output > idle_timeout_seconds:
                reporter.failed(
                    "Serial log produced no new output for "
                    f"{idle_timeout_seconds} seconds"
                )
                return SerialWaitResult(False, True)

            try:
                status = log_path.stat()
            except OSError:
                time.sleep(0.1)
                continue

            new_identity = (status.st_dev, status.st_ino)
            if new_identity != identity or status.st_size < offset:
                reporter.info(
                    "Serial log was replaced or truncated; following its "
                    "new contents from the beginning"
                )
                identity = new_identity
                offset = 0
                search_tail = b""

            if status.st_size <= offset:
                time.sleep(0.1)
                continue

            try:
                with log_path.open("rb") as serial_log:
                    serial_log.seek(offset)
                    chunk = serial_log.read(status.st_size - offset)
            except OSError:
                time.sleep(0.1)
                continue

            if not chunk:
                time.sleep(0.1)
                continue

            offset += len(chunk)
            last_output = time.monotonic()
            image_log.write(chunk)
            image_log.flush()
            reporter.child_line(chunk.decode("utf-8", errors="replace"))

            searchable = search_tail + chunk
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
                    reporter.info(
                        "Observed fresh serial suite start: "
                        f"{variant_name}:{run_id.decode('ascii')}"
                    )

            if (
                expected_completion is not None
                and expected_completion in searchable
            ):
                reporter.info(
                    "Observed serial completion marker: "
                    + expected_completion.decode("ascii")
                )
                return SerialWaitResult(True, False)

            # Preserve enough overlap to recognize a marker split between two
            # writes without retaining an unbounded copy of the serial log.
            search_tail = searchable[-256:]


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
    if sdk_path:
        environment["ZEPHYR_SDK_INSTALL_DIR"] = str(sdk_path)

    # The SDK 1.0.1 QEMU build used by this project needs MinGW runtime DLLs on
    # Windows. Git for Windows is the documented conventional source.
    if os.name == "nt":
        mingw_runtime = Path("C:/Program Files/Git/mingw64/bin")
        if mingw_runtime.is_dir():
            environment["PATH"] = str(mingw_runtime) + os.pathsep + environment.get("PATH", "")
    return environment


def selected_variants(names: Sequence[str]) -> list[Variant]:
    if not names or names == ["all"]:
        return list(VARIANTS)
    if "all" in names:
        raise ValueError("'all' cannot be combined with named variants")
    return [VARIANTS_BY_NAME[name] for name in names]


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


def resolve_serial_log(path: Path) -> Path:
    """Validate a user-owned log that must survive generated-tree cleanup."""

    resolved = path.expanduser().resolve()
    if not resolved.is_file():
        raise ValueError(
            f"serial log does not exist or is not a file: {resolved}"
        )

    generated_roots = (BUILD_ROOT.resolve(), ARTIFACT_ROOT.resolve())
    if any(
        resolved == root or root in resolved.parents
        for root in generated_roots
    ):
        raise ValueError(
            "serial log must be outside build/dfm_tests and "
            f"dfm_test_artifacts: {resolved}"
        )
    if resolved in (LOG_PATH.resolve(), QEMU_LOG_PATH.resolve()):
        raise ValueError(
            f"serial log conflicts with a harness-owned log: {resolved}"
        )
    return resolved


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
    parser.add_argument(
        "--serial-log",
        type=Path,
        help=(
            "Serial Monitor log to follow for a physical board; the file "
            "must already exist and be actively appended"
        ),
    )
    parser.add_argument(
        "--runner",
        help="optional west flash runner for a physical board",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = create_parser()
    args = parser.parse_args(argv)
    try:
        testcase = args.testcase
        variants = (
            [TESTCASE_VARIANTS[testcase]]
            if testcase is not None
            else selected_variants(args.variants or ["all"])
        )
        validate_build_labels(variants)
        board = args.board.strip()
        if not board:
            raise ValueError("board name cannot be empty")
        hardware_mode = board != DEFAULT_BOARD
        if hardware_mode and args.serial_log is None:
            raise ValueError(
                "--serial-log is required when --board selects a physical board"
            )
        if not hardware_mode and args.serial_log is not None:
            raise ValueError(
                f"--serial-log cannot be used with the default QEMU board "
                f"{DEFAULT_BOARD}"
            )
        if not hardware_mode and args.runner is not None:
            raise ValueError("--runner is only valid for a physical board")
        runner = args.runner.strip() if args.runner else None
        if args.runner is not None and not runner:
            raise ValueError("runner name cannot be empty")
        serial_log = (
            resolve_serial_log(args.serial_log) if args.serial_log else None
        )
    except ValueError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 2

    try:
        reset_artifact_root()
    except (OSError, RuntimeError) as error:
        print(f"FAIL: Could not reset artifact directory: {error}", file=sys.stderr)
        return 2

    # A QEMU invocation owns its combined target log. A physical-board
    # invocation only reads the user-owned Serial Monitor log and never
    # truncates or otherwise modifies it.
    if not hardware_mode:
        QEMU_LOG_PATH.write_text("", encoding="utf-8", newline="\n")

    run_cookie = (secrets.randbits(32) or 1) if hardware_mode else 0

    with LOG_PATH.open("w", encoding="utf-8", newline="\n") as log_file:
        reporter = Reporter(log_file)
        reporter.step("Starting DFM test orchestration")
        reporter.info(f"Orchestration log: {LOG_PATH}")
        reporter.info(f"Board: {board}")
        if hardware_mode:
            assert serial_log is not None
            reporter.info(
                f"Execution mode: physical board; serial log: {serial_log}"
            )
            reporter.info(f"Flash runner: {runner or 'board default'}")
            reporter.info(f"Run cookie: 0x{run_cookie:08x}")
        else:
            reporter.info(f"Execution mode: QEMU; DFM log: {QEMU_LOG_PATH}")
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

        failed_variants: list[str] = []
        for variant in variants:
            overlay = SCRIPT_DIR / "conf" / variant.overlay
            build_dir = BUILD_ROOT / variant.name
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
                "--pristine=always",
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
                failed_variants.append(variant.name)
                continue
            if expected_revision not in config_lines:
                reporter.failed(
                    f"Build {variant.name} has wrong DFM Revision; expected "
                    f"{variant.revision}"
                )
                failed_variants.append(variant.name)
                continue
            reporter.passed(
                f"DFM Revision verified: {variant.revision}"
            )

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
                # This stable path always describes only the newly copied
                # image. Replace rather than mix the previous run's output.
                image_target_log.write_bytes(b"")
            except OSError as error:
                reporter.failed(
                    f"Could not archive build {variant.name}: {error}"
                )
                failed_variants.append(variant.name)
                continue
            reporter.info(f"Build ELF: {elf_path}")
            reporter.info(f"Build Kconfig: {config_path}")
            reporter.info(f"Saved ELF: {artifact_elf}")
            reporter.info(f"Saved Kconfig: {artifact_config}")
            reporter.info(f"Image-only target log: {image_target_log}")

            if hardware_mode:
                assert serial_log is not None
                try:
                    cursor = serial_log_cursor(serial_log)
                except OSError as error:
                    reporter.failed(
                        f"Could not read serial log before flash: {error}"
                    )
                    failed_variants.append(variant.name)
                    continue

                flash_command = [
                    *west.command,
                    "flash",
                    "--build-dir",
                    str(build_dir),
                ]
                if runner:
                    flash_command.extend(("--runner", runner))
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
                    failed_variants.append(variant.name)
                    continue
                reporter.passed(f"Flash {variant.name}")

                serial_run = wait_for_serial_suite(
                    serial_log,
                    cursor,
                    variant.name,
                    image_target_log,
                    reporter,
                    RUN_TIMEOUT_SECONDS,
                    RUN_IDLE_TIMEOUT_SECONDS,
                )
                run_ok = (
                    not serial_run.timed_out
                    and serial_run.completion_seen
                )
            else:
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
                    raw_output_paths=(QEMU_LOG_PATH, image_target_log),
                    idle_timeout_seconds=RUN_IDLE_TIMEOUT_SECONDS,
                    qemu_pid_file=build_dir / "qemu.pid",
                )
                run_ok = (
                    not run.timed_out
                    and run.completion_seen
                    and run.cleanup_ok
                )

            target_ok = validate_target_harness(image_target_log, reporter)
            metadata_ok = validate_alert_metadata(
                image_target_log, reporter, expected_alert_counts
            )
            if not run_ok:
                reporter.failed(f"Run {variant.name}: sequence did not complete")
            if not target_ok:
                reporter.failed(
                    f"Run {variant.name}: target harness reported failure"
                )
            if not metadata_ok:
                reporter.failed(
                    f"Run {variant.name}: incomplete or incompatible alert metadata"
                )
            if not run_ok or not target_ok or not metadata_ok:
                failed_variants.append(variant.name)
                continue
            reporter.passed(
                f"Run {variant.name}: sequence complete; manual verdict pending"
            )

        if failed_variants:
            reporter.failed(
                "Failed variants: " + ", ".join(failed_variants)
            )
            return 1

        reporter.passed("All selected variants completed; manual review pending")
        return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == WINDOWS_JOB_CHILD_FLAG:
        raise SystemExit(windows_job_child(sys.argv[2:]))
    raise SystemExit(main())
