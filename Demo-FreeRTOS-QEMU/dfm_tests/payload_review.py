"""Detect text-export and optional Codex review for the DFM test suite.

The suite owns this orchestration layer.  The Detect loader remains the only
component that resets or starts Detect; this module merely invokes it, records
its completion atomically, and starts a read-only Codex review after explicit
user consent.
"""

from __future__ import annotations

from dataclasses import dataclass
import datetime as dt
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import time
import tomllib
from typing import Sequence


@dataclass(frozen=True)
class ReviewTarget:
    """One logical test and the build directory containing its evidence."""

    test_id: str
    build_label: str
    expected_alerts: int


MODEL_ALIASES = {
    "5.6-luna": "gpt-5.6-luna",
    "5.6-terra": "gpt-5.6-terra",
    "5.6-sol": "gpt-5.6-sol",
    "gpt-5.6-luna": "gpt-5.6-luna",
    "gpt-5.6-terra": "gpt-5.6-terra",
    "gpt-5.6-sol": "gpt-5.6-sol",
}
REASONING_LEVELS = (
    "minimal",
    "low",
    "medium",
    "high",
    "xhigh",
    "max",
    "ultra",
)


@dataclass(frozen=True)
class AgentRunMetric:
    """Timing and token usage for one physical Codex process."""

    label: str
    role: str
    attempt: int
    model: str
    reasoning_effort: str
    elapsed_seconds: float
    input_tokens: int
    cached_input_tokens: int
    cache_write_input_tokens: int
    output_tokens: int
    reasoning_output_tokens: int
    exit_code: int | None
    usage_available: bool

    @property
    def total_tokens(self) -> int:
        # cached_input_tokens is already included in input_tokens. Likewise,
        # reasoning_output_tokens describes part of the output, so neither is
        # added a second time.
        return self.input_tokens + self.output_tokens

    def as_dict(self) -> dict[str, object]:
        return {
            "label": self.label,
            "role": self.role,
            "attempt": self.attempt,
            "model": self.model,
            "reasoning_effort": self.reasoning_effort,
            "elapsed_seconds": round(self.elapsed_seconds, 3),
            "input_tokens": self.input_tokens,
            "cached_input_tokens": self.cached_input_tokens,
            "cache_write_input_tokens": self.cache_write_input_tokens,
            "output_tokens": self.output_tokens,
            "reasoning_output_tokens": self.reasoning_output_tokens,
            "total_tokens": self.total_tokens,
            "exit_code": self.exit_code,
            "usage_available": self.usage_available,
        }


_SOURCE_FILES_BY_TEST: dict[str, tuple[str, ...]] = {
    **{
        test_id: ("dfm_tests/src/test_call_chains.c",)
        for test_id in (
            "1001", "1002", "1003", "1004", "1007", "1011", "1012",
            "1013", "1014", "1024",
        )
    },
    **{
        test_id: ("dfm_tests/src/test_contexts.c",)
        for test_id in ("1006", "1009", "1015", "1021", "1025")
    },
    "1005": (
        "dfm_tests/src/test_contexts.c",
        "dfm_tests/src/test_runner.c",
        "dfm_tests/src/test_state.c",
    ),
    "1008": (
        "dfm_tests/src/test_contexts.c",
        "dfm_tests/src/test_runner.c",
        "dfm_tests/src/test_state.c",
    ),
    "1010": (
        "dfm_tests/src/test_contexts.c",
        "dfm_tests/src/test_runner.c",
        "dfm_tests/src/test_state.c",
    ),
    "1016": (
        "dfm_tests/src/test_contexts.c",
        "dfm_tests/src/test_msp.S",
    ),
    **{
        test_id: ("dfm_tests/src/test_boundaries.c",)
        for test_id in ("1017", "1018", "1019", "1020")
    },
    **{
        test_id: ("dfm_tests/src/test_m33.c",)
        for test_id in ("1022", "1023")
    },
}

_BUILD_CONTRACTS: dict[str, dict[str, object]] = {
    "Build-M3-O0": {
        "variant": "m3_o0",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {"optimization": "-O0"},
    },
    "Build-M3-Og": {
        "variant": "m3_og",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {"optimization": "-Og"},
    },
    "Build-M3-Os": {
        "variant": "m3_os",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {"optimization": "-Os"},
    },
    "Build-M3-NoCD": {
        "variant": "m3_no_coredump",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {
            "optimization": "-Os",
            "coredumps_enabled": 0,
        },
    },
    "Build-M3-SmallCD": {
        "variant": "m3_small_coredump",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {
            "optimization": "-Os",
            "max_coredump_size": "128",
        },
    },
    "Build-M3-Stack128": {
        "variant": "m3_stack128",
        "cpu_policy": "Portable common Cortex-M profile; M33 is valid.",
        "required_settings": {
            "optimization": "-O0",
            "stack_dump_size": 128,
        },
    },
    "Build-M33-Qual": {
        "variant": "m33_qual",
        "cpu_policy": (
            "FreeRTOS Cortex-M33 hardware qualification profile; "
            "STM32U585, hard-float, FPU and PSPLIM are required."
        ),
        "required_settings": {
            "target": "b_u585i_iot02a_stm32u585",
            "optimization": "-O0",
            "max_coredump_size": "2048",
        },
    },
}

GREEN = "\033[32m"
RED = "\033[31m"
BLUE = "\033[34m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def _color_enabled(stream: object) -> bool:
    isatty = getattr(stream, "isatty", None)
    return (
        callable(isatty)
        and bool(isatty())
        and "NO_COLOR" not in os.environ
    )


def _color_text(text: str, color: str, stream: object) -> str:
    return f"{color}{text}{RESET}" if color and _color_enabled(stream) else text


def _console(
    message: str = "",
    color: str = "",
    *,
    file: object | None = None,
    flush: bool = False,
) -> None:
    stream = file if file is not None else sys.stdout
    print(_color_text(message, color, stream), file=stream, flush=flush)


def _loader_line_color(line: str) -> str:
    if re.search(r"(?:^|\s)(?:\[FAIL\]|\[ERROR\]|ERROR:|FAIL:)", line):
        return RED
    if re.search(r"(?:^|\s)(?:\[WARN\]|WARNING:|WARN:)", line):
        return YELLOW
    if re.search(r"(?:^|\s)\[PASS\]", line):
        return GREEN
    if re.search(r"(?:^|\s)(?:\[STEP\]|\[INFO\])", line):
        return CYAN
    return ""


