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
            Path(__file__).resolve().parent.parent / "load-zephyr-alerts.bat"
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
            (build / "alert-metadata-1019A-1789560147527.txt").write_text(
                "Payload count: 1\n", encoding="utf-8"
            )
            (build / "eventlog-1019A-1789560147527.txt").write_text(
                "trace", encoding="utf-8"
            )
            (build / "alert-metadata-1019B-1789560147528.txt").write_text(
                "Payload count: 1\n", encoding="utf-8"
            )
            (build / "coredump-1019B-1789560147528.txt").write_text(
                r"Remote debugging using C:\cache\trap.zpr" + "\n",
                encoding="utf-8",
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
            (build / "zephyr.config").write_text(
                "CONFIG_CPU_CORTEX_M33=y\n"
                "CONFIG_SIZE_OPTIMIZATIONS=y\n"
                "CONFIG_INIT_STACKS=y\n"
                "CONFIG_THREAD_STACK_INFO=y\n",
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
        self.assertEqual(manifest["schema_version"], 5)
        self.assertNotIn("authoritative_docs", manifest)
        self.assertEqual(len(entry["artifacts"]), 4)
        self.assertEqual(
            entry["payload_inventory"],
            [
                {
                    "alert_id": "1019A",
                    "session_id": "1789560147527",
                    "metadata": (
                        "Build-M3-Os/"
                        "alert-metadata-1019A-1789560147527.txt"
                    ),
                    "declared_count": 1,
                    "payloads": [
                        {
                            "name": "dfm_trace.psfs",
                            "evidence": (
                                "Build-M3-Os/"
                                "eventlog-1019A-1789560147527.txt"
                            ),
                        }
                    ],
                    "complete": True,
                    "errors": [],
                },
                {
                    "alert_id": "1019B",
                    "session_id": "1789560147528",
                    "metadata": (
                        "Build-M3-Os/"
                        "alert-metadata-1019B-1789560147528.txt"
                    ),
                    "declared_count": 1,
                    "payloads": [
                        {
                            "name": "trap.zpr",
                            "evidence": (
                                "Build-M3-Os/"
                                "coredump-1019B-1789560147528.txt"
                            ),
                        }
                    ],
                    "complete": True,
                    "errors": [],
                },
            ],
        )
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
        self.assertIn(
            "does not require CONFIG_CPU_CORTEX_M3",
            entry["build_contract"]["cpu_policy"],
        )
        self.assertEqual(
            entry["build_config_evidence"]["settings"],
            {
                "CONFIG_SIZE_OPTIMIZATIONS": "y",
                "CONFIG_INIT_STACKS": "y",
                "CONFIG_THREAD_STACK_INFO": "y",
            },
        )

    def test_payload_inventory_rejects_unaccounted_payload(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            build = root / "Build-M3-Os"
            build.mkdir()
            metadata = "Build-M3-Os/alert-metadata-1002-session.txt"
            eventlog = "Build-M3-Os/eventlog-1002-session.txt"
            (root / metadata).write_text(
                "Payload count: 2\n", encoding="utf-8"
            )
            (root / eventlog).write_text("trace\n", encoding="utf-8")

            inventory = payload_review._payload_inventory(
                root, [metadata, eventlog]
            )

        self.assertEqual(len(inventory), 1)
        self.assertFalse(inventory[0]["complete"])
        self.assertEqual(
            inventory[0]["payloads"],
            [{"name": "dfm_trace.psfs", "evidence": eventlog}],
        )
        self.assertIn("declares 2 payload", inventory[0]["errors"][0])

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
        self.assertIn("per-alert payload inventory", normalized)
        self.assertIn("do not scan directories", normalized)
        self.assertIn("do not", normalized)
        self.assertIn("read other Markdown documents", normalized)
        self.assertIn("do not turn tool-output truncation", normalized)
        self.assertIn("do not open its source serial.log or qemu.log", normalized)
        self.assertIn("inventory every `[DFM Tests]` row", normalized)
        self.assertIn("not just the `[ALERT]` row", normalized)
        self.assertIn("Retry failed or truncated reads", normalized)
        self.assertIn("M3 profile name does not require", normalized)

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
            payload_review.ReviewTarget("1022", "Build-M33-Qual", 1),
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
                    "test_id": "1022",
                    "verdict": "FAIL",
                    "comment": "FP registers are unavailable.",
                    "evidence": ["Only core registers were exported."],
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
        self.assertIn("- **1022 — FAIL:** FP registers are unavailable.", report)
        self.assertIn("## Evidence", report)
        self.assertIn("### Test 1022 — FAIL", report)
        self.assertNotIn("| Test | Verdict |", report)
        self.assertNotIn("A legacy aggregate summary.", report)

    def test_source_allowlist_covers_every_registered_test(self):
        self.assertEqual(
            set(payload_review._SOURCE_FILES_BY_TEST),
            {str(test_id) for test_id in range(1001, 1031)},
        )

    def test_every_oracle_declares_exhaustive_expected_payloads(self):
        root = Path(__file__).resolve().parent.parent

        for test_id in payload_review._SOURCE_FILES_BY_TEST:
            with self.subTest(test_id=test_id):
                section = payload_review._test_oracle(root, test_id)[
                    "markdown"
                ]
                normalized = " ".join(section.split())
                self.assertIn("**Expected payloads:**", normalized)
                if test_id in ("1010", "1028"):
                    self.assertIn("**Expected payloads:** None", normalized)
                else:
                    self.assertIn(
                        "no other payloads are allowed", normalized.lower()
                    )

    def test_special_payload_oracles_are_explicit(self):
        root = Path(__file__).resolve().parent.parent
        oracle_1015 = " ".join(
            payload_review._test_oracle(root, "1015")["markdown"].split()
        )
        oracle_1017 = " ".join(
            payload_review._test_oracle(root, "1017")["markdown"].split()
        )
        oracle_1020 = " ".join(
            payload_review._test_oracle(root, "1020")["markdown"].split()
        )
        oracle_1025 = " ".join(
            payload_review._test_oracle(root, "1025")["markdown"].split()
        )
        oracle_1026 = " ".join(
            payload_review._test_oracle(root, "1026")["markdown"].split()
        )
        oracle_1027 = " ".join(
            payload_review._test_oracle(root, "1027")["markdown"].split()
        )
        oracle_1028 = " ".join(
            payload_review._test_oracle(root, "1028")["markdown"].split()
        )
        oracle_1029 = " ".join(
            payload_review._test_oracle(root, "1029")["markdown"].split()
        )
        oracle_1030 = " ".join(
            payload_review._test_oracle(root, "1030")["markdown"].split()
        )

        self.assertIn("Exactly `dfm_trace.psfs`, with no `trap.zpr`", oracle_1015)
        self.assertIn("Exactly `trap.zpr`, with no `dfm_trace.psfs`", oracle_1017)
        self.assertIn("recorder is stopped at runtime", oracle_1017)
        self.assertIn(
            "exactly `dfm_trace.psfs`, with no `trap.zpr`",
            oracle_1020,
        )
        self.assertIn(
            "Exactly `fault.zpr`, with no `dfm_trace.psfs` or `trap.zpr`",
            oracle_1025,
        )
        self.assertIn(
            "Exactly `trap.zpr`, with no `dfm_trace.psfs` or `fault.zpr`",
            oracle_1026,
        )
        self.assertIn(
            "Exactly `trap.zpr` and `dfm_trace.psfs`, with no `fault.zpr`",
            oracle_1027,
        )
        self.assertIn("Test 1027B", oracle_1027)
        self.assertIn("T1027 RETAIN BEGIN", oracle_1027)
        self.assertIn("T1027 RETAIN END", oracle_1027)
        self.assertIn("**Expected payloads:** None", oracle_1028)
        self.assertIn("CORRUPTION_REJECTED", oracle_1028)
        self.assertIn("one complete `trap.zpr`", oracle_1029)
        self.assertIn("leading prefix of `dfm_trace.psfs`", oracle_1029)
        self.assertIn("trace chunks 1-6 of 7", oracle_1029)
        self.assertIn(
            "Exactly `trap.zpr`, with no `dfm_trace.psfs` or `fault.zpr`",
            oracle_1030,
        )

    def test_m33_contract_and_overlay_require_2048_byte_coredump(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M33-Qual"]
        self.assertEqual(
            contract["required_settings"][
                "CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE"
            ],
            "2048",
        )
        overlay = (
            Path(__file__).resolve().parent / "conf" / "m33.conf"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE=2048",
            overlay.splitlines(),
        )

    def test_no_coredump_contract_requires_trace_without_coredumps(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M3-NoCD"]
        required = contract["required_settings"]
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS"],
            "disabled",
        )
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE"],
            "y",
        )
        overlay = (
            Path(__file__).resolve().parent / "conf" / "no_coredump.conf"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=y",
            overlay.splitlines(),
        )

    def test_no_trace_contract_requires_coredumps_without_trace(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M3-NoTrace"]
        required = contract["required_settings"]
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS"],
            "y",
        )
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE"],
            "disabled",
        )
        overlay = (
            Path(__file__).resolve().parent / "conf" / "no_trace.conf"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS=y",
            overlay.splitlines(),
        )
        self.assertIn(
            "CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n",
            overlay.splitlines(),
        )

    def test_retained_contract_and_board_regions_are_explicit(self):
        contract = payload_review._BUILD_CONTRACTS["Build-M3-Retained"]
        required = contract["required_settings"]
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY"], "y"
        )
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_COREDUMP_RETAIN"], "y"
        )
        self.assertEqual(
            required["CONFIG_PERCEPIO_DFM_CFG_COREDUMP_SEND"], "disabled"
        )

        root = Path(__file__).resolve().parent.parent
        config = (root / "dfm_tests" / "conf" / "retained.conf").read_text(
            encoding="utf-8"
        )
        for setting in (
            "CONFIG_RETAINED_MEM_MUTEX_FORCE_DISABLE=y",
            "CONFIG_RETENTION_MUTEX_FORCE_DISABLE=y",
            "CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY=y",
            "CONFIG_PERCEPIO_DFM_CFG_COREDUMP_RETAIN=y",
            "CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=y",
        ):
            self.assertIn(setting, config.splitlines())

        board_regions = {
            "qemu_cortex_m3": ("0x2000db50", "0xdb50"),
            "b_u585i_iot02a": ("0x200bdb50", "0xbdb50"),
        }
        for board, (retained_base, normal_ram_size) in board_regions.items():
            board_overlay = (root / "boards" / f"{board}.overlay").read_text(
                encoding="utf-8"
            )
            self.assertNotIn("retention0", board_overlay)

            overlay = (
                root / "boards" / f"{board}_retained.overlay"
            ).read_text(
                encoding="utf-8"
            )
            self.assertIn("retention0: retention@0", overlay)
            self.assertIn(f"reg = <{retained_base} 0x24b0>;", overlay)
            self.assertIn("reg = <0x0 0x24b0>;", overlay)
            self.assertIn(f"reg = <0x20000000 {normal_ram_size}>;", overlay)
            self.assertIn("prefix = [44 46 4d 52];", overlay)
            self.assertIn("checksum = <0>;", overlay)

        small_contract = payload_review._BUILD_CONTRACTS["Build-M3-Ret8K"]
        self.assertEqual(small_contract["variant"], "m3_retained_8k")
        small_config = (
            root / "dfm_tests" / "conf" / "retained_8k.conf"
        ).read_text(encoding="utf-8")
        self.assertIn(
            'CONFIG_PERCEPIO_DFM_CFG_FIRMWARE_VERSION="Build-M3-Ret8K"',
            small_config.splitlines(),
        )

        small_regions = {
            "qemu_cortex_m3": ("0x2000e000", "0xe000"),
            "b_u585i_iot02a": ("0x200be000", "0xbe000"),
        }
        for board, (retained_base, normal_ram_size) in small_regions.items():
            overlay = (
                root / "boards" / f"{board}_retained_8k.overlay"
            ).read_text(encoding="utf-8")
            self.assertIn(f"reg = <{retained_base} 0x2000>;", overlay)
            self.assertIn("reg = <0x0 0x2000>;", overlay)
            self.assertIn(f"reg = <0x20000000 {normal_ram_size}>;", overlay)
            self.assertIn("prefix = [44 46 4d 52];", overlay)
            self.assertIn("checksum = <0>;", overlay)

    def test_1022_oracle_does_not_require_exported_fp_registers(self):
        root = Path(__file__).resolve().parent.parent
        section = payload_review._test_oracle(root, "1022")["markdown"]

        self.assertIn("One alert with a coredump", section)
        self.assertIn("core registers", section)
        self.assertIn("unwind succeeds", section)
        self.assertIn("normal return", section)
        self.assertIn("`s0`–`s31` and `FPSCR` are therefore not expected", section)
        self.assertIn("their absence must not fail this test", section)

    def test_disabled_kconfig_contract_accepts_not_set_or_omitted_symbol(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "zephyr.config"
            config.write_text(
                "# CONFIG_EXPLICITLY_OFF is not set\nCONFIG_ENABLED=y\n",
                encoding="utf-8",
            )
            evidence = payload_review._build_config_evidence(
                config,
                root,
                {
                    "CONFIG_EXPLICITLY_OFF": "disabled",
                    "CONFIG_OMITTED_OFF": "disabled",
                    "CONFIG_ENABLED": "y",
                },
            )

        self.assertEqual(
            evidence["settings"],
            {
                "CONFIG_EXPLICITLY_OFF": "disabled",
                "CONFIG_OMITTED_OFF": "disabled",
                "CONFIG_ENABLED": "y",
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
