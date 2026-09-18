import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from dfm_tests import agent_review_benchmark as benchmark
from dfm_tests.payload_review import ReviewTarget


class AgentReviewBenchmarkTests(unittest.TestCase):
    def test_matrix_uses_three_requested_levels_per_model(self):
        self.assertEqual(
            benchmark.BENCHMARK_MATRIX,
            (
                ("gpt-5.6-luna", ("low", "medium", "ultra")),
                ("gpt-5.6-terra", ("low", "medium", "ultra")),
                ("gpt-5.6-sol", ("low", "medium", "xhigh")),
            ),
        )

    def test_copy_and_injection_leave_baseline_untouched(self):
        target = ReviewTarget("1001", "Build-M3-O0", 1)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source_build = source / target.build_label
            source_build.mkdir(parents=True)
            originals = {
                "alert-metadata-1001-1.txt": "Payload count: 2\n",
                "eventlog-1001-1.txt": "required event\n",
                "coredump-1001-1.txt": "valid backtrace\n",
                "alert-metadata-1002-1.txt": "do not copy\n",
                "qemu.log": "DFMT:BEGIN:1001:0\n",
                "build-config.json": '{"optimization":"-O0"}\n',
            }
            for name, contents in originals.items():
                (source_build / name).write_text(contents, encoding="utf-8")
            output = root / "output"

            benchmark.copy_selected_evidence(source, output, [target])
            plan = benchmark.inject_faults(output, [target])

            output_build = output / target.build_label
            self.assertFalse((output_build / "alert-metadata-1002-1.txt").exists())
            self.assertIn(
                "ELF file not found",
                (output_build / "coredump-1001-1.txt").read_text(
                    encoding="utf-8"
                ),
            )
            self.assertIn(
                "CORRUPTED_EVENT_BYTES",
                (output_build / "eventlog-1001-1.txt").read_text(
                    encoding="utf-8"
                ),
            )
            self.assertEqual(
                (source_build / "coredump-1001-1.txt").read_text(
                    encoding="utf-8"
                ),
                "valid backtrace\n",
            )
            self.assertEqual(len(plan["1001"]), 3)

    def test_assessment_requires_clean_pass_and_injected_fail(self):
        targets = [
            ReviewTarget("1001", "Build-M3-O0", 1),
            ReviewTarget("1002", "Build-M3-Os", 1),
        ]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            normal = root / "normal"
            injected = root / "injected"
            normal.mkdir()
            injected.mkdir()

            def write_result(path: Path, verdicts: dict[str, str]) -> None:
                (path / "payload-review-result.json").write_text(
                    json.dumps(
                        {
                            "tests": [
                                {
                                    "test_id": test_id,
                                    "verdict": verdict,
                                    "comment": "classification",
                                    "evidence": [],
                                }
                                for test_id, verdict in verdicts.items()
                            ]
                        }
                    ),
                    encoding="utf-8",
                )

            write_result(normal, {"1001": "PASS", "1002": "PASS"})
            write_result(injected, {"1001": "FAIL", "1002": "FAIL"})
            correct, comment = benchmark.assess_pair(normal, injected, targets)
            write_result(injected, {"1001": "FAIL", "1002": "PASS"})
            incorrect, bad_comment = benchmark.assess_pair(
                normal, injected, targets
            )

        self.assertTrue(correct)
        self.assertEqual(comment, "all classifications correct")
        self.assertFalse(incorrect)
        self.assertIn("1002: injected=PASS", bad_comment)

    def test_full_matrix_orchestration_uses_deterministic_no_summary_reviews(self):
        target = ReviewTarget("1001", "Build-M3-O0", 1)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_build = root / "source" / target.build_label
            source_build.mkdir(parents=True)
            for kind in ("alert-metadata", "eventlog", "coredump"):
                (source_build / f"{kind}-1001-1.txt").write_text(
                    f"valid {kind}\n", encoding="utf-8"
                )

            def fake_review(
                _app_dir, artifact_root, _run_id, targets, **_kwargs
            ):
                injected = artifact_root.name == "fault-injected"
                (artifact_root / "payload-review-result.json").write_text(
                    json.dumps(
                        {
                            "tests": [
                                {
                                    "test_id": item.test_id,
                                    "verdict": "FAIL" if injected else "PASS",
                                    "comment": "expected classification",
                                    "evidence": [],
                                }
                                for item in targets
                            ]
                        }
                    ),
                    encoding="utf-8",
                )
                (artifact_root / "payload-review-metrics.json").write_text(
                    json.dumps(
                        {
                            "total_elapsed_seconds": 2.0,
                            "total_tokens": 100,
                            "runs": [{"usage_available": True}],
                        }
                    ),
                    encoding="utf-8",
                )
                return not injected

            output = root / "benchmark"
            with mock.patch.object(
                benchmark.payload_review,
                "run_agentic_review",
                side_effect=fake_review,
            ) as review:
                accurate, destination = benchmark.run_benchmark(
                    root,
                    root / "source",
                    "run-1",
                    [target],
                    output_root=output,
                )
            report = json.loads(
                (destination / "benchmark-results.json").read_text(
                    encoding="utf-8"
                )
            )

        self.assertTrue(accurate)
        self.assertEqual(review.call_count, 18)
        self.assertTrue(
            all(
                call.kwargs["run_final_summary"] is False
                and call.kwargs["publish_summary"] is False
                for call in review.call_args_list
            )
        )
        self.assertEqual(len(report["results"]), 9)
        self.assertTrue(
            all(row["accuracy"] == "PASS" for row in report["results"])
        )
        self.assertTrue(
            all(row["average_tokens"] == 100.0 for row in report["results"])
        )


if __name__ == "__main__":
    unittest.main()