def _progress_color(message: str) -> str:
    normalized = message.casefold()
    if "reported an error" in normalized:
        return RED
    if "warning" in normalized or "found no matches" in normalized:
        return YELLOW
    if message.startswith("Agent note:"):
        return BLUE
    return CYAN


def _utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def normalize_model(model: str | None) -> str | None:
    if model is None:
        return None
    return MODEL_ALIASES.get(model.casefold(), model)


def _codex_config_defaults() -> tuple[str | None, str | None]:
    """Read only the two display fields used by the review summary."""

    config_home = os.environ.get("CODEX_HOME")
    config_path = (
        Path(config_home) / "config.toml"
        if config_home
        else Path.home() / ".codex" / "config.toml"
    )
    try:
        config = tomllib.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError):
        return None, None
    model = config.get("model")
    effort = config.get("model_reasoning_effort")
    return (
        str(model) if isinstance(model, str) else None,
        str(effort) if isinstance(effort, str) else None,
    )


def resolve_review_configuration(
    model: str | None,
    reasoning_effort: str | None,
) -> tuple[str | None, str | None, str, str]:
    """Return command overrides followed by useful effective display names."""

    command_model = normalize_model(model)
    command_effort = reasoning_effort.casefold() if reasoning_effort else None
    default_model, default_effort = _codex_config_defaults()
    return (
        command_model,
        command_effort,
        command_model or default_model or "Codex config default",
        command_effort or default_effort or "Codex config default",
    )


