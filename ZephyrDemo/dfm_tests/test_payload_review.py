import io
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
            (build / "eventlog-1019A-1789560147527.txt").write_text(
                "trace", encoding="utf-8"
            )
            (build / "coredump-1019B-1789560147528.txt").write_text(
                "gdb", encoding="utf-8"
            )
            (build / "serial.log").write_text("target", encoding="utf-8")
            (build / "zephyr.config").write_text("config", encoding="utf-8")
            manifest_path = payload_review._build_manifest(
                root,
                root,
                "run-1",
                [payload_review.ReviewTarget("1019", "Build-M3-Os", 2)],
            )
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

        entry = manifest["tests"][0]
        self.assertEqual(manifest["schema_version"], 2)
        self.assertNotIn("authoritative_docs", manifest)
        self.assertEqual(len(entry["artifacts"]), 2)
        self.assertIn("### Test 1019", entry["oracle"]["markdown"])
        self.assertNotIn("Test 1018", entry["oracle"]["markdown"])
        self.assertNotIn("Test 1020", entry["oracle"]["markdown"])
        self.assertEqual(
            entry["source_files"],
            ["dfm_tests/src/test_boundaries.c"],
        )
        self.assertEqual(entry["target_logs"], ["Build-M3-Os/serial.log"])
        self.assertEqual(entry["build_config"], "Build-M3-Os/zephyr.config")

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
        self.assertIn("Read each allowlisted file at most once", normalized)
        self.assertIn("Do not read the complete zephyr.config", normalized)

    def test_source_allowlist_covers_every_registered_test(self):
        self.assertEqual(
            set(payload_review._SOURCE_FILES_BY_TEST),
            {str(test_id) for test_id in range(1001, 1025)},
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
        self, find_codex, login, run_single
    ):
        targets = [
            payload_review.ReviewTarget("1001", "Build-M3-O0", 1),
            payload_review.ReviewTarget("1019", "Build-M3-Os", 2),
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


if __name__ == "__main__":
    unittest.main()
