"""Benchmark DFM payload-review accuracy, latency, and token use.

The benchmark reuses an existing Detect text export. For every requested
model/effort pair it reviews identical clean and fault-injected copies. It
never mutates the baseline artifact directory and deliberately skips the
agent-written final summary so the matrix is aggregated deterministically.
"""

from __future__ import annotations

import datetime as dt
import json
from pathlib import Path
import re
import shutil
from typing import Sequence

try:
    from . import payload_review
except ImportError:  # Direct import while run_suite.py is invoked as a script.
    import payload_review


BENCHMARK_MATRIX: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("gpt-5.6-luna", ("low", "medium", "ultra")),
    ("gpt-5.6-terra", ("low", "medium", "ultra")),
    ("gpt-5.6-sol", ("low", "medium", "xhigh")),
)


def default_output_root(app_dir: Path) -> Path:
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    return app_dir / "build" / f"agent-review-benchmark-{stamp}"


def _target_file_pattern(test_id: str) -> re.Pattern[str]:
    return re.compile(
        rf"^(?:alert-metadata|eventlog|coredump)-"
        rf"{re.escape(test_id)}(?:[A-Za-z])?-.*\.txt$"
    )


def copy_selected_evidence(
    source_root: Path,
    output_root: Path,
    targets: Sequence[payload_review.ReviewTarget],
) -> None:
    """Create an isolated evidence tree for exactly the selected tests."""

    if output_root.exists():
        raise ValueError(f"Refusing to overwrite benchmark data: {output_root}")
    copied_support: set[str] = set()
    for target in targets:
        source_build = source_root / target.build_label
        if not source_build.is_dir():
            raise ValueError(f"Baseline build directory is missing: {source_build}")
        output_build = output_root / target.build_label
        output_build.mkdir(parents=True, exist_ok=True)
        pattern = _target_file_pattern(target.test_id)
        for source in source_build.iterdir():
            if source.is_file() and pattern.match(source.name):
                shutil.copy2(source, output_build / source.name)
        if target.build_label in copied_support:
            continue
        copied_support.add(target.build_label)
        for name in ("qemu.log", "serial.log", "build-config.json"):
            source = source_build / name
            if source.is_file():
                shutil.copy2(source, output_build / name)


def inject_faults(
    artifact_root: Path,
    targets: Sequence[payload_review.ReviewTarget],
) -> dict[str, list[str]]:
    """Corrupt metadata and both payload text types for each selected test."""

    plan: dict[str, list[str]] = {}
    for target in targets:
        build_dir = artifact_root / target.build_label
        prefix = re.compile(
            rf"^(alert-metadata|eventlog|coredump)-"
            rf"{re.escape(target.test_id)}(?:[A-Za-z])?-.*\.txt$"
        )
        grouped: dict[str, list[Path]] = {
            "alert-metadata": [],
            "eventlog": [],
            "coredump": [],
        }
        for path in build_dir.iterdir():
            match = prefix.match(path.name) if path.is_file() else None
            if match:
                grouped[match.group(1)].append(path)

        injected: list[str] = []
        if not grouped["alert-metadata"]:
            metadata = build_dir / (
                f"alert-metadata-{target.test_id}-injected.txt"
            )
            metadata.write_text(
                f"Alert Type: {target.test_id}\nTest ID: {target.test_id}\n"
                "Payload count: 2\nPayload numbers: 1, 2\n"
                "INJECTED unexpected alert for zero-alert oracle.\n",
                encoding="utf-8",
                newline="\n",
            )
            grouped["alert-metadata"].append(metadata)
            injected.append("created an unexpected alert metadata record")
        else:
            for metadata in grouped["alert-metadata"]:
                metadata.write_text(
                    f"Alert Type: {target.test_id}\nTest ID: {target.test_id}\n"
                    "Payload count: 99\nPayload numbers: corrupt\n"
                    "INJECTED metadata/payload-count corruption.\n",
                    encoding="utf-8",
                    newline="\n",
                )
            injected.append("replaced alert metadata with an invalid payload count")

        if not grouped["eventlog"]:
            grouped["eventlog"].append(
                build_dir / f"eventlog-{target.test_id}-injected.txt"
            )
        for eventlog in grouped["eventlog"]:
            eventlog.write_text(
                "TraceRecorder export deliberately corrupted.\n"
                "A required event was removed.\n"
                "@@CORRUPTED_EVENT_BYTES:GG-XX-INVALID@@\n",
                encoding="utf-8",
                newline="\n",
            )
        injected.append("removed required trace events and added malformed bytes")

        if not grouped["coredump"]:
            grouped["coredump"].append(
                build_dir / f"coredump-{target.test_id}-injected.txt"
            )
        for coredump in grouped["coredump"]:
            coredump.write_text(
                "Reading symbols from Demo-FreeRTOS-QEMU.elf...\n"
                "ELF file not found.\n<eof>\n",
                encoding="utf-8",
                newline="\n",
            )
        injected.append("replaced coredump text with a simulated GDB/ELF failure")
        plan[target.test_id] = injected
    return plan