def _write_json_atomic(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    os.replace(temporary, path)


def _ask_yes_no(
    question: str,
    *,
    assume_yes: bool = False,
) -> bool:
    """Ask an opt-in question; non-interactive invocations safely answer no."""

    if assume_yes:
        _console(f"{question} yes (--yes)", YELLOW)
        return True
    if not sys.stdin.isatty():
        _console(f"{question} no (non-interactive input)", YELLOW)
        return False
    prompt = _color_text(f"{question} ", YELLOW, sys.stdout)
    try:
        answer = input(prompt).strip().casefold()
        return answer in {"y", "yes", "j", "ja"}
    except (EOFError, KeyboardInterrupt):
        _console()
        return False


def _loader_environment(artifact_root: Path, run_id: str) -> dict[str, str]:
    environment = os.environ.copy()
    environment["DETECT_CLIENT_TEXT_OUTPUT"] = "1"
    environment["DETECT_CLIENT_OUTPUT_DIR"] = str(artifact_root.resolve())
    environment["DETECT_CLIENT_RUN_ID"] = run_id
    return environment


def _artifact_files(artifact_root: Path) -> list[str]:
    files: list[str] = []
    for pattern in (
        "alert-metadata-*.txt",
        "eventlog-*.txt",
        "coredump-*.txt",
    ):
        files.extend(
            str(path.relative_to(artifact_root)).replace("\\", "/")
            for path in artifact_root.glob(f"Build-*/{pattern}")
            if path.is_file()
        )
    return sorted(files)


def _relative_path(path: Path, root: Path) -> str:
    return str(path.relative_to(root)).replace("\\", "/")


def _review_target_sort_key(target: ReviewTarget) -> tuple[int, str]:
    match = re.fullmatch(r"(\d+)(.*)", target.test_id)
    if match is None:
        return (sys.maxsize, target.test_id.casefold())
    return (int(match.group(1)), match.group(2).casefold())


def _test_oracle(app_dir: Path, test_id: str) -> dict[str, str]:
    """Extract only one test's authoritative Markdown section."""

    relative_source = Path("testing-docs/dfm_test_cases.md")
    source = app_dir / relative_source
    contents = source.read_text(encoding="utf-8")
    heading = re.compile(rf"^### Test {re.escape(test_id)}\b.*$", re.MULTILINE)
    match = heading.search(contents)
    if match is None:
        raise ValueError(f"No oracle section found for Test {test_id} in {source}")
    next_heading = re.search(
        r"^(?:### Test \d+\b|## )",
        contents[match.end():],
        re.MULTILINE,
    )
    end = (
        match.end() + next_heading.start()
        if next_heading is not None
        else len(contents)
    )
    return {
        "source": relative_source.as_posix(),
        "heading": match.group(0),
        "markdown": contents[match.start():end].strip(),
    }


def _target_log_evidence(
    path: Path,
    artifact_root: Path,
    test_id: str,
) -> dict[str, object]:
    """Extract one test's compact target-side DFMT protocol block."""

    source = _relative_path(path, artifact_root)
    try:
        raw_lines = path.read_text(
            encoding="utf-8", errors="replace"
        ).splitlines()
    except OSError as error:
        return {"source": source, "lines": [], "error": str(error)}

    dfmt_lines = [
        (line_number, line.strip())
        for line_number, line in enumerate(raw_lines, start=1)
        if line.strip().startswith("DFMT:")
    ]
    begin_prefix = f"DFMT:BEGIN:{test_id}:"
    start = next(
        (
            index
            for index, (_, line) in enumerate(dfmt_lines)
            if line.startswith(begin_prefix)
        ),
        None,
    )
    selected: set[int] = {
        index
        for index, (_, line) in enumerate(dfmt_lines)
        if line.startswith("DFMT:SUITE_BEGIN:")
        or line.startswith("DFMT:SUITE_COMPLETE:")
    }
    if start is not None:
        end = next(
            (
                index
                for index in range(start + 1, len(dfmt_lines))
                if dfmt_lines[index][1].startswith("DFMT:BEGIN:")
            ),
            len(dfmt_lines),
        )
        selected.update(range(start, end))
    else:
        test_token = re.compile(rf"(?:^|:){re.escape(test_id)}[A-Za-z]?(?::|$)")
        selected.update(
            index
            for index, (_, line) in enumerate(dfmt_lines)
            if test_token.search(line)
        )

    lines = [
        {"line": dfmt_lines[index][0], "text": dfmt_lines[index][1]}
        for index in sorted(selected)
    ]
    return {"source": source, "lines": lines, "error": None}


def _build_config_evidence(
    path: Path,
    artifact_root: Path,
    required_settings: dict[str, object],
) -> dict[str, object]:
    """Read only the explicit FreeRTOS settings in a build contract."""

    source = _relative_path(path, artifact_root)
    try:
        config = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return {"source": source, "settings": {}, "error": str(error)}

    settings: dict[str, object] = {}
    for name in required_settings:
        settings[name] = config.get(name, "missing")
    return {"source": source, "settings": settings, "error": None}


def run_detect_loader(
    app_dir: Path,
    artifact_root: Path,
    targets: Sequence[ReviewTarget],
) -> tuple[bool, dict[str, object]]:
    """Run the full loader synchronously and publish its final status."""

    loader = app_dir / "load-freertos-alerts.bat"
    alert_dir = app_dir / "freertos-test"
    run_id = (
        dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        + "-"
        + secrets.token_hex(4)
    )
    status_path = artifact_root / "detect-load-status.json"
    receiver_log = artifact_root / f"detect-load-{run_id}.txt"
    started_at = _utc_now()
    status: dict[str, object] = {
        "schema_version": 1,
        "run_id": run_id,
        "state": "running",
        "started_at": started_at,
        "finished_at": None,
        "exit_code": None,
        "loader": str(loader),
        "log": str(receiver_log),
        "text_output": True,
        "tests": [target.test_id for target in targets],
        "artifacts": [],
        "errors": [],
    }
    _write_json_atomic(status_path, status)

    _console("\nStarting full Detect load and text export...", YELLOW)
    _console(f"Loader log: {receiver_log}", BLUE)
    environment = _loader_environment(artifact_root, run_id)
    lines: list[str] = []
    exit_code = 127
    try:
        with receiver_log.open("w", encoding="utf-8", newline="\n") as log:
            process = subprocess.Popen(
                ["cmd.exe", "/d", "/c", str(loader), "--suite-artifacts"],
                cwd=app_dir,
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            assert process.stdout is not None
            for raw_line in process.stdout:
                line = raw_line.rstrip("\r\n")
                _console(line, _loader_line_color(line))
                log.write(line + "\n")
                log.flush()
                lines.append(line)
            exit_code = process.wait()
    except OSError as error:
        message = f"Could not run Detect loader: {error}"
        _console(f"ERROR: {message}", RED, file=sys.stderr)
        lines.append(f"ERROR: {message}")

    artifacts = _artifact_files(artifact_root)
    errors = [
        line
        for line in lines
        if re.search(r"(?:^|\b)(?:ERROR|FAIL)(?::|\b)", line, re.IGNORECASE)
    ][-50:]
    inventory_errors: list[str] = []
    for target in targets:
        metadata_pattern = re.compile(
            rf"^alert-metadata-{re.escape(target.test_id)}(?:[A-Za-z])?-"
        )
        metadata_count = sum(
            1
            for name in artifacts
            if Path(name).parent.name == target.build_label
            and metadata_pattern.match(Path(name).name)
        )
        if metadata_count != target.expected_alerts:
            inventory_errors.append(
                f"Test {target.test_id} metadata count mismatch: expected "
                f"{target.expected_alerts}, got {metadata_count}"
            )
    errors.extend(inventory_errors)
    complete = exit_code == 0 and not inventory_errors
    status.update(
        {
            "state": "complete" if complete else "failed",
            "finished_at": _utc_now(),
            "exit_code": exit_code,
            "artifacts": artifacts,
            "errors": errors,
        }
    )
    _write_json_atomic(status_path, status)
    try:
        _write_json_atomic(alert_dir / "load-status.json", status)
    except OSError as error:
        status["state"] = "failed"
        status["errors"] = [*errors, f"Could not publish alert status: {error}"]
        _write_json_atomic(status_path, status)
        complete = False

    if complete:
        _console(
            f"Detect text export complete: {len(artifacts)} artifact file(s).",
            GREEN,
        )
    else:
        detail = (
            "artifact inventory validation failed"
            if exit_code == 0
            else f"loader exit code {exit_code}"
        )
        _console(
            f"ERROR: Detect text export failed ({detail}); "
            f"see {receiver_log}.",
            RED,
            file=sys.stderr,
        )
    return complete, status


def _build_manifest(
    app_dir: Path,
    artifact_root: Path,
    run_id: str,
    targets: Sequence[ReviewTarget],
    manifest_name: str = "payload-review-manifest.json",
) -> Path:
    manifest_path = artifact_root / manifest_name
    artifact_files = _artifact_files(artifact_root)
    tests: list[dict[str, object]] = []
    for target in targets:
        source_files = _SOURCE_FILES_BY_TEST.get(target.test_id)
        if source_files is None:
            raise ValueError(
                f"No payload-review source mapping for Test {target.test_id}"
            )
        build_contract = _BUILD_CONTRACTS.get(target.build_label)
        if build_contract is None:
            raise ValueError(
                f"No payload-review build contract for {target.build_label}"
            )
        build_dir = artifact_root / target.build_label
        prefix = re.compile(
            rf"^(?:alert-metadata|eventlog|coredump)-"
            rf"{re.escape(target.test_id)}(?:[A-Za-z])?-"
        )
        files = [
            name
            for name in artifact_files
            if Path(name).parent.name == target.build_label
            and prefix.match(Path(name).name)
        ]
        target_evidence = [
            _target_log_evidence(path, artifact_root, target.test_id)
            for name in ("qemu.log", "serial.log")
            if (path := build_dir / name).is_file()
        ]
        config_path = build_dir / "build-config.json"
        required_settings = build_contract["required_settings"]
        assert isinstance(required_settings, dict)
        tests.append(
            {
                "test_id": target.test_id,
                "build_label": target.build_label,
                "expected_alerts": target.expected_alerts,
                "artifacts": files,
                "oracle": _test_oracle(app_dir, target.test_id),
                "source_files": list(source_files),
                "target_evidence": target_evidence,
                "build_contract": build_contract,
                "build_config_evidence": (
                    _build_config_evidence(
                        config_path,
                        artifact_root,
                        required_settings,
                    )
                    if config_path.is_file()
                    else None
                ),
            }
        )

    manifest = {
        "schema_version": 4,
        "run_id": run_id,
        "repository": str(app_dir.resolve()),
        "artifact_root": str(artifact_root.resolve()),
        "review_guide": "testing-docs/dfm_payload_review_agent.md",
        "tests": tests,
    }
    _write_json_atomic(manifest_path, manifest)
    return manifest_path


def _codex_environment() -> dict[str, str]:
    """Prevent API-key auth from taking precedence over ChatGPT auth."""

    environment = os.environ.copy()
    for name in ("OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN"):
        environment.pop(name, None)
    return environment


def _find_codex_cli() -> str | None:
    """Find Codex in PATH or in the standard ChatGPT/VS Code installations."""

    from_path = shutil.which("codex") or shutil.which("codex.exe")
    if from_path:
        return from_path

    candidates: list[Path] = []
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        candidates.extend(
            Path(local_app_data).glob("OpenAI/Codex/bin/*/codex.exe")
        )
    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        candidates.extend(
            Path(user_profile).glob(
                ".vscode/extensions/openai.chatgpt-*-win32-x64/"
                "bin/windows-x86_64/codex.exe"
            )
        )

    existing = [path for path in candidates if path.is_file()]
    if not existing:
        return None
    return str(max(existing, key=lambda path: path.stat().st_mtime))


def _chatgpt_login_ok(codex: str, environment: dict[str, str]) -> tuple[bool, str]:
    try:
        result = subprocess.run(
            [codex, "login", "status"],
            env=environment,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, str(error)
    output = result.stdout.strip()
    normalized = output.casefold()
    chatgpt = "chatgpt" in normalized
    api_key = "api key" in normalized or "api-key" in normalized
    return result.returncode == 0 and chatgpt and not api_key, output


def _review_schema(expected_tests: int) -> dict[str, object]:
    test_result = {
        "type": "object",
        "additionalProperties": False,
        "required": ["test_id", "verdict", "comment", "evidence"],
        "properties": {
            "test_id": {"type": "string"},
            "verdict": {"type": "string", "enum": ["PASS", "FAIL"]},
            "comment": {"type": "string"},
            "evidence": {"type": "array", "items": {"type": "string"}},
        },
    }
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "type": "object",
        "additionalProperties": False,
        "required": ["summary", "tests"],
        "properties": {
            "summary": {"type": "string"},
            "tests": {
                "type": "array",
                "items": test_result,
                "minItems": expected_tests,
                "maxItems": expected_tests,
            },
        },
    }


def _final_summary_schema() -> dict[str, object]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "type": "object",
        "additionalProperties": False,
        "required": ["bullets"],
        "properties": {
            "bullets": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 2,
                "maxItems": 5,
            }
        },
    }


