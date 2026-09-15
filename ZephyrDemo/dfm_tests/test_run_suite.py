import contextlib
import io
from pathlib import Path
import tempfile
import threading
import time
import unittest
from unittest import mock

from dfm_tests import run_suite


class SelectionTests(unittest.TestCase):
    def test_testcase_selects_owning_variant(self):
        args = run_suite.create_parser().parse_args(["--testcase", "1016"])

        self.assertEqual(args.testcase, "1016")
        self.assertEqual(run_suite.TESTCASE_VARIANTS[args.testcase].name, "m3_os")

    def test_testcase_and_variants_are_mutually_exclusive(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                run_suite.create_parser().parse_args(
                    ["--testcase", "1016", "--variants", "m3_os"]
                )


class TargetVerdictTests(unittest.TestCase):
    def validate(self, contents: str) -> tuple[bool, str]:
        with tempfile.TemporaryDirectory() as directory:
            log_path = Path(directory) / "target.log"
            log_path.write_text(contents, encoding="utf-8")
            report = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()):
                result = run_suite.validate_target_harness(
                    log_path, run_suite.Reporter(report)
                )
            return result, report.getvalue()

    def test_accepts_clean_target_output(self):
        result, report = self.validate(
            "DFMT:CHECK:1016:PASS:TRAP_RETURNED\n"
            "DFMT:SUITE_COMPLETE:m3_os:12345678\n"
        )

        self.assertTrue(result)
        self.assertIn("Target harness reported no failures", report)

    def test_rejects_harness_failure_despite_suite_completion(self):
        result, report = self.validate(
            "DFMT:HARNESS_FAIL:1016:INTERRUPTED:phase=2:reason=25\n"
            "DFMT:SUITE_COMPLETE:m3_os:12345678\n"
        )

        self.assertFalse(result)
        self.assertIn("Target reported failure: DFMT:HARNESS_FAIL:1016", report)

    def test_rejects_failed_target_check(self):
        result, report = self.validate(
            "DFMT:CHECK:1016:FAIL:PSP_RESTORED\n"
            "DFMT:SUITE_COMPLETE:m3_os:12345678\n"
        )

        self.assertFalse(result)
        self.assertIn("Target reported failure: DFMT:CHECK:1016:FAIL", report)


class AlertMetadataTests(unittest.TestCase):
    def validate(
        self,
        alerts: list[run_suite.SerializedAlert],
        test_ids: tuple[str, ...],
    ) -> tuple[bool, str]:
        report = io.StringIO()
        with mock.patch.object(
            run_suite, "read_serialized_alerts", return_value=alerts
        ):
            with contextlib.redirect_stdout(io.StringIO()):
                result = run_suite.validate_alert_metadata(
                    Path("unused.log"),
                    run_suite.Reporter(report),
                    run_suite.selected_alert_counts(test_ids),
                )
        return result, report.getvalue()

    def test_rejects_missing_expected_alert(self):
        result, report = self.validate([], ("1012",))

        self.assertFalse(result)
        self.assertIn("type 1012: expected 1, decoded 0", report)

    def test_accepts_exact_type_and_multiplicity(self):
        alerts = [
            run_suite.SerializedAlert(1016, "Test 1016A"),
            run_suite.SerializedAlert(1016, "Test 1016B"),
        ]
        result, report = self.validate(alerts, ("1016",))

        self.assertTrue(result)
        self.assertIn("type 1016=2", report)

    def test_zero_alert_case_rejects_unexpected_alert(self):
        result, report = self.validate(
            [run_suite.SerializedAlert(1010, "unexpected")],
            ("1010",),
        )

        self.assertFalse(result)
        self.assertIn("type 1010: expected 0, decoded 1", report)


class SerialLogFollowerTests(unittest.TestCase):
    def reporter(self) -> run_suite.Reporter:
        return run_suite.Reporter(io.StringIO())

    def test_ignores_existing_log_and_captures_output_written_during_flash(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "serial.log"
            captured = root / "captured.log"
            source.write_bytes(
                b"DFMT:SUITE_BEGIN:m3_os:11111111\n"
                b"DFMT:SUITE_COMPLETE:m3_os:11111111\n"
            )
            cursor = run_suite.serial_log_cursor(source)
            fresh = (
                b"DFMT:SUITE_BEGIN:m3_os:22222222\n"
                b"new target output\n"
                b"DFMT:SUITE_COMPLETE:m3_os:22222222\n"
            )
            with source.open("ab") as serial_log:
                serial_log.write(fresh)

            with contextlib.redirect_stdout(io.StringIO()):
                result = run_suite.wait_for_serial_suite(
                    source,
                    cursor,
                    "m3_os",
                    captured,
                    self.reporter(),
                    timeout_seconds=2,
                    idle_timeout_seconds=1,
                )

            self.assertTrue(result.completion_seen)
            self.assertFalse(result.timed_out)
            self.assertEqual(captured.read_bytes(), fresh)

    def test_recognizes_markers_split_across_serial_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "serial.log"
            captured = root / "captured.log"
            source.write_bytes(b"")
            cursor = run_suite.serial_log_cursor(source)

            def append_output() -> None:
                pieces = (
                    b"DFMT:SUITE_BEG",
                    b"IN:m3_o0:abcdef01\noutput\nDFMT:SUITE_COM",
                    b"PLETE:m3_o0:abcdef01\n",
                )
                for piece in pieces:
                    time.sleep(0.15)
                    with source.open("ab") as serial_log:
                        serial_log.write(piece)

            writer = threading.Thread(target=append_output)
            writer.start()
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    result = run_suite.wait_for_serial_suite(
                        source,
                        cursor,
                        "m3_o0",
                        captured,
                        self.reporter(),
                        timeout_seconds=3,
                        idle_timeout_seconds=2,
                    )
            finally:
                writer.join()

            self.assertTrue(result.completion_seen)
            self.assertFalse(result.timed_out)
            self.assertIn(
                b"DFMT:SUITE_COMPLETE:m3_o0:abcdef01",
                captured.read_bytes(),
            )


if __name__ == "__main__":
    unittest.main()
