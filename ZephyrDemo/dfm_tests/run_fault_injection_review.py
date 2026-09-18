"""Negative tests for the agentic DFM payload reviewer.

The experiment reuses a completed green suite run. It copies selected evidence
to an ignored build directory, injects deterministic defects, and runs the same
single-test Codex review used by the normal suite. Original artifacts are never
modified.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import datetime as dt
import json
from pathlib import Path
import shutil
from typing import Sequence

try:
    from . import payload_review
except ImportError:  # Direct invocation from the repository root.
    import payload_review


@dataclass(frozen=True)
class ExpectedFault:
    fault_id: str
    description: str
    indicators: tuple[str, ...]


@dataclass(frozen=True)
class FaultScenario:
    test_id: str
    build_label: str
    expected_alerts: int
    faults: tuple[ExpectedFault, ...]


SCENARIOS = (
    FaultScenario(
        "1001",
        "Build-M3-O0",
        1,
        (
            ExpectedFault(
                "coredump-type",
                "coredump type changed from DFM_TRAP to CORRUPTED_UNKNOWN",
                ("corrupted_unknown", "dump type", "dfm_trap"),
            ),
            ExpectedFault(
                "coredump-local-value",
                "both local_sum values changed to 3735928559 (0xDEADBEEF)",
                ("local_sum", "3735928559", "deadbeef"),
            ),
        ),
    ),
    FaultScenario(
        "1002",
        "Build-M3-Os",
        1,
        (
            ExpectedFault(
                "gdb-elf-not-found",
                "coredump text replaced by 'ELF file not found. <eof>'",
                (
                    "elf file not found",
                    "<eof>",
                    "gdb",
                    "invalid coredump",
                    "coredump export",
                ),
            ),
        ),
    ),
    FaultScenario(
        "1003",
        "Build-M3-O0",
        1,
        (
            ExpectedFault(
                "eventlog-argument",
                "r0 trace argument changed from 03030300 to DEADBEEF",
                ("deadbeef", "03030300", "argument", "args"),
            ),
            ExpectedFault(
                "eventlog-missing-path",
                "required test_thread -> trap_at_entry event removed",
                (
                    "test_thread -> trap_at_entry",
                    "missing path",
                    "path event",
                    "required path",
                ),
            ),
            ExpectedFault(
                "eventlog-garbage",
                "syntactically invalid CORRUPTED_EVENT_BYTES line appended",
                (
                    "corrupted_event",
                    "gg-xx",
                    "garbage",
                    "malformed",
                    "invalid line",
                ),
            ),
        ),
    ),
    FaultScenario(
        "1012",
        "Build-M3-O0",
        1,
        (
            ExpectedFault(
                "missing-coredump-payload",
                "coredump artifact hidden from the reviewer allowlist",
                (
                    "missing coredump",
                    "no coredump",
                    "coredump is absent",
                    "required coredump",
                    "coredump artifact",
                ),
            ),
            ExpectedFault(
                "metadata-payload-count",
                "metadata changed from two payloads to one",
                ("payload count", "payload number", "metadata"),
            ),
        ),
    ),
)

@dataclass(frozen=True)
class ReviewAssessment:
    expected_to_fail: tuple[str, ...]
    failed_as_expected: tuple[str, ...]
    unexpected_pass: tuple[str, ...]
    missing_results: tuple[str, ...]
    detected_faults: tuple[tuple[str, str], ...]
    missed_faults: tuple[tuple[str, str], ...]

    @property
    def successful(self) -> bool:
        return not self.unexpected_pass and not self.missing_results


def _single_file(directory: Path, pattern: str) -> Path:
    matches = sorted(directory.glob(pattern))
    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one {pattern!r} in {directory}, found "
            f"{len(matches)}."
        )
    return matches[0]


def _replace_exact(
    text: str,
    old: str,
    new: str,
    expected_count: int = 1,
) -> str:
    count = text.count(old)
    if count != expected_count:
        raise ValueError(
            f"Expected {expected_count} occurrence(s) of {old!r}, found {count}."
        )
    return text.replace(old, new)


def normalize_model(model: str | None) -> str | None:
    return payload_review.normalize_model(model)


def _require_green_baseline(artifact_root: Path) -> str:
    result_path = artifact_root / "payload-review-result.json"
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(
            f"A completed green agent review is required at {result_path}: {error}"
        ) from error

    tests = result.get("tests", []) if isinstance(result, dict) else []
    by_id = {
        str(item.get("test_id")): item
        for item in tests
        if isinstance(item, dict)
    }
    not_green = [
        scenario.test_id
        for scenario in SCENARIOS
        if str(by_id.get(scenario.test_id, {}).get("verdict")) != "PASS"
    ]
    if not_green:
        raise ValueError(
            "The baseline must contain PASS verdicts for all injected tests; "
            f"not green: {', '.join(not_green)}."
        )

    status_path = artifact_root / "detect-load-status.json"
    try:
        status = json.loads(status_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return "unknown-green-run"
    return str(status.get("run_id") or "unknown-green-run")


def _copy_test_evidence(source_root: Path, output_root: Path) -> None:
    if output_root.exists():
        raise ValueError(f"Refusing to overwrite existing output: {output_root}")

    copied_support: set[str] = set()
    for scenario in SCENARIOS:
        source_build = source_root / scenario.build_label
        output_build = output_root / scenario.build_label
        if not source_build.is_dir():
            raise ValueError(f"Baseline build directory is missing: {source_build}")
        output_build.mkdir(parents=True, exist_ok=True)
        for kind in ("alert-metadata", "coredump", "eventlog"):
            source = _single_file(
                source_build, f"{kind}-{scenario.test_id}-*.txt"
            )
            shutil.copy2(source, output_build / source.name)

        if scenario.build_label in copied_support:
            continue
        copied_support.add(scenario.build_label)
        for name in ("qemu.log", "serial.log", "build-config.json"):
            source = source_build / name
            if source.is_file():
                shutil.copy2(source, output_build / name)


def inject_faults(output_root: Path) -> None:
    """Inject the defects declared by SCENARIOS into copied evidence."""

    o0 = output_root / "Build-M3-O0"
    coredump = _single_file(o0, "coredump-1001-*.txt")
    coredump_text = coredump.read_text(encoding="utf-8")
    coredump_text = _replace_exact(
        coredump_text,
        "Coredump type: DFM_TRAP() call.",
        "Coredump type: CORRUPTED_UNKNOWN.",
    )
    coredump_text = _replace_exact(
        coredump_text,
        "local_sum = 1717986917",
        "local_sum = 3735928559",
        expected_count=2,
    )
    coredump.write_text(coredump_text, encoding="utf-8", newline="\n")

    eventlog = _single_file(o0, "eventlog-1003-*.txt")
    eventlog_text = eventlog.read_text(encoding="utf-8")
    eventlog_text = _replace_exact(
        eventlog_text,
        "[DFM Tests] T1003 ARGS r0=03030300 r1=03030301",
        "[DFM Tests] T1003 ARGS r0=DEADBEEF r1=03030301",
    )
    eventlog_text = _replace_exact(
        eventlog_text,
        "[DFM Tests] T1003 PATH test_thread -> trap_at_entry\n",
        "",
    )
    eventlog_text = eventlog_text.rstrip("\r\n") + (
        "\n@@CORRUPTED_EVENT_BYTES:GG-XX-INVALID@@\n"
    )
    eventlog.write_text(eventlog_text, encoding="utf-8", newline="\n")

    metadata = _single_file(o0, "alert-metadata-1012-*.txt")
    metadata_text = metadata.read_text(encoding="utf-8")
    metadata_text = _replace_exact(
        metadata_text, "Payload count: 2", "Payload count: 1"
    )
    metadata_text = _replace_exact(
        metadata_text, "Payload numbers: 1, 2", "Payload numbers: 1"
    )
    metadata.write_text(metadata_text, encoding="utf-8", newline="\n")
    hidden_coredump = _single_file(o0, "coredump-1012-*.txt")
    hidden_coredump.rename(
        hidden_coredump.with_name(f"hidden-{hidden_coredump.name}")
    )

    os_build = output_root / "Build-M3-Os"
    gdb_failure = _single_file(os_build, "coredump-1002-*.txt")
    gdb_failure.write_text(
        "Reading symbols from zephyr.elf...\n"
        "ELF file not found.\n"
        "<eof>\n",
        encoding="utf-8",
        newline="\n",
    )


def _fault_plan() -> dict[str, list[dict[str, str]]]:
    return {
        scenario.test_id: [
            {"fault_id": fault.fault_id, "description": fault.description}
            for fault in scenario.faults
        ]
        for scenario in SCENARIOS
    }


def prepare_experiment(
    source_root: Path,
    output_root: Path,
    *,
    model: str | None = None,
    reasoning_effort: str | None = None,
) -> str:
    baseline_run_id = _require_green_baseline(source_root)
    _copy_test_evidence(source_root, output_root)
    inject_faults(output_root)
    plan_document = {
        "schema_version": 1,
        "baseline_run_id": baseline_run_id,
        "source_artifacts": str(source_root.resolve()),
        "expected_to_fail": [scenario.test_id for scenario in SCENARIOS],
        "review_configuration": {
            "model": model or "Codex config default",
            "reasoning_effort": reasoning_effort or "Codex config default",
        },
        "injections_by_test": _fault_plan(),
    }
    (output_root / "fault-injection-plan.json").write_text(
        json.dumps(plan_document, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return baseline_run_id


def _review_targets() -> list[payload_review.ReviewTarget]:
    return [
        payload_review.ReviewTarget(
            scenario.test_id,
            scenario.build_label,
            scenario.expected_alerts,
        )
        for scenario in SCENARIOS
    ]


def run_reviews(
    app_dir: Path,
    artifact_root: Path,
    run_id: str,
    *,
    model: str | None = None,
    reasoning_effort: str | None = None,
) -> dict[str, object] | None:
    """Run one fresh suite reviewer per injected logical test."""

    targets = _review_targets()
    payload_review._build_manifest(app_dir, artifact_root, run_id, targets)
    schema = artifact_root / "payload-review-schema.json"
    payload_review._write_json_atomic(schema, payload_review._review_schema(1))

    codex = payload_review._find_codex_cli()
    if not codex:
        print("FAULT-INJECTION INFRA FAIL: Codex CLI was not found.")
        return None
    environment = payload_review._codex_environment()
    login_ok, login_status = payload_review._chatgpt_login_ok(codex, environment)
    print(f"Codex login status: {login_status or '(no output)'}")
    if not login_ok:
        print("FAULT-INJECTION INFRA FAIL: ChatGPT login is unavailable.")
        return None

    test_results: list[dict[str, object]] = []
    summaries: list[str] = []
    for index, target in enumerate(targets, start=1):
        manifest = payload_review._build_manifest(
            app_dir,
            artifact_root,
            run_id,
            [target],
            f"payload-review-manifest-{target.test_id}.json",
        )
        single_result: dict[str, object] | None = None
        for attempt in (1, 2):
            single_result = payload_review._run_single_test_review(
                codex=codex,
                environment=environment,
                app_dir=app_dir,
                artifact_root=artifact_root,
                manifest_path=manifest,
                schema_path=schema,
                target=target,
                index=index,
                total=len(targets),
                attempt=attempt,
                model=model,
                reasoning_effort=reasoning_effort,
            )
            if single_result is not None:
                break
            if attempt == 1:
                print(f"Test {target.test_id} returned no verdict; retrying once.")
        if single_result is None:
            print(
                "FAULT-INJECTION INFRA FAIL: no structured verdict for test "
                f"{target.test_id}."
            )
            return None
        items = single_result.get("tests", [])
        if len(items) != 1 or not isinstance(items[0], dict):
            print(
                "FAULT-INJECTION INFRA FAIL: malformed verdict for test "
                f"{target.test_id}."
            )
            return None
        test_results.append(items[0])
        summary = str(single_result.get("summary", "")).strip()
        if summary:
            summaries.append(f"{target.test_id}: {summary}")

    result: dict[str, object] = {
        "summary": " ".join(summaries),
        "tests": test_results,
    }
    payload_review._write_json_atomic(
        artifact_root / "payload-review-result.json", result
    )
    payload_review._render_reports(artifact_root, run_id, targets, result)
    return result


def assess_results(result: dict[str, object]) -> ReviewAssessment:
    tests = result.get("tests", []) if isinstance(result, dict) else []
    by_id = {
        str(item.get("test_id")): item
        for item in tests
        if isinstance(item, dict)
    }
    failed_as_expected: list[str] = []
    unexpected_pass: list[str] = []
    missing_results: list[str] = []
    detected_faults: list[tuple[str, str]] = []
    missed_faults: list[tuple[str, str]] = []

    for scenario in SCENARIOS:
        item = by_id.get(scenario.test_id)
        if item is None:
            missing_results.append(scenario.test_id)
            missed_faults.extend(
                (scenario.test_id, fault.fault_id) for fault in scenario.faults
            )
            continue
        if str(item.get("verdict")) == "FAIL":
            failed_as_expected.append(scenario.test_id)
        else:
            unexpected_pass.append(scenario.test_id)

        evidence = item.get("evidence", [])
        if not isinstance(evidence, list):
            evidence = []
        combined = " ".join(
            [str(item.get("comment", ""))]
            + [str(entry) for entry in evidence]
        ).casefold()
        for fault in scenario.faults:
            destination = (
                detected_faults
                if any(token in combined for token in fault.indicators)
                else missed_faults
            )
            destination.append((scenario.test_id, fault.fault_id))

    return ReviewAssessment(
        expected_to_fail=tuple(scenario.test_id for scenario in SCENARIOS),
        failed_as_expected=tuple(failed_as_expected),
        unexpected_pass=tuple(unexpected_pass),
        missing_results=tuple(missing_results),
        detected_faults=tuple(detected_faults),
        missed_faults=tuple(missed_faults),
    )


def print_assessment(assessment: ReviewAssessment) -> None:
    def joined(values: Sequence[str]) -> str:
        return ", ".join(values) if values else "none"

    print("\nFault-injection review summary")
    print(f"  Expected to fail review: {joined(assessment.expected_to_fail)}")
    print(f"  Failed as expected:      {joined(assessment.failed_as_expected)}")
    print(f"  Unexpected PASS:         {joined(assessment.unexpected_pass)}")
    print(f"  Missing verdict:         {joined(assessment.missing_results)}")
    print("  Detected injected faults:")
    if assessment.detected_faults:
        for test_id, fault_id in assessment.detected_faults:
            print(f"    - {test_id}: {fault_id}")
    else:
        print("    - none")
    print("  Missed injected faults:")
    if assessment.missed_faults:
        for test_id, fault_id in assessment.missed_faults:
            print(f"    - {test_id}: {fault_id}")
    else:
        print("    - none")


def print_plan() -> None:
    print("Expected fault-injected tests:")
    for scenario in SCENARIOS:
        print(
            f"  Test {scenario.test_id} / {scenario.build_label} "
            "(expected review verdict: FAIL)"
        )
        for fault in scenario.faults:
            print(f"    - {fault.fault_id}: {fault.description}")


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Reuse green payload artifacts, inject deterministic defects, and "
            "verify that the agentic reviewer rejects every affected test."
        )
    )
    parser.add_argument(
        "--source-artifacts",
        type=Path,
        default=Path("dfm_test_artifacts"),
        help="completed green artifact root (default: dfm_test_artifacts)",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        help="new experiment root; must not already exist",
    )
    parser.add_argument(
        "--prepare-only",
        action="store_true",
        help="create injected artifact copies but do not start Codex",
    )
    parser.add_argument(
        "--model",
        help=(
            "Codex model for every review agent, for example 5.6-Sol or "
            "gpt-5.6-sol (default: current Codex configuration)"
        ),
    )
    parser.add_argument(
        "--reasoning-effort",
        type=str.casefold,
        choices=payload_review.REASONING_LEVELS,
        help=(
            "reasoning level for every review agent, for example medium "
            "(default: current Codex configuration)"
        ),
    )
    return parser


def _default_output_root(app_dir: Path) -> Path:
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    return app_dir / "build" / f"fault-injection-review-{stamp}"


def main(argv: Sequence[str] | None = None) -> int:
    args = create_parser().parse_args(argv)
    app_dir = Path(__file__).resolve().parent.parent
    source_root = (
        args.source_artifacts
        if args.source_artifacts.is_absolute()
        else app_dir / args.source_artifacts
    )
    output_root = args.output_root or _default_output_root(app_dir)
    if not output_root.is_absolute():
        output_root = app_dir / output_root
    model = normalize_model(args.model)

    try:
        baseline_run_id = prepare_experiment(
            source_root,
            output_root,
            model=model,
            reasoning_effort=args.reasoning_effort,
        )
    except (OSError, ValueError) as error:
        print(f"FAULT-INJECTION SETUP FAIL: {error}")
        return 2

    print(f"Prepared fault-injection evidence: {output_root}")
    print(
        "Review configuration: "
        f"model={model or 'Codex config default'}, "
        f"reasoning={args.reasoning_effort or 'Codex config default'}"
    )
    print_plan()
    if args.prepare_only:
        print("PREPARE PASS: no Codex process was started.")
        return 0

    result = run_reviews(
        app_dir,
        output_root,
        f"{baseline_run_id}-fault-injection",
        model=model,
        reasoning_effort=args.reasoning_effort,
    )
    if result is None:
        return 2
    assessment = assess_results(result)
    print_assessment(assessment)
    print(f"See {output_root / 'diagnostic_review.md'}")
    if not assessment.successful:
        print("FAULT-INJECTION FAIL: not every injected test was rejected.")
        return 1
    print("FAULT-INJECTION PASS: every injected test was rejected as expected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