def _review_prompt(manifest_path: Path, target: ReviewTarget) -> str:
    return f"""Perform an independent DFM diagnostic payload review.

Read the manifest at {manifest_path}. Review only logical test {target.test_id}
in build {target.build_label}. This Codex process is the one dedicated review
agent for that test. Do not spawn subagents and do not call collaboration wait
or delegation tools.

Follow the manifest's review_guide. The manifest already embeds the exact
authoritative oracle section for this test and explicitly lists every artifact,
source file, compact target-evidence block, and build contract that may be used.
Use that allowlist;
do not scan directories, search the repository for the test ID, read other
Markdown documents, inspect the ELF, or hash files. If listed evidence is
missing or contradictory, report FAIL with the gap instead of broadening the
search.

Avoid redundant full-file reads, but do not turn tool-output truncation or a
failed evidence command into a test FAIL. Retry failed or truncated reads with
a narrower, simpler command until the required evidence is resolved. The
manifest already embeds the relevant target-side DFMT lines in target_evidence;
do not open its source serial.log or qemu.log. Use only build_contract and
build_config_evidence for variant/configuration checks; do not open
build-config.json and do not invent requirements absent from the contract.
Prefer one simple command per evidence file;
avoid custom PowerShell objects or complex combined scripts.

Check payload presence or intentional absence, register/local values, complete
backtraces, fault data, TraceRecorder events and ordering against the embedded
oracle. A test with zero expected alerts can pass only when the oracle and
listed target log confirm that absence. Do not infer a PASS merely from the
host suite result.

Return exactly one result whose test_id is {target.test_id}, plus a short
summary. Do not edit any file and do not run the suite, loader, Receiver,
Detect, or network operations. Your final response must match the supplied
JSON schema exactly.
"""


def _final_summary_prompt(report_path: Path) -> str:
    return (
        f"Read {report_path.as_posix()} and summarize the review in 2-5 "
        "concise bullets. "
        "Return JSON matching the supplied schema.\n"
    )


def _short_progress_text(value: object, limit: int = 220) -> str:
    text = " ".join(str(value).split())
    return text if len(text) <= limit else text[: limit - 3] + "..."


def _command_detail(command: object) -> str:
    """Remove the generic PowerShell launcher so the useful operation is shown."""

    detail = " ".join(str(command).split())
    marker = " -Command "
    if marker in detail:
        detail = detail.split(marker, 1)[1]
    detail = detail.lstrip("'\"")
    if detail.startswith("$ErrorActionPreference=") and ";" in detail:
        detail = detail.split(";", 1)[1]
    return " ".join(detail.strip(" '\"").split())


def _command_files(detail: str) -> list[str]:
    """Extract a few readable filenames from a shell command."""

    pattern = re.compile(
        r"(?:[A-Za-z]:)?(?:[A-Za-z0-9_. -]+[\\/]+)+"
        r"(?:[A-Za-z0-9_.-]+\.(?:txt|md|json|log|config|elf|c|h|py|xml)|"
        r"CMakeLists\.txt|Kconfig)",
        re.IGNORECASE,
    )
    names: list[str] = []
    for path in pattern.findall(detail):
        name = re.split(r"[\\/]+", path)[-1]
        if name not in names:
            names.append(name)
    return names


def _command_action(detail: str) -> str:
    if re.search(r"(?:^|[;&|])\s*rg(?:\.exe)?\s", detail):
        return "Searching"
    if "Get-FileHash" in detail:
        return "Hashing"
    if "Get-Content" in detail or "Select-String" in detail:
        return "Reading"
    if "Get-ChildItem" in detail or "Get-Item" in detail:
        return "Listing"
    return "Inspecting"


def _command_started_message(command: object) -> str:
    detail = _command_detail(command)
    files = _command_files(detail)
    file_text = ""
    if files:
        shown = files[:4]
        file_text = " " + ", ".join(shown)
        if len(files) > len(shown):
            file_text += f" (+{len(files) - len(shown)} more)"
    return f"{_command_action(detail)}{file_text}: {_short_progress_text(detail, 160)}"


def _agent_note(item: dict[str, object]) -> str:
    raw_text = str(item.get("text", ""))
    try:
        update = json.loads(raw_text)
    except json.JSONDecodeError:
        return _short_progress_text(raw_text)
    if not isinstance(update, dict):
        return _short_progress_text(raw_text)
    summary = str(update.get("summary", "")).strip()
    return _short_progress_text(summary or raw_text)


