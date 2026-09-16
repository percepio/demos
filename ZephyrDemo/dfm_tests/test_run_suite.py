import contextlib
import io
from pathlib import Path
import tempfile
from types import SimpleNamespace
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

    def test_com_and_device_log_are_mutually_exclusive(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                run_suite.create_parser().parse_args(
                    ["--com", "COM7", "--devicelog", "qemu.log"]
                )

    def test_qemu_all_excludes_hardware_only_m33_variant(self):
        variants = run_suite.selected_variants(
            ["all"], include_hardware_only=False
        )

        self.assertNotIn("m33_qual", [variant.name for variant in variants])

    def test_physical_all_includes_m33_qualification(self):
        variants = run_suite.selected_variants(
            ["all"], include_hardware_only=True
        )

        self.assertIn("m33_qual", [variant.name for variant in variants])

    def test_m33_testcase_selects_qualification_variant(self):
        args = run_suite.create_parser().parse_args(["--testcase", "1022"])

        self.assertEqual(
            run_suite.TESTCASE_VARIANTS[args.testcase].name, "m33_qual"
        )

    def test_qemu_rejects_explicit_m33_testcase_before_build(self):
        stderr = io.StringIO()

        with contextlib.redirect_stderr(stderr):
            result = run_suite.main(["--testcase", "1022"])

        self.assertEqual(result, 2)
        self.assertIn("hardware-only variant(s): m33_qual", stderr.getvalue())


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


class TestCaseResultTests(unittest.TestCase):
    def test_reports_explicit_pass_for_zero_alert_case(self):
        contents = (
            "DFMT:BEGIN:1010:0\n"
            "DFMT:RETURNED:1010:startup:ipsr=0:control=0x2\n"
        )
        with tempfile.TemporaryDirectory() as directory:
            log_path = Path(directory) / "target.log"
            log_path.write_text(contents, encoding="utf-8")
            report = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()):
                result = run_suite.report_test_case_results(
                    log_path, ("1010",), run_suite.Reporter(report)
                )

        self.assertTrue(result)
        self.assertIn("[TEST PASS] 1010:", report.getvalue())


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


class FakeSerialPort:
    def __init__(self, chunks: list[bytes]) -> None:
        self.chunks = list(chunks)
        self.closed = False

    def read(self, size: int) -> bytes:
        if self.closed or not self.chunks:
            return b""
        chunk = self.chunks.pop(0)
        if len(chunk) <= size:
            return chunk
        self.chunks.insert(0, chunk[size:])
        return chunk[:size]

    def close(self) -> None:
        self.closed = True


class SerialPortTests(unittest.TestCase):
    def reporter(self) -> run_suite.Reporter:
        return run_suite.Reporter(io.StringIO())

    def test_sorts_com_ports_by_descending_number(self):
        ports = SimpleNamespace(
            comports=lambda: [
                SimpleNamespace(device="COM3"),
                SimpleNamespace(device="COM17"),
                SimpleNamespace(device="COM9"),
            ]
        )

        self.assertEqual(
            run_suite.available_serial_ports(ports),
            ["COM17", "COM9", "COM3"],
        )

    def test_probe_accepts_percepio_split_across_reads(self):
        port = FakeSerialPort([b"Starting Per", b"cepio Detect test\n"])
        serial_module = SimpleNamespace(
            Serial=lambda **kwargs: port,
            SerialException=OSError,
            EIGHTBITS=8,
            PARITY_NONE="N",
            STOPBITS_ONE=1,
        )

        with contextlib.redirect_stdout(io.StringIO()):
            found = run_suite.probe_serial_port(
                serial_module, "COM17", self.reporter(), timeout_seconds=0.1
            )

        self.assertTrue(found)
        self.assertTrue(port.closed)

    def test_probe_opens_reader_before_firmware_is_prepared(self):
        port = FakeSerialPort([])
        serial_module = SimpleNamespace(
            Serial=lambda **kwargs: port,
            SerialException=OSError,
            EIGHTBITS=8,
            PARITY_NONE="N",
            STOPBITS_ONE=1,
        )
        prepared: list[str] = []

        def flash_after_open(device: str) -> None:
            self.assertFalse(port.closed)
            prepared.append(device)
            port.chunks.append(b"Starting Percepio Detect test\n")

        with contextlib.redirect_stdout(io.StringIO()):
            found = run_suite.probe_serial_port(
                serial_module,
                "COM17",
                self.reporter(),
                timeout_seconds=0.5,
                prepare_probe=flash_after_open,
            )

        self.assertTrue(found)
        self.assertEqual(prepared, ["COM17"])
        self.assertTrue(port.closed)

    def test_probe_rejects_marker_after_first_kibibyte(self):
        port = FakeSerialPort(
            [b"x" * run_suite.SERIAL_PROBE_MAX_BYTES, b"Percepio"]
        )
        serial_module = SimpleNamespace(
            Serial=lambda **kwargs: port,
            SerialException=OSError,
            EIGHTBITS=8,
            PARITY_NONE="N",
            STOPBITS_ONE=1,
        )

        with contextlib.redirect_stdout(io.StringIO()):
            found = run_suite.probe_serial_port(
                serial_module, "COM8", self.reporter(), timeout_seconds=0.1
            )

        self.assertFalse(found)

    def test_auto_detection_restarts_after_all_ports_fail(self):
        ports = SimpleNamespace(
            comports=lambda: [
                SimpleNamespace(device="COM2"),
                SimpleNamespace(device="COM10"),
            ]
        )
        report = io.StringIO()
        with mock.patch.object(
            run_suite,
            "probe_serial_port",
            side_effect=[False, False, True],
        ) as probe:
            with contextlib.redirect_stdout(io.StringIO()):
                selected = run_suite.auto_detect_serial_port(
                    SimpleNamespace(), ports, run_suite.Reporter(report)
                )

        self.assertEqual(selected, "COM10")
        self.assertEqual(
            [call.args[1] for call in probe.call_args_list],
            ["COM10", "COM2", "COM10"],
        )
        self.assertIn("restarting the search", report.getvalue())

    def test_capture_streams_all_bytes_and_recognizes_split_markers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            captured = root / "captured.log"
            pieces = [
                b"DFMT:SUITE_BEG",
                b"IN:m3_os:22222222\nall device output\nDFMT:SUITE_COM",
                b"PLETE:m3_os:22222222\n",
            ]
            port = FakeSerialPort(pieces)
            capture = run_suite.SerialCapture(
                port,
                "COM17",
                "m3_os",
                captured,
                self.reporter(),
            )
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    capture.start()
                    result = capture.wait(
                        timeout_seconds=3,
                        idle_timeout_seconds=2,
                    )
            finally:
                capture.close()

            self.assertTrue(result.completion_seen)
            self.assertFalse(result.timed_out)
            self.assertEqual(captured.read_bytes(), b"".join(pieces))


if __name__ == "__main__":
    unittest.main()
