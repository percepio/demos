# DFM Per-Test Review Instructions

Use these instructions when reviewing one DFM test in a fresh Codex session.
The review concerns the alert payload produced by the test; it is not a request
to change the DFM implementation.

## Relevant files

- `C:\src\DemosRepo\ZephyrDemo\testing-docs\dfm_test_cases.md` — primary test
  specification and manual oracle.
- `C:\src\DemosRepo\ZephyrDemo\dfm_tests\src\` — implementation of each test.
- `C:\src\DemosRepo\ZephyrDemo\dfm_tests\run_suite.py` — test registry, build
  variants, and execution rules.
- `C:\src\DemosRepo\ZephyrDemo\dfm_test_artifacts\` — generated ELF files and
  QEMU logs for each revision/build variant.
- `C:\src\DemosRepo\ZephyrDemo\dfm_test_run.log` — complete suite execution log.
- `C:\src\DemosRepo\ZephyrDemo\testing-docs\test-reports\dfm_test_report.md` —
  the single consolidated review report to update.
- `C:\src\DemosRepo\ZephyrDemo\AGENTS.md` — mandatory test-execution policy.

The other files under `testing-docs/` may be consulted if the primary oracle
is ambiguous.

## Evidence supplied by the user

After the initial prompt, the user will paste alert metadata such as the Alert
Key, Revision, and Description, followed by one or more alert payload exports.
These payloads can include:

- GDB output obtained from the alert's `trap.zpr`, including registers,
  variables, selected frames, and preferably `bt -full`.
- A TraceRecorder text export from the alert's `dfm_trace.psfs`.
- Detect alert details or screenshots.

The coredump-viewer startup script prints a fixed selection of frames. That
output is not the GDB `bt` command and must not be described as a complete
backtrace. Use an explicitly supplied `bt` or `bt -full` when evaluating the
full unwind chain.

Trace exports may retain events from earlier tests in the same recorder buffer.
Judge the current test from its own `Txxxx BEGIN` marker onward. The
TraceRecorder `[ALERT]` event text may also be shorter than the full Detect
Description; report this only if the actual alert Description is incorrect.

## Review procedure

For the supplied test, compare all three sources:

1. The expected behavior and manual oracle in `dfm_test_cases.md`.
2. The corresponding test implementation in `dfm_tests/src/`, including exact
   arguments, sentinel values, trace events, call chain, and `DFM_TRAP()` call.
3. The supplied alert payloads and the matching local build/run artifacts.

Check the revision/build variant, alert description and callsite, test return
status, coredump validity, registers, arguments, locals, unwind chain, and trace
ordering where they are part of that test's oracle. Do not invent evidence that
was not supplied or available locally. Explicitly identify any mismatch or
missing evidence that prevents a confident recommendation.

## Report update

Edit this exact file, not a copy:

`C:\src\DemosRepo\ZephyrDemo\testing-docs\test-reports\dfm_test_report.md`

Never edit the `# DFM Test Report Overview` section; it is maintained only by
the user. Add or update one compact test section under `# Codex Review`, using
the style already established by the preceding test sections. Include:

- `**Reviewer:** Codex`
- build and artifact identification
- brief reviewed evidence
- a short explanation of any harmless anomaly
- `**Recommendation:** PASS` when no problem is found, otherwise a clearly
  justified `FAIL` or statement that the evidence is insufficient

Keep the section concise because the report covers 25 tests. In the final reply,
state the recommendation and link to the updated section. Do not add generic
verdict disclaimers.

## Execution restriction

Never run `load-zephyr-alerts.bat` or perform its Detect cleanup/loading
steps. It deletes previous results. Do not start, stop, clean, or modify Detect,
its database, containers, alert directory, server, or client. If execution is
needed, only `python dfm_tests/run_suite.py` (optionally with its documented
variant selection) is permitted, and it should not be rerun merely to review
payload evidence already supplied by the user.

## Ready-to-use session prompt

Replace `<TEST_ID>` and paste the following as the first message in a new
session:

```text
Review DFM Test <TEST_ID> using the instructions in:
C:\src\DemosRepo\ZephyrDemo\testing-docs\test-reports\dfm_test_review_instructions.md

Use the test oracle, source implementation, and matching local artifacts when
reviewing the alert payload. After the review, add or update the compact Codex
section for this test in the consolidated report. Do not edit the DFM Test
Report Overview and do not run load-zephyr-alerts.bat.

I will next paste the alert metadata (Alert Key, Revision, and Description),
followed by payload data such as the TraceRecorder text export and GDB output
from the coredump. Wait for that evidence before making the recommendation.
```