def _progress_message(line: str) -> str | None:
    """Turn a Codex JSONL event into a clear terminal progress message."""

    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        return None
    event_type = str(event.get("type", ""))
    if event_type == "thread.started":
        return "Codex session started."
    if event_type == "turn.started":
        return "Codex is examining the test evidence."
    if event_type in {"turn.completed", "thread.completed"}:
        return "Codex analysis finished; validating the structured verdict."
    if event_type == "error":
        return f"Codex reported an error: {event.get('message', 'unknown error')}"
    item = event.get("item")
    if not isinstance(item, dict):
        return None
    item_type = str(item.get("type", ""))
    status = str(item.get("status", ""))
    if event_type == "item.started" and item_type == "command_execution":
        return _command_started_message(item.get("command", ""))
    if event_type == "item.completed" and item_type == "agent_message":
        return f"Agent note: {_agent_note(item)}"
    if event_type == "item.completed" and item_type == "command_execution":
        exit_code = item.get("exit_code")
        failed = status == "failed" or exit_code not in (None, 0)
        if not failed:
            return None
        detail = _short_progress_text(_command_detail(item.get("command", "")))
        output = _short_progress_text(item.get("aggregated_output", ""), 180)
        if not output and re.search(r"(?:^|[;&|])\s*rg\s", detail):
            return (
                "Evidence search found no matches (not automatically a test "
                f"failure): {detail}"
            )
        message = (
            f"Evidence command warning (exit {exit_code}; not the final test "
            f"verdict): {detail}"
        )
        if output:
            message += f" | {output}"
        return message
    return None


def _terminate_process(process: subprocess.Popen[str]) -> None:
    """Stop a review child promptly without leaving it running after Ctrl+C."""

    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def _run_codex_process(
    *,
    command: Sequence[str],
    prompt: str,
    app_dir: Path,
    environment: dict[str, str],
    event_log: Path,
    interrupted_message: str,
) -> int | None:
    """Run one Codex child, retain JSONL events, and show compact progress."""

    process: subprocess.Popen[str] | None = None
    try:
        with event_log.open("w", encoding="utf-8", newline="\n") as log:
            process = subprocess.Popen(
                list(command),
                cwd=app_dir,
                env=environment,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            assert process.stdin is not None
            assert process.stdout is not None
            process.stdin.write(prompt)
            process.stdin.close()
            for line in process.stdout:
                log.write(line)
                log.flush()
                progress = _progress_message(line)
                if progress:
                    _console(
                        f"  {progress}",
                        _progress_color(progress),
                        flush=True,
                    )
            return process.wait()
    except KeyboardInterrupt:
        if process is not None:
            _terminate_process(process)
        _console(f"\n{interrupted_message}", RED, file=sys.stderr)
        raise
    except OSError as error:
        if process is not None:
            _terminate_process(process)
        _console(
            f"ERROR: Could not start Codex: {error}",
            RED,
            file=sys.stderr,
        )
        return None


def _usage_from_event_log(event_log: Path) -> tuple[dict[str, int], bool]:
    """Sum completed-turn usage from one Codex JSONL process log."""

    fields = (
        "input_tokens",
        "cached_input_tokens",
        "cache_write_input_tokens",
        "output_tokens",
        "reasoning_output_tokens",
    )
    totals = {field: 0 for field in fields}
    found = False
    try:
        lines = event_log.read_text(encoding="utf-8").splitlines()
    except OSError:
        return totals, False
    for line in lines:
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict) or event.get("type") != "turn.completed":
            continue
        usage = event.get("usage")
        if not isinstance(usage, dict):
            continue
        found = True
        for field in fields:
            value = usage.get(field, 0)
            if isinstance(value, int) and not isinstance(value, bool):
                totals[field] += value
    return totals, found


def _run_codex_with_metrics(
    *,
    command: Sequence[str],
    prompt: str,
    app_dir: Path,
    environment: dict[str, str],
    event_log: Path,
    interrupted_message: str,
    metrics: list[AgentRunMetric] | None,
    label: str,
    role: str,
    attempt: int,
    model: str,
    reasoning_effort: str,
) -> int | None:
    started = time.perf_counter()
    exit_code = _run_codex_process(
        command=command,
        prompt=prompt,
        app_dir=app_dir,
        environment=environment,
        event_log=event_log,
        interrupted_message=interrupted_message,
    )
    elapsed = time.perf_counter() - started
    usage, usage_available = _usage_from_event_log(event_log)
    metric = AgentRunMetric(
        label=label,
        role=role,
        attempt=attempt,
        model=model,
        reasoning_effort=reasoning_effort,
        elapsed_seconds=elapsed,
        input_tokens=usage["input_tokens"],
        cached_input_tokens=usage["cached_input_tokens"],
        cache_write_input_tokens=usage["cache_write_input_tokens"],
        output_tokens=usage["output_tokens"],
        reasoning_output_tokens=usage["reasoning_output_tokens"],
        exit_code=exit_code,
        usage_available=usage_available,
    )
    if metrics is not None:
        metrics.append(metric)
    usage_text = (
        f"{metric.total_tokens:,} tokens"
        if usage_available
        else "token usage unavailable"
    )
    _console(
        f"  Agent metrics: {elapsed:.1f} s, {usage_text}, "
        f"model={model}, reasoning={reasoning_effort}.",
        BLUE,
        flush=True,
    )
    return exit_code


def _metrics_document(metrics: Sequence[AgentRunMetric]) -> dict[str, object]:
    total_seconds = sum(item.elapsed_seconds for item in metrics)
    total_tokens = sum(item.total_tokens for item in metrics)
    count = len(metrics)
    return {
        "schema_version": 1,
        "agent_processes": count,
        "total_elapsed_seconds": round(total_seconds, 3),
        "average_elapsed_seconds": round(total_seconds / count, 3) if count else 0,
        "total_tokens": total_tokens,
        "average_tokens": round(total_tokens / count, 1) if count else 0,
        "input_tokens": sum(item.input_tokens for item in metrics),
        "cached_input_tokens": sum(item.cached_input_tokens for item in metrics),
        "cache_write_input_tokens": sum(
            item.cache_write_input_tokens for item in metrics
        ),
        "output_tokens": sum(item.output_tokens for item in metrics),
        "reasoning_output_tokens": sum(
            item.reasoning_output_tokens for item in metrics
        ),
        "runs": [item.as_dict() for item in metrics],
    }


