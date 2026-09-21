import io
import contextlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

from dfm_tests import payload_review


class _TtyBuffer(io.StringIO):
    def isatty(self) -> bool:
        return True


def _write_test_cases(root: Path, *test_ids: str) -> None:
    docs = root / "testing-docs"
    docs.mkdir(parents=True, exist_ok=True)
    sections = [
        f"### Test {test_id} - Oracle {test_id}\n\n"
        f"- Expected evidence for {test_id}."
        for test_id in test_ids
    ]
    (docs / "dfm_test_cases.md").write_text(
        "\n\n".join(sections) + "\n",
        encoding="utf-8",
    )


class PayloadReviewTests(unittest.TestCase):
    def test_codex_usage_parser_does_not_double_count_cached_tokens(self):
        with tempfile.TemporaryDirectory() as directory:
            event_log = Path(directory) / "events.jsonl"
            event_log.write_text(
                '{"type":"turn.completed","usage":{'
                '"input_tokens":100,"cached_input_tokens":80,'
                '"cache_write_input_tokens":3,"output_tokens":20,'
                '"reasoning_output_tokens":7}}\n'
                'not-json\n',
                encoding="utf-8",
            )
            usage, available = payload_review._usage_from_event_log(event_log)

        metric = payload_review.AgentRunMetric(
            label="1001",
            role="test",
            attempt=1,
            model="gpt-5.6-sol",
            reasoning_effort="medium",
            elapsed_seconds=2.5,
            input_tokens=usage["input_tokens"],
            cached_input_tokens=usage["cached_input_tokens"],
            cache_write_input_tokens=usage["cache_write_input_tokens"],
            output_tokens=usage["output_tokens"],
            reasoning_output_tokens=usage["reasoning_output_tokens"],
            exit_code=0,
            usage_available=available,
        )

        self.assertTrue(available)
        self.assertEqual(metric.total_tokens, 120)
        self.assertEqual(metric.as_dict()["cached_input_tokens"], 80)

    def test_metrics_document_averages_physical_agent_processes(self):
        metrics = [
            payload_review.AgentRunMetric(
                label=str(index),
                role="test",
                attempt=1,
                model="gpt-5.6-sol",
                reasoning_effort="low",
                elapsed_seconds=seconds,
                input_tokens=tokens,
                cached_input_tokens=0,
                cache_write_input_tokens=0,
                output_tokens=10,
                reasoning_output_tokens=2,
                exit_code=0,
                usage_available=True,
            )
            for index, seconds, tokens in ((1, 2.0, 90), (2, 4.0, 190))
        ]

        document = payload_review._metrics_document(metrics)

        self.assertEqual(document["agent_processes"], 2)
        self.assertEqual(document["total_elapsed_seconds"], 6.0)
        self.assertEqual(document["average_elapsed_seconds"], 3.0)
        self.assertEqual(document["total_tokens"], 300)
        self.assertEqual(document["average_tokens"], 150.0)

    def test_console_uses_semantic_color_only_for_tty(self):
        terminal = _TtyBuffer()
        with mock.patch.dict(payload_review.os.environ):
            payload_review.os.environ.pop("NO_COLOR", None)
            payload_review._console(
                "Review 1/1", payload_review.YELLOW, file=terminal
            )

        self.assertEqual(
            terminal.getvalue(),
            f"{payload_review.YELLOW}Review 1/1{payload_review.RESET}\n",
        )

        redirected = io.StringIO()
        payload_review._console(
            "Review 1/1", payload_review.YELLOW, file=redirected
        )
        self.assertEqual(redirected.getvalue(), "Review 1/1\n")

        no_color_terminal = _TtyBuffer()
        with mock.patch.dict(
            payload_review.os.environ, {"NO_COLOR": "1"}
        ):
            payload_review._console(
                "Review 1/1",
                payload_review.YELLOW,
                file=no_color_terminal,
            )
        self.assertEqual(no_color_terminal.getvalue(), "Review 1/1\n")

    def test_progress_palette_distinguishes_notes_warnings_and_errors(self):
        self.assertEqual(
            payload_review._progress_color("Agent note: checking trace"),
            payload_review.BLUE,
        )
        self.assertEqual(
            payload_review._progress_color("Evidence command warning"),
            payload_review.YELLOW,
        )
        self.assertEqual(
            payload_review._progress_color("Codex reported an error"),
            payload_review.RED,
        )

    def test_loader_starts_normal_client_after_text_export(self):
        loader = (
            Path(__file__).resolve().parent.parent / "load-freertos-alerts.bat"
        ).read_text(encoding="utf-8")
        export = loader.index('call "%CLIENT_BAT%"', loader.index(":start_client"))
        clear_text_mode = loader.index(
            'set "DETECT_CLIENT_TEXT_OUTPUT="', export
        )
        interactive = loader.index("Start-Process", clear_text_mode)
        launch_line = loader[interactive:loader.index("\n", interactive)]

        self.assertLess(export, clear_text_mode)
        self.assertLess(clear_text_mode, interactive)
        self.assertIn("DETECT_ALERT_DIR and DETECT_ELF_PATH", loader)
        self.assertIn("-WorkingDirectory $env:CLIENT_DIR", launch_line)
        self.assertIn("-WindowStyle Normal", launch_line)
        self.assertNotIn("-Wait", launch_line)

    def test_loader_environment_enables_text_output_for_children(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = payload_review._loader_environment(
                Path(directory), "run-1"
            )

        self.assertEqual(environment["DETECT_CLIENT_TEXT_OUTPUT"], "1")
        self.assertEqual(environment["DETECT_CLIENT_RUN_ID"], "run-1")

    def test_manifest_matches_description_suffix_to_logical_test(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _write_test_cases(root, "1018", "1019", "1020")
            build = root / "Build-M3-Os"
            build.mkdir()
            (build / "eventlog-1019A-1789560147527.txt").write_text(
                "trace", encoding="utf-8"
            )
            (build / "coredump-1019B-1789560147528.txt").write_text(
                "gdb", encoding="utf-8"
            )
            (build / "serial.log").write_text(
                "DFMT:SUITE_BEGIN:m3_os:cookie\n"
                "DFMT:BEGIN:1018:0\n"
                "DFMT:RETURNED:1018:0\n"
                "DFMT:BEGIN:1019:1\n"
                "transport data omitted\n"
                "DFMT:CHECK:1019:PASS:ONE\n"
                "DFMT:RETURNED:1019:0\n"
                "DFMT:BEGIN:1020:2\n"
                "DFMT:RETURNED:1020:0\n"
                "DFMT:SUITE_COMPLETE:m3_os:cookie\n",
                encoding="utf-8",
            )
            (build / "build-config.json").write_text(
                json.dumps(
                    {
                        "platform": "FreeRTOS",
                        "variant": "m3_os",
                        "optimization": "-Os",
                    }
                ),
                encoding="utf-8",
            )
            manifest_path = payload_review._build_manifest(
                root,
                root,
                "run-1",
                [payload_review.ReviewTarget("1019", "Build-M3-Os", 2)],
            )
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

        entry = manifest["tests"][0]
        self.assertEqual(manifest["schema_version"], 4)
        self.assertNotIn("authoritative_docs", manifest)
        self.assertEqual(len(entry["artifacts"]), 2)
        self.assertIn("### Test 1019", entry["oracle"]["markdown"])
        self.assertNotIn("Test 1018", entry["oracle"]["markdown"])
        self.assertNotIn("Test 1020", entry["oracle"]["markdown"])
        self.assertEqual(
            entry["source_files"],
            ["dfm_tests/src/test_boundaries.c"],
        )
        self.assertNotIn("target_logs", entry)
        target_evidence = entry["target_evidence"][0]
        self.assertEqual(
            target_evidence["source"], "Build-M3-Os/serial.log"
        )
        target_text = "\n".join(
            item["text"] for item in target_evidence["lines"]
        )
        self.assertIn("DFMT:BEGIN:1019:1", target_text)
        self.assertIn("DFMT:CHECK:1019:PASS:ONE", target_text)
        self.assertIn("DFMT:RETURNED:1019:0", target_text)
        self.assertIn("DFMT:SUITE_COMPLETE:m3_os:cookie", target_text)
        self.assertNotIn("DFMT:BEGIN:1018", target_text)
        self.assertNotIn("DFMT:BEGIN:1020", target_text)
        self.assertNotIn("build_config", entry)
        self.assertEqual(
            entry["build_contract"]["cpu_policy"],
            "Portable common Cortex-M profile; M33 is valid.",
        )
        self.assertEqual(
            entry["build_config_evidence"]["settings"],
            {"optimization": "-Os"},
        )

    @mock.patch("dfm_tests.payload_review.subprocess.run")
    def test_chatgpt_login_rejects_api_key_status(self, run):
        run.return_value = subprocess.CompletedProcess(
            ["codex", "login", "status"], 0, "Logged in using API key\n"
        )

        accepted, _ = payload_review._chatgpt_login_ok("codex", {})

        self.assertFalse(accepted)

    @mock.patch("dfm_tests.payload_review.subprocess.run")
    def test_chatgpt_login_accepts_chatgpt_status(self, run):
        run.return_value = subprocess.CompletedProcess(
            ["codex", "login", "status"], 0, "Logged in using ChatGPT\n"
        )

        accepted, _ = payload_review._chatgpt_login_ok("codex", {})

        self.assertTrue(accepted)

    def test_review_prompt_uses_one_fresh_agent_without_nested_delegation(self):
        target = payload_review.ReviewTarget("1019", "Build-M3-Os", 2)
        prompt = payload_review._review_prompt(Path("manifest.json"), target)
        normalized = " ".join(prompt.split())

        self.assertIn("Review only logical test 1019", normalized)
        self.assertIn("one dedicated review agent", normalized)
        self.assertIn("Do not spawn subagents", normalized)
        self.assertIn("do not call collaboration wait", normalized)
        self.assertIn(
            "manifest already embeds the exact authoritative oracle",
            normalized,
        )
        self.assertIn("do not scan directories", normalized)
        self.assertIn("do not", normalized)
        self.assertIn("read other Markdown documents", normalized)
        self.assertIn("do not turn tool-output truncation", normalized)
        self.assertIn("do not open its source serial.log or qemu.log", normalized)
        self.assertIn("inventory every `[DFM Tests]` row", normalized)
        self.assertIn("not just the `[ALERT]` row", normalized)
        self.assertIn("Retry failed or truncated reads", normalized)
        self.assertIn("do not open build-config.json", normalized)

    def test_final_summary_prompt_is_short_and_neutral(self):
        prompt = payload_review._final_summary_prompt(
            Path("dfm_test_artifacts/diagnostic_review.md")
        )
        normalized = " ".join(prompt.split())

        self.assertEqual(
            normalized,
            "Read dfm_test_artifacts/diagnostic_review.md and summarize the "
            "review in 2-5 concise bullets. Return JSON matching the supplied "
            "schema.",
        )

    @mock.patch("dfm_tests.payload_review._run_codex_process")
    def test_final_summary_runs_one_read_only_codex_process(self, run_process):
        def complete_summary(**kwargs):
            artifact_root = kwargs["event_log"].parent
            (artifact_root / "payload-review-summary.json").write_text(
                json.dumps({"bullets": ["Outcome.", "Limitation."]}),
                encoding="utf-8",
            )
            return 0

        run_process.side_effect = complete_summary
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifacts = root / "dfm_test_artifacts"
            artifacts.mkdir()
            (artifacts / "diagnostic_review.md").write_text(
                "# Review\n", encoding="utf-8"
            )
            bullets = payload_review._run_final_review_summary(
                codex="codex",
                environment={},
                app_dir=root,
                artifact_root=artifacts,
                model="gpt-5.6-sol",
                reasoning_effort="medium",
            )
            schema_exists = (
                artifacts / "payload-review-summary-schema.json"
            ).is_file()

        self.assertEqual(bullets, ["Outcome.", "Limitation."])
        command = run_process.call_args.kwargs["command"]
        self.assertIn("--sandbox", command)
        self.assertEqual(command[command.index("--sandbox") + 1], "read-only")
        self.assertEqual(command[command.index("--model") + 1], "gpt-5.6-sol")
        self.assertIn('model_reasoning_effort="medium"', command)
        self.assertIn("diagnostic_review.md", run_process.call_args.kwargs["prompt"])
        self.assertTrue(schema_exists)

    @mock.patch("dfm_tests.payload_review._run_codex_process")
    def test_single_review_can_override_model_and_reasoning(self, run_process):
        def complete_review(**kwargs):
            artifact_root = kwargs["event_log"].parent
            (artifact_root / "payload-review-result-1001.json").write_text(
                json.dumps(
                    {
                        "summary": "done",
                        "tests": [
                            {
                                "test_id": "1001",
                                "verdict": "PASS",
                                "comment": "ok",
                                "evidence": [],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            return 0

        run_process.side_effect = complete_review
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = payload_review._run_single_test_review(
                codex="codex",
                environment={},
                app_dir=root,
                artifact_root=root,
                manifest_path=root / "manifest.json",
                schema_path=root / "schema.json",
                target=payload_review.ReviewTarget("1001", "Build-M3-O0", 1),
                index=1,
                total=1,
                model="gpt-5.6-sol",
                reasoning_effort="medium",
            )

        self.assertIsNotNone(result)
        command = run_process.call_args.kwargs["command"]
        self.assertEqual(
            command[command.index("--model") + 1], "gpt-5.6-sol"
        )
        self.assertIn(
            'model_reasoning_effort="medium"',
            command,
        )

    def test_diagnostic_report_uses_bulleted_overview(self):
        targets = [
            payload_review.ReviewTarget("1001", "Build-M3-O0", 1),
            payload_review.ReviewTarget("1025", "Build-M3-Os", 1),
        ]
        result = {
            "summary": "A legacy aggregate summary.",
            "tests": [
                {
                    "test_id": "1001",
                    "verdict": "PASS",
                    "comment": "Core evidence is complete.",
                    "evidence": ["Registers match."],
                },
                {
                    "test_id": "1025",
                    "verdict": "FAIL",
                    "comment": "Fault payload is unavailable.",
                    "evidence": ["No fault.dmp was exported."],
                },
            ],
        }

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for target in targets:
                (root / target.build_label).mkdir()
            payload_review._render_reports(root, "run-1", targets, result)
            report = (root / "diagnostic_review.md").read_text(
                encoding="utf-8"
            )

        self.assertIn("## Overview", report)
        self.assertIn("- **1001 — PASS:** Core evidence is complete.", report)
        self.assertIn("- **1025 — FAIL:** Fault payload is unavailable.", report)
        self.assertIn("## Evidence", report)
        self.assertIn("### Test 1025 — FAIL", report)
        self.assertNotIn("| Test | Verdict |", report)
        self.assertNotIn("A legacy aggregate summary.", report)

    def test_source_allowlist_covers_every_registered_test(self):
        self.assertEqual(
            set(payload_review._SOURCE_FILES_BY_TEST),
            {
                *(str(test_id) for test_id in range(1001, 1022)),
                "1022",
                "1023",
                "1024",
                "1025",
            },
        )

    def test_small_coredump_contract_requires_128_byte_buffer(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M3-SmallCD"]
        self.assertEqual(
            contract["required_settings"]["max_coredump_size"], "128"
        )
        variant_cmake = (
            Path(__file__).resolve().parent / "CMakeLists.txt"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "set(DFM_TEST_MAX_COREDUMP_SIZE 128)", variant_cmake
        )

    def test_m33_contract_requires_u585_and_large_coredump(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M33-Qual"]

        self.assertEqual(contract["variant"], "m33_qual")
        self.assertEqual(
            contract["required_settings"]["target"],
            "b_u585i_iot02a_stm32u585",
        )
        self.assertEqual(
            contract["required_settings"]["max_coredump_size"], "2048"
        )
        self.assertEqual(
            contract["required_settings"]["optimization"], "-O0"
        )

    def test_1025_oracle_requires_fault_payload(self):
        root = Path(__file__).resolve().parent.parent
        section = payload_review._test_oracle(root, "1025")["markdown"]

        self.assertIn("numeric type 1025", section)
        self.assertIn("`fault.dmp`", section)
        self.assertIn("undefined-instruction", section)
        self.assertIn("expected reset/resume", section)

    def test_build_config_evidence_extracts_only_contract_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "build-config.json"
            config.write_text(
                json.dumps(
                    {
                        "optimization": "-Os",
                        "coredumps_enabled": 0,
                        "unrelated": "ignored",
                    }
                ),
                encoding="utf-8",
            )
            evidence = payload_review._build_config_evidence(
                config,
                root,
                {
                    "optimization": "-Os",
                    "coredumps_enabled": 0,
                    "missing_value": 128,
                },
            )

        self.assertEqual(
            evidence["settings"],
            {
                "optimization": "-Os",
                "coredumps_enabled": 0,
                "missing_value": "missing",
            },
        )

    def test_progress_shows_evidence_operation_not_powershell_launcher(self):
        event = {
            "type": "item.started",
            "item": {
                "type": "command_execution",
                "command": (
                    '"C:\\\\Windows\\\\System32\\\\WindowsPowerShell\\\\v1.0'
                    '\\\\powershell.exe" -Command '
                    "'$ErrorActionPreference='Stop'; rg -n backtrace "
                    "'dfm_test_artifacts\\\\Build-M3-Os\\\\coredump-1019A.txt'"
                ),
            },
        }

        message = payload_review._progress_message(json.dumps(event))

        self.assertIn("Searching coredump-1019A.txt", message)
        self.assertIn("rg -n backtrace", message)
        self.assertIn("coredump-1019A.txt", message)
        self.assertNotIn("powershell.exe", message)

    def test_progress_explains_failed_search_is_not_final_verdict(self):
        event = {
            "type": "item.completed",
            "item": {
                "type": "command_execution",
                "command": "powershell.exe -Command rg -n missing evidence.txt",
                "aggregated_output": "",
                "exit_code": 1,
                "status": "failed",
            },
        }

        message = payload_review._progress_message(json.dumps(event))

        self.assertIn("found no matches", message)
        self.assertIn("not automatically a test failure", message)

    def test_progress_includes_agent_summary(self):
        update = {
            "summary": "Backtraces checked; trace ordering remains.",
            "tests": [],
        }
        event = {
            "type": "item.completed",
            "item": {
                "type": "agent_message",
                "text": json.dumps(update),
            },
        }

        message = payload_review._progress_message(json.dumps(event))

        self.assertEqual(
            message,
            "Agent note: Backtraces checked; trace ordering remains.",
        )

    @mock.patch(
        "dfm_tests.payload_review.shutil.which", return_value="C:/bin/codex.exe"
    )
    def test_codex_finder_prefers_path(self, which):
        self.assertEqual(payload_review._find_codex_cli(), "C:/bin/codex.exe")
        which.assert_called_once_with("codex")

    @mock.patch("dfm_tests.payload_review.shutil.which", return_value=None)
    def test_codex_finder_uses_chatgpt_desktop_installation(self, which):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = (
                root / "OpenAI" / "Codex" / "bin" / "version" / "codex.exe"
            )
            executable.parent.mkdir(parents=True)
            executable.write_bytes(b"codex")
            with mock.patch.dict(
                payload_review.os.environ,
                {"LOCALAPPDATA": str(root), "USERPROFILE": str(root / "user")},
            ):
                result = payload_review._find_codex_cli()

        self.assertEqual(result, str(executable))
        self.assertEqual(which.call_count, 2)

    @mock.patch(
        "dfm_tests.payload_review._run_final_review_summary",
        return_value=["All reviewed evidence is consistent.", "No failures."],
    )
    @mock.patch("dfm_tests.payload_review._run_single_test_review")
    @mock.patch(
        "dfm_tests.payload_review._chatgpt_login_ok",
        return_value=(True, "Logged in using ChatGPT"),
    )
    @mock.patch(
        "dfm_tests.payload_review._find_codex_cli",
        return_value="C:/bin/codex.exe",
    )
    def test_agentic_review_starts_one_fresh_process_per_test_in_order(
        self, find_codex, login, run_single, final_summary
    ):
        targets = [
            payload_review.ReviewTarget("1019", "Build-M3-Os", 2),
            payload_review.ReviewTarget("1001", "Build-M3-O0", 1),
        ]

        def result_for_target(**kwargs):
            test_id = kwargs["target"].test_id
            return {
                "summary": f"Reviewed {test_id}",
                "tests": [
                    {
                        "test_id": test_id,
                        "verdict": "PASS",
                        "comment": "ok",
                        "evidence": [],
                    }
                ],
            }

        run_single.side_effect = result_for_target
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _write_test_cases(root, "1001", "1019")
            for target in targets:
                (root / target.build_label).mkdir()

            accepted = payload_review.run_agentic_review(
                root, root, "run-1", targets
            )
            aggregate = json.loads(
                (root / "payload-review-result.json").read_text(
                    encoding="utf-8"
                )
            )
            report = (root / "diagnostic_review.md").read_text(
                encoding="utf-8"
            )
            run_log = (root / "dfm_test_run.log").read_text(encoding="utf-8")

        self.assertTrue(accepted)
        self.assertEqual(
            [item["test_id"] for item in aggregate["tests"]],
            ["1001", "1019"],
        )
        self.assertEqual(
            [call.kwargs["target"].test_id for call in run_single.call_args_list],
            ["1001", "1019"],
        )
        self.assertEqual(
            [call.kwargs["index"] for call in run_single.call_args_list],
            [1, 2],
        )
        self.assertEqual(
            [call.kwargs["manifest_path"].name for call in run_single.call_args_list],
            [
                "payload-review-manifest-1001.json",
                "payload-review-manifest-1019.json",
            ],
        )
        find_codex.assert_called_once_with()
        login.assert_called_once()
        final_summary.assert_called_once()
        self.assertIn("## Overview", report)
        self.assertIn("PASS: 2/2", run_log)
        self.assertIn("Failed tests: none.", run_log)

    @mock.patch(
        "dfm_tests.payload_review._run_final_review_summary",
        return_value=["One review process failed.", "Other evidence passed."],
    )
    @mock.patch("dfm_tests.payload_review._run_single_test_review")
    @mock.patch(
        "dfm_tests.payload_review._chatgpt_login_ok",
        return_value=(True, "Logged in using ChatGPT"),
    )
    @mock.patch(
        "dfm_tests.payload_review._find_codex_cli",
        return_value="C:/bin/codex.exe",
    )
    def test_agent_failure_retries_once_then_continues_remaining_tests(
        self, _find_codex, _login, run_single, final_summary
    ):
        targets = [
            payload_review.ReviewTarget("1002", "Build-M3-Os", 1),
            payload_review.ReviewTarget("1001", "Build-M3-O0", 1),
        ]
        pass_1002 = {
            "summary": "Reviewed 1002",
            "tests": [
                {
                    "test_id": "1002",
                    "verdict": "PASS",
                    "comment": "ok",
                    "evidence": [],
                }
            ],
        }
        run_single.side_effect = [None, None, pass_1002]

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _write_test_cases(root, "1001", "1002")
            for target in targets:
                (root / target.build_label).mkdir()

            accepted = payload_review.run_agentic_review(
                root, root, "run-1", targets
            )
            aggregate = json.loads(
                (root / "payload-review-result.json").read_text(
                    encoding="utf-8"
                )
            )
            run_log = (root / "dfm_test_run.log").read_text(encoding="utf-8")

        self.assertFalse(accepted)
        self.assertEqual(
            [item["test_id"] for item in aggregate["tests"]],
            ["1001", "1002"],
        )
        self.assertIn(
            "Agent infrastructure failure",
            aggregate["tests"][0]["comment"],
        )
        self.assertEqual(
            [call.kwargs["attempt"] for call in run_single.call_args_list],
            [1, 2, 1],
        )
        final_summary.assert_called_once()
        self.assertIn("PASS: 1/2", run_log)
        self.assertIn("Failed tests: 1001.", run_log)

    @mock.patch("dfm_tests.payload_review._run_single_test_review")
    @mock.patch(
        "dfm_tests.payload_review._chatgpt_login_ok",
        return_value=(True, "Logged in using ChatGPT"),
    )
    @mock.patch(
        "dfm_tests.payload_review._find_codex_cli",
        return_value="C:/bin/codex.exe",
    )
    def test_payload_fail_verdict_makes_review_fail_without_final_summary(
        self, _find_codex, _login, run_single
    ):
        run_single.return_value = {
            "summary": "Mismatch found",
            "tests": [
                {
                    "test_id": "1001",
                    "verdict": "FAIL",
                    "comment": "Injected mismatch.",
                    "evidence": ["bad value"],
                }
            ],
        }
        target = payload_review.ReviewTarget("1001", "Build-M3-O0", 1)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            _write_test_cases(root, "1001")
            (root / target.build_label).mkdir()

            accepted = payload_review.run_agentic_review(
                root,
                root,
                "run-1",
                [target],
                run_final_summary=False,
                publish_summary=False,
            )

        self.assertFalse(accepted)

    @mock.patch("dfm_tests.payload_review.run_detect_loader")
    @mock.patch("dfm_tests.payload_review._ask_yes_no", return_value=False)
    def test_partial_suite_requires_consent_before_loader(self, ask, loader):
        result = payload_review.postprocess_suite(
            app_dir=Path("."),
            artifact_root=Path("dfm_test_artifacts"),
            suite_exit_code=0,
            interrupted=False,
            full_selection=False,
            targets=[],
        )

        self.assertEqual(result, 0)
        ask.assert_called_once()
        loader.assert_not_called()

    @mock.patch("dfm_tests.payload_review.run_agentic_review", return_value=True)
    @mock.patch(
        "dfm_tests.payload_review.run_detect_loader",
        return_value=(True, {"run_id": "run-1"}),
    )
    def test_assume_yes_accepts_both_post_suite_questions(self, loader, review):
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            result = payload_review.postprocess_suite(
                app_dir=Path("."),
                artifact_root=Path("dfm_test_artifacts"),
                suite_exit_code=0,
                interrupted=False,
                full_selection=False,
                targets=[],
                assume_yes=True,
            )

        self.assertEqual(result, 0)
        loader.assert_called_once()
        review.assert_called_once()
        self.assertEqual(output.getvalue().count("yes (--yes)"), 2)

if __name__ == "__main__":
    unittest.main()
