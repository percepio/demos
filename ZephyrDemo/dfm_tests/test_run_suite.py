import contextlib
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

from dfm_tests import log_watchdog, run_suite


class _TtyBuffer(io.StringIO):
    def isatty(self) -> bool:
        return True


class SelectionTests(unittest.TestCase):
    def test_reporter_uses_semantic_terminal_colors_but_plain_log(self):
        terminal = _TtyBuffer()
        log = io.StringIO()

        with mock.patch.dict(run_suite.os.environ):
            run_suite.os.environ.pop("NO_COLOR", None)
            with contextlib.redirect_stdout(terminal):
                reporter = run_suite.Reporter(log)
                reporter.info("details")
                reporter.step("action")
                reporter.warning("caution")
                reporter.passed("good")
                reporter.failed("bad")

        shown = terminal.getvalue()
        self.assertIn(run_suite.BLUE, shown)
        self.assertIn(run_suite.CYAN, shown)
        self.assertIn(run_suite.YELLOW, shown)
        self.assertIn(run_suite.GREEN, shown)
        self.assertIn(run_suite.RED, shown)
        self.assertNotIn("\033[", log.getvalue())

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

    def test_yes_short_and_long_options_enable_automatic_confirmation(self):
        for option in ("-y", "--yes"):
            with self.subTest(option=option):
                args = run_suite.create_parser().parse_args([option])
                self.assertTrue(args.yes)

    def test_benchmark_defaults_to_first_three_tests(self):
        parser = run_suite.create_parser()

        default = parser.parse_args(["--benchmark-agent-review"])
        explicit = parser.parse_args(["--benchmark-agent-review", "5"])

        self.assertEqual(default.benchmark_agent_review, 3)
        self.assertEqual(explicit.benchmark_agent_review, 5)

    def test_benchmark_rejects_nonpositive_test_count(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                run_suite.create_parser().parse_args(
                    ["--benchmark-agent-review", "0"]
                )

    def test_agent_review_only_bypasses_suite_and_watchdog(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact_root = Path(directory) / "artifacts"
            artifact_root.mkdir()
            (artifact_root / "detect-load-status.json").write_text(
                json.dumps(
                    {
                        "run_id": "run-existing",
                        "state": "complete",
                        "exit_code": 0,
                        "tests": ["1002", "1001"],
                    }
                ),
                encoding="utf-8",
            )
            with (
                mock.patch.object(run_suite, "ARTIFACT_ROOT", artifact_root),
                mock.patch.object(
                    run_suite, "run_agentic_review", return_value=True
                ) as review,
                mock.patch.object(run_suite, "start_watchdog") as watchdog,
                mock.patch.object(run_suite, "_run_suite") as suite,
            ):
                result = run_suite.main(
                    [
                        "--agent-review-only",
                        "--model",
                        "5.6-Sol",
                        "--reasoning-effort",
                        "medium",
                    ]
                )

        self.assertEqual(result, 0)
        watchdog.assert_not_called()
        suite.assert_not_called()
        review.assert_called_once()
        self.assertEqual(review.call_args.kwargs["model"], "gpt-5.6-sol")
        self.assertEqual(review.call_args.kwargs["reasoning_effort"], "medium")
        self.assertEqual(
            [target.test_id for target in review.call_args.args[3]],
            ["1001", "1002"],
        )

    def test_standalone_watchdog_resets_then_expires_after_15_checks(self):
        with tempfile.TemporaryDirectory() as directory:
            log_path = Path(directory) / "suite.log"
            log_path.write_text("start\n", encoding="utf-8")
            checks = 0

            def next_check(_: float) -> None:
                nonlocal checks
                checks += 1
                if checks == 5:
                    log_path.write_text("start\nactivity\n", encoding="utf-8")

            result = log_watchdog.watch_log(
                log_path,
                check_interval_seconds=60,
                max_unchanged_checks=15,
                sleep=next_check,
            )

        self.assertEqual(result, log_watchdog.WATCHDOG_TIMEOUT_EXIT_CODE)
        self.assertEqual(checks, 20)

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

    def test_no_trace_cases_select_no_trace_variant(self):
        for test_id in ("1025", "1026"):
            with self.subTest(test_id=test_id):
                args = run_suite.create_parser().parse_args(
                    ["--testcase", test_id]
                )
                self.assertEqual(
                    run_suite.TESTCASE_VARIANTS[args.testcase].name,
                    "m3_no_trace",
                )
                self.assertEqual(
                    run_suite.TESTCASE_ALERT_COUNTS[test_id], 1
                )

    def test_retained_case_selects_retained_variant(self):
        args = run_suite.create_parser().parse_args(["--testcase", "1027"])

        self.assertEqual(
            run_suite.TESTCASE_VARIANTS[args.testcase].name,
            "m3_retained",
        )
        self.assertEqual(run_suite.TESTCASE_ALERT_COUNTS["1027"], 1)

    def test_qemu_rejects_explicit_m33_testcase_before_build(self):
        stderr = io.StringIO()

        with contextlib.redirect_stderr(stderr):
            result = run_suite.main(["--testcase", "1022"])

        self.assertEqual(result, 2)
        self.assertIn("hardware-only variant(s): m33_qual", stderr.getvalue())

    def test_b_u585i_uses_baud_rate_from_board_overlay(self):
        self.assertEqual(
            run_suite.serial_baud_rate_for_board("b_u585i_iot02a"),
            460800,
        )

    def test_unknown_physical_board_uses_standard_baud_rate(self):
        self.assertEqual(
            run_suite.serial_baud_rate_for_board("another_board"),
            115200,
        )

    def test_only_first_build_is_forced_pristine(self):
        self.assertEqual(run_suite.west_pristine_mode(0), "always")
        self.assertEqual(run_suite.west_pristine_mode(1), "auto")
        self.assertEqual(run_suite.west_pristine_mode(6), "auto")

    def test_negative_build_index_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "cannot be negative"):
            run_suite.west_pristine_mode(-1)

    def test_trace_extension_is_selected_from_exact_build_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            build_dir = root / "build" / "dfm_tests" / "m3_os"
            build_dir.mkdir(parents=True)
            stale = root / "syscalls-v4.4.98.xml"
            generated = build_dir / "syscalls-v4.4.99.xml"
            stale.write_text("stale", encoding="utf-8")
            generated.write_text("current", encoding="utf-8")

            result = run_suite.trace_extensions_for_build(build_dir)

        self.assertEqual(result, [generated])


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


class DfmTransportChecksumTests(unittest.TestCase):
    def validate(self, contents: str) -> tuple[bool, str]:
        with tempfile.TemporaryDirectory() as directory:
            log_path = Path(directory) / "target.log"
            log_path.write_text(contents, encoding="utf-8")
            report = io.StringIO()
            with contextlib.redirect_stdout(io.StringIO()):
                result = run_suite.validate_dfm_transport_checksums(
                    log_path, run_suite.Reporter(report)
                )
            return result, report.getvalue()

    @staticmethod
    def block(payload: bytes, checksum: int) -> str:
        hex_data = " ".join(f"{byte:02X}" for byte in payload)
        return (
            "[[ DevAlert Data Begins ]]\n"
            f"[[ DATA: {hex_data} ]]\n"
            f"[[ DevAlert Data Ended. Checksum: {checksum} ]]\n"
        )

    def test_accepts_matching_nonzero_checksum(self):
        payload = bytes(range(32))
        result, report = self.validate(
            self.block(payload, run_suite.crc16_ccitt(payload))
        )

        self.assertTrue(result)
        self.assertIn("1 verified, 0 skipped", report)

    def test_rejects_checksum_mismatch(self):
        result, report = self.validate(self.block(b"transferred data", 12345))

        self.assertFalse(result)
        self.assertIn("checksum mismatch", report)

    def test_zero_checksum_explicitly_skips_verification(self):
        result, report = self.validate(self.block(b"unchecked data", 0))

        self.assertTrue(result)
        self.assertIn("0 verified, 1 skipped", report)

    def test_rejects_incomplete_dfm_block(self):
        result, report = self.validate(
            "[[ DevAlert Data Begins ]]\n[[ DATA: 01 02 03 ]]\n"
        )

        self.assertFalse(result)
        self.assertIn("did not contain an end/checksum marker", report)

    def test_rejects_malformed_hex_data_even_with_zero_checksum(self):
        result, report = self.validate(
            "[[ DevAlert Data Begins ]]\n"
            "[[ DATA: 01 XX 03 ]]\n"
            "[[ DevAlert Data Ended. Checksum: 0 ]]\n"
        )

        self.assertFalse(result)
        self.assertIn("malformed DFM hex data", report)

    def test_rejects_empty_block_even_with_zero_checksum(self):
        result, report = self.validate(
            "[[ DevAlert Data Begins ]]\n"
            "[[ DevAlert Data Ended. Checksum: 0 ]]\n"
        )

        self.assertFalse(result)
        self.assertIn("contained no data", report)


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

    def test_rejects_description_that_cannot_fit_trace_event(self):
        alerts = [run_suite.SerializedAlert(1012, "x" * 50)]

        result, report = self.validate(alerts, ("1012",))

        self.assertFalse(result)
        self.assertIn("suite's TraceRecorder budget is 49", report)

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
        self.reset_count = 0

    def read(self, size: int) -> bytes:
        if self.closed or not self.chunks:
            return b""
        chunk = self.chunks.pop(0)
        if len(chunk) <= size:
            return chunk
        self.chunks.insert(0, chunk[size:])
        return chunk[:size]

    def reset_input_buffer(self) -> None:
        self.reset_count += 1

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

        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stdout(io.StringIO()):
                capture = run_suite.probe_serial_port(
                    serial_module,
                    "COM17",
                    self.reporter(),
                    variant_name="m3_os",
                    image_log_path=Path(directory) / "serial.log",
                    timeout_seconds=0.1,
                )

            self.assertIsNotNone(capture)
            assert capture is not None
            self.assertFalse(port.closed)
            capture.close()

        self.assertEqual(port.reset_count, 1)
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

        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stdout(io.StringIO()):
                capture = run_suite.probe_serial_port(
                    serial_module,
                    "COM17",
                    self.reporter(),
                    variant_name="m3_os",
                    image_log_path=Path(directory) / "serial.log",
                    timeout_seconds=0.5,
                    prepare_probe=flash_after_open,
                )

            self.assertIsNotNone(capture)
            assert capture is not None
            capture.close()

        self.assertEqual(prepared, ["COM17"])
        self.assertTrue(port.closed)

    def test_probe_closes_port_if_input_reset_fails(self):
        port = FakeSerialPort([])
        port.reset_input_buffer = mock.Mock(side_effect=OSError("reset failed"))
        serial_module = SimpleNamespace(
            Serial=lambda **kwargs: port,
            SerialException=OSError,
            EIGHTBITS=8,
            PARITY_NONE="N",
            STOPBITS_ONE=1,
        )

        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stdout(io.StringIO()):
                capture = run_suite.probe_serial_port(
                    serial_module,
                    "COM17",
                    self.reporter(),
                    variant_name="m3_os",
                    image_log_path=Path(directory) / "serial.log",
                    timeout_seconds=0.1,
                )

        self.assertIsNone(capture)
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

        with tempfile.TemporaryDirectory() as directory:
            with contextlib.redirect_stdout(io.StringIO()):
                capture = run_suite.probe_serial_port(
                    serial_module,
                    "COM8",
                    self.reporter(),
                    variant_name="m3_os",
                    image_log_path=Path(directory) / "serial.log",
                    timeout_seconds=0.1,
                )

        self.assertIsNone(capture)
        self.assertTrue(port.closed)

    def test_auto_detection_restarts_after_all_ports_fail(self):
        ports = SimpleNamespace(
            comports=lambda: [
                SimpleNamespace(device="COM2"),
                SimpleNamespace(device="COM10"),
            ]
        )
        report = io.StringIO()
        selected_capture = SimpleNamespace(device="COM10")
        with mock.patch.object(
            run_suite,
            "probe_serial_port",
            side_effect=[None, None, selected_capture],
        ) as probe:
            with contextlib.redirect_stdout(io.StringIO()):
                selected = run_suite.auto_detect_serial_port(
                    SimpleNamespace(),
                    ports,
                    run_suite.Reporter(report),
                    variant_name="m3_os",
                    image_log_path=Path("serial.log"),
                )

        self.assertIs(selected, selected_capture)
        self.assertEqual(
            [call.args[1] for call in probe.call_args_list],
            ["COM10", "COM2", "COM10"],
        )
        self.assertIn("restarting the search", report.getvalue())

    def test_successful_probe_capture_continues_to_suite_completion(self):
        pieces = [
            b"Starting Per",
            b"cepio Detect test\nDFMT:SUITE_BEGIN:m3_os:22222222\n",
            b"DFMT:BEGIN:1002:0\n",
            b"DFMT:RETURNED:1002:0\nDFMT:SUITE_COMPLETE:m3_os:22222222\n",
        ]
        port = FakeSerialPort(pieces)
        serial_factory = mock.Mock(return_value=port)
        serial_module = SimpleNamespace(
            Serial=serial_factory,
            SerialException=OSError,
            EIGHTBITS=8,
            PARITY_NONE="N",
            STOPBITS_ONE=1,
        )
        prepared: list[str] = []

        with tempfile.TemporaryDirectory() as directory:
            captured = Path(directory) / "serial.log"
            with contextlib.redirect_stdout(io.StringIO()):
                capture = run_suite.probe_serial_port(
                    serial_module,
                    "COM17",
                    self.reporter(),
                    variant_name="m3_os",
                    image_log_path=captured,
                    timeout_seconds=0.5,
                    prepare_probe=prepared.append,
                )
                self.assertIsNotNone(capture)
                assert capture is not None
                self.assertFalse(port.closed)
                result = capture.wait(timeout_seconds=3, idle_timeout_seconds=2)
                capture.close()

            self.assertTrue(result.completion_seen)
            self.assertEqual(captured.read_bytes(), b"".join(pieces))

        serial_factory.assert_called_once()
        self.assertEqual(prepared, ["COM17"])
        self.assertTrue(port.closed)

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