def _write_and_print_metrics(
    artifact_root: Path,
    metrics: Sequence[AgentRunMetric],
) -> dict[str, object]:
    document = _metrics_document(metrics)
    _write_json_atomic(artifact_root / "payload-review-metrics.json", document)
    _console("\nAgent analysis metrics", YELLOW)
    _console(
        "  Configuration(s): "
        + ", ".join(
            sorted(
                {
                    f"{item.model}/{item.reasoning_effort}"
                    for item in metrics
                }
            )
        )
        if metrics
        else "  Configuration(s): no Codex process completed",
        BLUE,
    )
    _console(
        f"  Processes: {document['agent_processes']}; "
        f"total {document['total_elapsed_seconds']:.1f} s and "
        f"{document['total_tokens']:,} tokens.",
        BLUE,
    )
    _console(
        f"  Average: {document['average_elapsed_seconds']:.1f} s and "
        f"{document['average_tokens']:,.1f} tokens per process.",
        BLUE,
    )
    _console(
        f"  Token detail: input {document['input_tokens']:,} "
        f"(cached {document['cached_input_tokens']:,}, cache-write "
        f"{document['cache_write_input_tokens']:,}); output "
        f"{document['output_tokens']:,} (reasoning "
        f"{document['reasoning_output_tokens']:,}).",
        BLUE,
    )
    return document


def _run_single_test_review(
    *,
    codex: str,
    environment: dict[str, str],
    app_dir: Path,
    artifact_root: Path,
    manifest_path: Path,
    schema_path: Path,
    target: ReviewTarget,
    index: int,
    total: int,
    attempt: int = 1,
    model: str | None = None,
    reasoning_effort: str | None = None,
    metrics: list[AgentRunMetric] | None = None,
    display_model: str | None = None,
    display_reasoning_effort: str | None = None,
) -> dict[str, object] | None:
    """Run and validate one dedicated Codex process for one logical test."""

    safe_test_id = re.sub(r"[^A-Za-z0-9_.-]", "_", target.test_id)
    result_path = artifact_root / f"payload-review-result-{safe_test_id}.json"
    attempt_suffix = "" if attempt == 1 else f"-attempt{attempt}"
    event_log = (
        artifact_root
        / f"payload-review-codex-{safe_test_id}{attempt_suffix}.jsonl"
    )
    result_path.unlink(missing_ok=True)
    prompt = _review_prompt(manifest_path.resolve(), target)
    command = [codex, "exec"]
    if model:
        command.extend(["--model", model])
    if reasoning_effort:
        command.extend(
            ["--config", f'model_reasoning_effort="{reasoning_effort}"']
        )
    command.extend([
        "--sandbox",
        "read-only",
        "--cd",
        str(app_dir.resolve()),
        "--output-schema",
        str(schema_path.resolve()),
        "--output-last-message",
        str(result_path.resolve()),
        "--json",
        "-",
    ])
    heading = (
        f"\nReview {index}/{total} - test {target.test_id}"
        if attempt == 1
        else f"\nRetry {attempt}/2 - test {target.test_id}"
    )
    _console(heading, YELLOW, flush=True)
    _console(f"  Event log: {event_log}", BLUE, flush=True)
    exit_code = _run_codex_with_metrics(
        command=command,
        prompt=prompt,
        app_dir=app_dir,
        environment=environment,
        event_log=event_log,
        interrupted_message=(
            f"Agentic review interrupted during test {target.test_id}."
        ),
        metrics=metrics,
        label=target.test_id,
        role="test",
        attempt=attempt,
        model=display_model or model or "Codex config default",
        reasoning_effort=(
            display_reasoning_effort
            or reasoning_effort
            or "Codex config default"
        ),
    )
    if exit_code is None:
        return None

    if exit_code != 0:
        _console(
            f"ERROR: Codex review for test {target.test_id} failed with exit "
            f"code {exit_code}; see {event_log}.",
            RED,
            file=sys.stderr,
        )
        return None
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        _console(
            f"ERROR: Could not read Codex result for test {target.test_id}: "
            f"{error}",
            RED,
            file=sys.stderr,
        )
        return None
    items = result.get("tests", []) if isinstance(result, dict) else []
    returned_ids = [
        str(item.get("test_id"))
        for item in items
        if isinstance(item, dict)
    ]
    if returned_ids != [target.test_id]:
        _console(
            f"ERROR: Codex review for test {target.test_id} returned "
            f"unexpected test IDs: {returned_ids}.",
            RED,
            file=sys.stderr,
        )
        return None
    verdict = str(items[0].get("verdict", "FAIL"))
    _console(
        f"Review {index}/{total} complete - test {target.test_id}: {verdict}.",
        GREEN if verdict == "PASS" else RED,
        flush=True,
    )
    return result


def _run_final_review_summary(
    *,
    codex: str,
    environment: dict[str, str],
    app_dir: Path,
    artifact_root: Path,
    model: str | None = None,
    reasoning_effort: str | None = None,
    metrics: list[AgentRunMetric] | None = None,
    display_model: str | None = None,
    display_reasoning_effort: str | None = None,
) -> list[str] | None:
    """Run one final Codex process over the completed Markdown report."""

    report_path = artifact_root / "diagnostic_review.md"
    schema_path = artifact_root / "payload-review-summary-schema.json"
    result_path = artifact_root / "payload-review-summary.json"
    event_log = artifact_root / "payload-review-codex-summary.jsonl"
    _write_json_atomic(schema_path, _final_summary_schema())
    result_path.unlink(missing_ok=True)
    command = [codex, "exec"]
    if model:
        command.extend(["--model", model])
    if reasoning_effort:
        command.extend(
            ["--config", f'model_reasoning_effort="{reasoning_effort}"']
        )
    command.extend([
        "--sandbox",
        "read-only",
        "--cd",
        str(app_dir.resolve()),
        "--output-schema",
        str(schema_path.resolve()),
        "--output-last-message",
        str(result_path.resolve()),
        "--json",
        "-",
    ])
    _console("\nFinal Codex review summary", YELLOW, flush=True)
    _console(f"  Event log: {event_log}", BLUE, flush=True)
    exit_code = _run_codex_with_metrics(
        command=command,
        prompt=_final_summary_prompt(report_path.resolve()),
        app_dir=app_dir,
        environment=environment,
        event_log=event_log,
        interrupted_message="Final Codex review summary interrupted.",
        metrics=metrics,
        label="final-summary",
        role="summary",
        attempt=1,
        model=display_model or model or "Codex config default",
        reasoning_effort=(
            display_reasoning_effort
            or reasoning_effort
            or "Codex config default"
        ),
    )
    if exit_code is None:
        return None

    if exit_code != 0:
        _console(
            f"ERROR: Final Codex summary failed with exit code {exit_code}; "
            f"see {event_log}.",
            RED,
            file=sys.stderr,
        )
        return None
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        _console(
            f"ERROR: Could not read final Codex summary: {error}",
            RED,
            file=sys.stderr,
        )
        return None
    raw_bullets = result.get("bullets", []) if isinstance(result, dict) else []
    bullets = [
        _short_progress_text(item, 400)
        for item in raw_bullets
        if isinstance(item, str) and item.strip()
    ]
    if not 2 <= len(bullets) <= 5:
        _console(
            "ERROR: Final Codex summary did not contain 2-5 non-empty bullets.",
            RED,
            file=sys.stderr,
        )
        return None
    return bullets


