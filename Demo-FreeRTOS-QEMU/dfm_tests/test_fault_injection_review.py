import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from dfm_tests import run_fault_injection_review as fault_review


COREDUMPS = {
    "1001": """Coredump type: DFM_TRAP() call.
local_sum = 1717986917
local_sum = 1717986917
""",
    "1003": "Coredump type: DFM_TRAP() call.\n",
    "1012": "Coredump type: DFM_TRAP() call.\n",
    "1002": "Coredump type: DFM_TRAP() call.\n",
}

EVENTLOGS = {
    "1001": "[DFM Tests] T1001 BEGIN\n",
    "1003": """[DFM Tests] T1003 BEGIN
[DFM Tests] T1003 ARGS r0=03030300 r1=03030301
[DFM Tests] T1003 PATH test_thread -> trap_at_entry
[ALERT] Test 1003
""",
    "1012": "[DFM Tests] T1012 BEGIN\n",
    "1002": "[DFM Tests] T1002 BEGIN\n",
}


def _metadata(test_id: str) -> str:
    return (
        "Percepio DFM alert metadata\n"
        f"Alert Type: {test_id}\n"
        f"Test ID: {test_id}\n"
        "Payload count: 2\n"
        "Payload numbers: 1, 2\n"
    )


def _green_artifacts(root: Path) -> Path:
    artifacts = root / "dfm_test_artifacts"
    (artifacts / "payload-review-result.json").parent.mkdir(parents=True)
    (artifacts / "payload-review-result.json").write_text(
        json.dumps(
            {
                "summary": "green",
                "tests": [
                    {
                        "test_id": scenario.test_id,
                        "verdict": "PASS",
                        "comment": "green baseline",
                        "evidence": [],
                    }
                    for scenario in fault_review.SCENARIOS
                ],
            }
        ),
        encoding="utf-8",
    )
    (artifacts / "detect-load-status.json").write_text(
        json.dumps({"run_id": "green-run-1"}), encoding="utf-8"
    )
    for scenario in fault_review.SCENARIOS:
        test_id = scenario.test_id
        build = artifacts / scenario.build_label
        build.mkdir(parents=True, exist_ok=True)
        (build / f"alert-metadata-{test_id}-1.txt").write_text(
            _metadata(test_id), encoding="utf-8"
        )
        (build / f"coredump-{test_id}-1.txt").write_text(
            COREDUMPS[test_id], encoding="utf-8"
        )
        (build / f"eventlog-{test_id}-1.txt").write_text(
            EVENTLOGS[test_id], encoding="utf-8"
        )
        (build / "qemu.log").write_text(
            f"DFMT:BEGIN:{test_id}:0\n", encoding="utf-8"
        )
        (build / "build-config.json").write_text(
            json.dumps(
                {
                    "optimization": (
                        "-O0" if scenario.build_label == "Build-M3-O0" else "-Os"
                    )
                }
            ),
            encoding="utf-8",
        )
    return artifacts


def _detected_results() -> dict[str, object]:
    return {
        "tests": [
            {
                "test_id": "1001",
                "verdict": "FAIL",
                "comment": "Coredump has CORRUPTED_UNKNOWN and bad local_sum.",
                "evidence": [],
            },
            {
                "test_id": "1003",
                "verdict": "FAIL",
                "comment": "Trace has DEADBEEF, lacks test_thread -> "
                "trap_at_entry, and contains malformed CORRUPTED_EVENT data.",
                "evidence": [],
            },
            {
                "test_id": "1012",
                "verdict": "FAIL",
                "comment": "Required coredump artifact is missing.",
                "evidence": ["Metadata payload count is one."],
            },
            {
                "test_id": "1002",
                "verdict": "FAIL",
                "comment": "The coredump export says ELF file not found.",
                "evidence": [],
            },
        ]
    }