def _read_json(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return value


def _verdicts(artifact_root: Path) -> tuple[dict[str, str], set[str]]:
    try:
        result = _read_json(artifact_root / "payload-review-result.json")
    except (OSError, json.JSONDecodeError, ValueError):
        return {}, set()
    verdicts: dict[str, str] = {}
    infrastructure: set[str] = set()
    tests = result.get("tests", [])
    if not isinstance(tests, list):
        return {}, set()
    for item in tests:
        if not isinstance(item, dict):
            continue
        test_id = str(item.get("test_id", ""))
        verdicts[test_id] = str(item.get("verdict", ""))
        if "infrastructure failure" in str(item.get("comment", "")).casefold():
            infrastructure.add(test_id)
    return verdicts, infrastructure


def _metric_totals(artifact_root: Path) -> tuple[float, int, bool]:
    try:
        metrics = _read_json(artifact_root / "payload-review-metrics.json")
    except (OSError, json.JSONDecodeError, ValueError):
        return 0.0, 0, False
    runs = metrics.get("runs", [])
    if not isinstance(runs, list):
        return 0.0, 0, False
    usage_complete = bool(runs) and all(
        isinstance(run, dict) and bool(run.get("usage_available"))
        for run in runs
    )
    return (
        float(metrics.get("total_elapsed_seconds", 0.0)),
        int(metrics.get("total_tokens", 0)),
        usage_complete,
    )


def assess_pair(
    normal_root: Path,
    injected_root: Path,
    targets: Sequence[payload_review.ReviewTarget],
) -> tuple[bool, str]:
    expected_ids = [target.test_id for target in targets]
    normal, normal_infra = _verdicts(normal_root)
    injected, injected_infra = _verdicts(injected_root)
    problems: list[str] = []
    for test_id in expected_ids:
        if test_id in normal_infra or test_id in injected_infra:
            problems.append(f"{test_id}: agent infrastructure failure")
            continue
        normal_verdict = normal.get(test_id)
        injected_verdict = injected.get(test_id)
        if normal_verdict != "PASS":
            problems.append(f"{test_id}: clean={normal_verdict or 'missing'}")
        if injected_verdict != "FAIL":
            problems.append(
                f"{test_id}: injected={injected_verdict or 'missing'}"
            )
    return not problems, "; ".join(problems) if problems else "all classifications correct"


def _write_report(output_root: Path, rows: Sequence[dict[str, object]]) -> None:
    result = {
        "schema_version": 1,
        "matrix": [
            {"model": model, "reasoning_efforts": list(efforts)}
            for model, efforts in BENCHMARK_MATRIX
        ],
        "results": list(rows),
    }
    payload_review._write_json_atomic(output_root / "benchmark-results.json", result)
    lines = [
        "# Agent payload-review benchmark",
        "",
        "| Model | Reasoning | Accuracy | Comment | Avg seconds/pass | Avg tokens/pass |",
        "|---|---:|:---:|---|---:|---:|",
    ]
    for row in rows:
        comment = str(row["comment"]).replace("|", "\\|")
        lines.append(
            f"| {row['model']} | {row['reasoning_effort']} | "
            f"{row['accuracy']} | {comment} | "
            f"{row['average_elapsed_seconds']:.1f} | "
            f"{row['average_tokens']:.1f} |"
        )
    (output_root / "benchmark-results.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
    )


def _print_table(rows: Sequence[dict[str, object]]) -> None:
    print("\nAgent payload-review benchmark")
    print(
        f"{'Model':<16} {'Effort':<8} {'Accuracy':<8} "
        f"{'Avg s/pass':>10} {'Avg tokens/pass':>16}  Comment"
    )
    print("-" * 92)
    for row in rows:
        print(
            f"{row['model']:<16} {row['reasoning_effort']:<8} "
            f"{row['accuracy']:<8} "
            f"{row['average_elapsed_seconds']:>10.1f} "
            f"{row['average_tokens']:>16.1f}  {row['comment']}"
        )


def run_benchmark(
    app_dir: Path,
    source_root: Path,
    run_id: str,
    targets: Sequence[payload_review.ReviewTarget],
    *,
    output_root: Path | None = None,
) -> tuple[bool, Path]:
    if not targets:
        raise ValueError("The benchmark requires at least one existing test.")
    destination = output_root or default_output_root(app_dir)
    if destination.exists():
        raise ValueError(f"Refusing to overwrite benchmark root: {destination}")
    destination.mkdir(parents=True)
    logical_passes = 2 * len(targets)
    rows: list[dict[str, object]] = []

    for model, efforts in BENCHMARK_MATRIX:
        for effort in efforts:
            label = f"{model.removeprefix('gpt-')}-{effort}"
            pair_root = destination / label
            normal_root = pair_root / "normal"
            injected_root = pair_root / "fault-injected"
            copy_selected_evidence(source_root, normal_root, targets)
            copy_selected_evidence(source_root, injected_root, targets)
            plan = inject_faults(injected_root, targets)
            payload_review._write_json_atomic(
                pair_root / "fault-injection-plan.json", plan
            )

            print(f"\n=== Benchmark {model} / {effort}: clean evidence ===")
            payload_review.run_agentic_review(
                app_dir,
                normal_root,
                f"{run_id}-benchmark-clean-{label}",
                targets,
                model=model,
                reasoning_effort=effort,
                run_final_summary=False,
                publish_summary=False,
                propagate_interrupt=True,
            )
            print(f"\n=== Benchmark {model} / {effort}: injected evidence ===")
            payload_review.run_agentic_review(
                app_dir,
                injected_root,
                f"{run_id}-benchmark-injected-{label}",
                targets,
                model=model,
                reasoning_effort=effort,
                run_final_summary=False,
                publish_summary=False,
                propagate_interrupt=True,
            )

            accurate, comment = assess_pair(normal_root, injected_root, targets)
            normal_seconds, normal_tokens, normal_usage = _metric_totals(normal_root)
            injected_seconds, injected_tokens, injected_usage = _metric_totals(
                injected_root
            )
            if not (normal_usage and injected_usage):
                comment += "; one or more token-usage events missing"
            rows.append(
                {
                    "model": model,
                    "reasoning_effort": effort,
                    "tests_per_mode": len(targets),
                    "agent_passes": logical_passes,
                    "accuracy": "PASS" if accurate else "FAIL",
                    "comment": comment,
                    "average_elapsed_seconds": round(
                        (normal_seconds + injected_seconds) / logical_passes, 3
                    ),
                    "average_tokens": round(
                        (normal_tokens + injected_tokens) / logical_passes, 1
                    ),
                    "clean_artifacts": str(normal_root),
                    "fault_injected_artifacts": str(injected_root),
                }
            )
            _write_report(destination, rows)

    _print_table(rows)
    print(f"Benchmark report: {destination / 'benchmark-results.md'}")
    return all(row["accuracy"] == "PASS" for row in rows), destination