def _publish_review_summary(
    app_dir: Path,
    result: dict[str, object],
    bullets: Sequence[str],
) -> bool:
    """Print the final summary and append the same plain text to the run log."""

    tests = [
        item
        for item in result.get("tests", [])
        if isinstance(item, dict)
    ]
    passed = sum(str(item.get("verdict", "FAIL")) == "PASS" for item in tests)
    failed_ids = [
        str(item.get("test_id", "?"))
        for item in tests
        if str(item.get("verdict", "FAIL")) != "PASS"
    ]
    failed_text = ", ".join(failed_ids) if failed_ids else "none"
    block = [
        "",
        "Codex review summary:",
        *(f"  - {bullet}" for bullet in bullets),
        "",
        f"  PASS: {passed}/{len(tests)}",
        f"  Failed tests: {failed_text}.",
        "  See 'diagnostic_review.md' for details.",
    ]

    _console(block[0])
    _console(block[1], YELLOW)
    for line in block[2 : 2 + len(bullets)]:
        _console(line, BLUE)
    _console()
    _console(block[-3], GREEN)
    _console(block[-2], RED if failed_ids else GREEN)
    _console(block[-1], BLUE)

    log_path = app_dir / "dfm_test_run.log"
    try:
        with log_path.open("a", encoding="utf-8", newline="\n") as log:
            log.write("\n".join(block) + "\n")
    except OSError as error:
        _console(
            f"ERROR: Could not append final review summary to {log_path}: "
            f"{error}",
            RED,
            file=sys.stderr,
        )
        return False
    return True


def _render_reports(
    artifact_root: Path,
    run_id: str,
    targets: Sequence[ReviewTarget],
    result: dict[str, object],
) -> None:
    by_test = {
        str(item.get("test_id")): item
        for item in result.get("tests", [])
        if isinstance(item, dict)
    }
    generated = _utc_now()
    grouped: dict[str, list[ReviewTarget]] = {}
    for target in targets:
        grouped.setdefault(target.build_label, []).append(target)

    def lines_for(selected: Sequence[ReviewTarget], title: str) -> list[str]:
        lines = [
            f"# {title}",
            "",
            f"- Run ID: `{run_id}`",
            f"- Generated: `{generated}`",
            "",
            "## Overview",
            "",
        ]
        for target in selected:
            item = by_test.get(target.test_id)
            if item is None:
                verdict = "FAIL"
                comment = "Codex returned no result for this test."
            else:
                verdict = str(item.get("verdict", "FAIL"))
                comment = str(item.get("comment", ""))
            lines.append(
                f"- **{target.test_id} — {verdict}:** {comment}"
            )

        lines.extend(["", "## Evidence"])
        for target in selected:
            item = by_test.get(target.test_id)
            if item is None:
                verdict = "FAIL"
                evidence: list[object] = []
            else:
                verdict = str(item.get("verdict", "FAIL"))
                evidence = list(item.get("evidence", []))
            lines.extend(["", f"### Test {target.test_id} — {verdict}", ""])
            if evidence:
                lines.extend(f"- {entry}" for entry in evidence)
            else:
                lines.append("- No evidence was returned.")
        lines.append("")
        lines.append(
            "This automated second opinion supplements, and does not replace, "
            "the manual product verdict."
        )
        lines.append("")
        return lines

    (artifact_root / "diagnostic_review.md").write_text(
        "\n".join(lines_for(targets, "DFM diagnostic review")),
        encoding="utf-8",
        newline="\n",
    )
    for build_label, selected in grouped.items():
        report = artifact_root / build_label / "diagnostic_review.md"
        report.write_text(
            "\n".join(
                lines_for(selected, f"DFM diagnostic review - {build_label}")
            ),
            encoding="utf-8",
            newline="\n",
        )