class FaultInjectionReviewTests(unittest.TestCase):
    def test_prepare_tracks_tests_and_injects_without_changing_baseline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = _green_artifacts(root)
            output = root / "experiment"

            run_id = fault_review.prepare_experiment(
                source,
                output,
                model="gpt-5.6-sol",
                reasoning_effort="medium",
            )

            source_o0 = source / "Build-M3-O0"
            output_o0 = output / "Build-M3-O0"
            output_os = output / "Build-M3-Os"
            plan = json.loads(
                (output / "fault-injection-plan.json").read_text()
            )
            source_core = (source_o0 / "coredump-1001-1.txt").read_text()
            injected_core = (output_o0 / "coredump-1001-1.txt").read_text()
            source_event = (source_o0 / "eventlog-1003-1.txt").read_text()
            injected_event = (output_o0 / "eventlog-1003-1.txt").read_text()
            injected_metadata = (
                output_o0 / "alert-metadata-1012-1.txt"
            ).read_text()
            visible_1012_core = list(output_o0.glob("coredump-1012-*.txt"))
            hidden_1012_core = list(
                output_o0.glob("hidden-coredump-1012-*.txt")
            )
            gdb_failure = (output_os / "coredump-1002-1.txt").read_text()

        self.assertEqual(run_id, "green-run-1")
        self.assertEqual(source_core, COREDUMPS["1001"])
        self.assertEqual(source_event, EVENTLOGS["1003"])
        self.assertIn("CORRUPTED_UNKNOWN", injected_core)
        self.assertEqual(injected_core.count("3735928559"), 2)
        self.assertIn("r0=DEADBEEF", injected_event)
        self.assertNotIn("test_thread -> trap_at_entry", injected_event)
        self.assertIn("CORRUPTED_EVENT_BYTES", injected_event)
        self.assertIn("Payload count: 1", injected_metadata)
        self.assertEqual(visible_1012_core, [])
        self.assertEqual(len(hidden_1012_core), 1)
        self.assertEqual(gdb_failure, "Reading symbols from Demo-FreeRTOS-QEMU.elf...\nELF file not found.\n<eof>\n")
        self.assertEqual(plan["expected_to_fail"], ["1001", "1002", "1003", "1012"])
        self.assertEqual(
            plan["review_configuration"],
            {"model": "gpt-5.6-sol", "reasoning_effort": "medium"},
        )

    def test_assessment_reports_expected_failures_and_missed_faults(self):
        result = _detected_results()
        result["tests"][1] = {
            "test_id": "1003",
            "verdict": "PASS",
            "comment": "No issue noticed.",
            "evidence": [],
        }

        assessment = fault_review.assess_results(result)

        self.assertEqual(assessment.failed_as_expected, ("1001", "1002", "1012"))
        self.assertEqual(assessment.unexpected_pass, ("1003",))
        self.assertFalse(assessment.successful)
        self.assertIn(("1003", "eventlog-argument"), assessment.missed_faults)
        self.assertIn(("1003", "eventlog-missing-path"), assessment.missed_faults)
        self.assertIn(("1003", "eventlog-garbage"), assessment.missed_faults)

    def test_assessment_accepts_all_expected_failures(self):
        assessment = fault_review.assess_results(_detected_results())

        self.assertTrue(assessment.successful)
        self.assertEqual(
            assessment.failed_as_expected, ("1001", "1002", "1003", "1012")
        )
        self.assertEqual(assessment.unexpected_pass, ())
        self.assertEqual(assessment.missed_faults, ())

    def test_model_alias_and_reasoning_parser(self):
        args = fault_review.create_parser().parse_args(
            ["--model", "5.6-Sol", "--reasoning-effort", "Medium"]
        )

        self.assertEqual(fault_review.normalize_model(args.model), "gpt-5.6-sol")
        self.assertEqual(args.reasoning_effort, "medium")

    def test_prepare_only_does_not_start_agent_reviews(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = _green_artifacts(root)
            output = root / "prepared"
            with mock.patch.object(fault_review, "run_reviews") as run_reviews:
                result = fault_review.main(
                    [
                        "--source-artifacts",
                        str(source),
                        "--output-root",
                        str(output),
                        "--prepare-only",
                    ]
                )

        self.assertEqual(result, 0)
        run_reviews.assert_not_called()

    @mock.patch.object(fault_review, "run_reviews")
    def test_manual_runner_prints_summary_and_passes_when_all_tests_fail(
        self, run_reviews
    ):
        run_reviews.return_value = _detected_results()
        output_text = io.StringIO()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = _green_artifacts(root)
            output = root / "reviewed"
            with contextlib.redirect_stdout(output_text):
                result = fault_review.main(
                    [
                        "--source-artifacts",
                        str(source),
                        "--output-root",
                        str(output),
                        "--model",
                        "5.6-Sol",
                        "--reasoning-effort",
                        "medium",
                    ]
                )

        self.assertEqual(result, 0)
        run_reviews.assert_called_once()
        self.assertEqual(run_reviews.call_args.kwargs["model"], "gpt-5.6-sol")
        self.assertEqual(run_reviews.call_args.kwargs["reasoning_effort"], "medium")
        shown = output_text.getvalue()
        self.assertIn("Expected to fail review: 1001, 1002, 1003, 1012", shown)
        self.assertIn("Failed as expected:      1001, 1002, 1003, 1012", shown)
        self.assertIn("Missed injected faults:\n    - none", shown)


if __name__ == "__main__":
    unittest.main()