def run_agentic_review(
    app_dir: Path,
    artifact_root: Path,
    run_id: str,
    targets: Sequence[ReviewTarget],
    *,
    model: str | None = None,
    reasoning_effort: str | None = None,
    run_final_summary: bool = True,
    publish_summary: bool = True,
    propagate_interrupt: bool = False,
) -> bool:
    """Run one fresh, sequential Codex process per test and render reports."""

    (
        command_model,
        command_effort,
        display_model,
        display_effort,
    ) = resolve_review_configuration(model, reasoning_effort)
    _console(
        "Agent review configuration: "
        f"model={display_model}, reasoning={display_effort}.",
        BLUE,
        flush=True,
    )

    codex = _find_codex_cli()
    if not codex:
        _console(
            "ERROR: Codex CLI was not found in PATH, the ChatGPT desktop "
            "installation, or the VS Code ChatGPT extension.",
            RED,
            file=sys.stderr,
        )
        return False

    environment = _codex_environment()
    login_ok, login_status = _chatgpt_login_ok(codex, environment)
    _console(
        f"Codex login status: {login_status or '(no output)'}",
        BLUE,
        flush=True,
    )
    if not login_ok:
        _console(
            "ERROR: Agentic review requires an authenticated ChatGPT login. "
            "It was not started, so no API-key billing can occur. Run "
            "'codex login' and choose ChatGPT, then retry.",
            RED,
            file=sys.stderr,
        )
        return False

    ordered_targets = sorted(targets, key=_review_target_sort_key)

    # Keep one aggregate inventory for audit. Each child receives a narrower
    # single-test manifest below so its fresh context contains no other test.
    _build_manifest(app_dir, artifact_root, run_id, ordered_targets)
    schema_path = artifact_root / "payload-review-schema.json"
    aggregate_result_path = artifact_root / "payload-review-result.json"
    _write_json_atomic(schema_path, _review_schema(1))
    _console(
        f"Starting sequential Agentic payload review for {len(ordered_targets)} "
        "test(s), one fresh Codex process at a time...",
        YELLOW,
        flush=True,
    )
    test_results: list[dict[str, object]] = []
    summaries: list[str] = []
    metrics: list[AgentRunMetric] = []
    infrastructure_failures = 0
    total = len(ordered_targets)
    try:
        for index, target in enumerate(ordered_targets, start=1):
            safe_test_id = re.sub(r"[^A-Za-z0-9_.-]", "_", target.test_id)
            test_manifest_path = _build_manifest(
                app_dir,
                artifact_root,
                run_id,
                [target],
                f"payload-review-manifest-{safe_test_id}.json",
            )
            single_result: dict[str, object] | None = None
            for attempt in (1, 2):
                single_result = _run_single_test_review(
                    codex=codex,
                    environment=environment,
                    app_dir=app_dir,
                    artifact_root=artifact_root,
                    manifest_path=test_manifest_path,
                    schema_path=schema_path,
                    target=target,
                    index=index,
                    total=total,
                    attempt=attempt,
                    model=command_model,
                    reasoning_effort=command_effort,
                    metrics=metrics,
                    display_model=display_model,
                    display_reasoning_effort=display_effort,
                )
                if single_result is not None:
                    break
                if attempt == 1:
                    _console(
                        "  Codex process failed without a verdict; retrying "
                        "once with a fresh process.",
                        YELLOW,
                        flush=True,
                    )

            if single_result is None:
                infrastructure_failures += 1
                test_results.append(
                    {
                        "test_id": target.test_id,
                        "verdict": "FAIL",
                        "comment": (
                            "Agent infrastructure failure: two Codex processes "
                            "ended without a valid structured verdict. This is "
                            "not a DFM product verdict; inspect the attempt logs."
                        ),
                        "evidence": [
                            f"payload-review-codex-{safe_test_id}.jsonl",
                            f"payload-review-codex-{safe_test_id}-attempt2.jsonl",
                        ],
                    }
                )
                summaries.append(
                    f"{target.test_id}: agent infrastructure failure"
                )
                continue

            items = single_result.get("tests", [])
            assert isinstance(items, list) and isinstance(items[0], dict)
            test_results.append(items[0])
            summary = str(single_result.get("summary", "")).strip()
            if summary:
                summaries.append(f"{target.test_id}: {summary}")
    except KeyboardInterrupt:
        if propagate_interrupt:
            raise
        return False

    result: dict[str, object] = {
        "summary": " ".join(summaries),
        "tests": test_results,
    }
    _write_json_atomic(aggregate_result_path, result)
    _render_reports(artifact_root, run_id, ordered_targets, result)
    if run_final_summary:
        try:
            final_bullets = _run_final_review_summary(
                codex=codex,
                environment=environment,
                app_dir=app_dir,
                artifact_root=artifact_root,
                model=command_model,
                reasoning_effort=command_effort,
                metrics=metrics,
                display_model=display_model,
                display_reasoning_effort=display_effort,
            )
        except KeyboardInterrupt:
            _write_and_print_metrics(artifact_root, metrics)
            if propagate_interrupt:
                raise
            return False
        summary_ok = final_bullets is not None
        if final_bullets is None:
            final_bullets = [
                "Final Codex summary unavailable; use the per-test overview in "
                "diagnostic_review.md."
            ]
    else:
        final_bullets = [
            "Final Codex summary disabled; deterministic aggregation is used."
        ]
        summary_ok = True
    published = (
        _publish_review_summary(app_dir, result, final_bullets)
        if publish_summary
        else True
    )
    _write_and_print_metrics(artifact_root, metrics)
    if infrastructure_failures:
        _console(
            "Agentic review completed with "
            f"{infrastructure_failures} agent infrastructure failure(s): "
            f"{artifact_root / 'diagnostic_review.md'}",
            RED,
        )
        return False
    if not summary_ok or not published:
        return False
    failed_verdicts = [
        str(item.get("test_id", "?"))
        for item in test_results
        if str(item.get("verdict", "FAIL")) != "PASS"
    ]
    if failed_verdicts:
        _console(
            "Agentic review found failing payload tests: "
            + ", ".join(failed_verdicts),
            RED,
        )
        return False
    _console(
        f"Agentic review complete: {artifact_root / 'diagnostic_review.md'}",
        GREEN,
    )
    return True


def postprocess_suite(
    *,
    app_dir: Path,
    artifact_root: Path,
    suite_exit_code: int,
    interrupted: bool,
    full_selection: bool,
    targets: Sequence[ReviewTarget],
    assume_yes: bool = False,
    model: str | None = None,
    reasoning_effort: str | None = None,
) -> int:
    """Apply load/review policy after a suite that created fresh artifacts."""

    automatic = suite_exit_code == 0 and not interrupted and full_selection
    if not automatic:
        reason = (
            "the suite was interrupted"
            if interrupted
            else "this is a focused/partial run"
            if not full_selection
            else "the automated suite did not pass"
        )
        if not _ask_yes_no(
            f"{reason.capitalize()}. Continue with full Detect load and payload "
            "text export? [y/N]",
            assume_yes=assume_yes,
        ):
            _console("Detect load and payload review skipped.", YELLOW)
            return suite_exit_code

    load_ok, status = run_detect_loader(app_dir, artifact_root, targets)
    if not load_ok:
        return suite_exit_code if suite_exit_code else 1

    if _ask_yes_no(
        "Start Agentic payload review? [y/N]",
        assume_yes=assume_yes,
    ):
        review_ok = run_agentic_review(
            app_dir,
            artifact_root,
            str(status["run_id"]),
            targets,
            model=model,
            reasoning_effort=reasoning_effort,
        )
        if not review_ok and suite_exit_code == 0:
            return 1
    else:
        _console(
            "Agentic payload review skipped; text artifacts remain for manual review.",
            YELLOW,
        )
    return suite_exit_code
