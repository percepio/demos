# Automated DFM payload text export and review

The DFM suite can turn every alert payload into a stable text artifact and
then offer an independent Codex review. The intent is to give both the human
reviewer and Codex the same direct diagnostic evidence without copying GDB and
Tracealyzer output by hand. The Codex verdict is a second opinion; the manual
product verdict remains authoritative.

## End-to-end flow

`dfm_tests/run_suite.py` sets `DETECT_CLIENT_TEXT_OUTPUT=1` in its own
environment and in every child environment. After a complete successful suite
it invokes:

```bat
load-zephyr-alerts.bat --suite-artifacts
```

`--suite-artifacts` is important: it forces the loader to use only the freshly
recreated `dfm_test_artifacts/Build-*` tree, even when a later standalone
`qemu_last_session.log` exists. A failed, interrupted, `--variants`, or
`--testcase` run asks before doing the full Detect load. Use
`--skip-payload-processing` when the suite must stop after target validation.
This is also required when an automated caller has not received permission to
run the destructive Detect loader.

Use `-y` or `--yes` to answer yes to both post-suite questions without
interactive input. On focused, failed, or interrupted runs this confirms the
full Detect load/text export; after a successful export it also starts the
Agentic payload review.

The full loader still owns all Detect cleanup/start behavior. It first runs
the Receiver with `--verbose` for every selected build log. Only after all
Receiver invocations have created their alert-file trees does it start the
Client. `run_suite.py` mirrors the complete Receiver/loader terminal output to
`dfm_test_artifacts/detect-load-<run-id>.txt`. In text mode the Client runs
synchronously as a one-shot payload processor instead of starting its HTTP
server. It reconstructs each file from the Receiver-created chunks and invokes
the existing Tracealyzer/coredump batch handler directly. This avoids the
interactive Dispatcher lifecycle in test automation. Loader completion means
that every Receiver and text exporter has finished, in that order. After a
successful export, the loader removes `DETECT_CLIENT_TEXT_OUTPUT` from its
local child environment and starts a fresh Client in a visible, detached
process without waiting for it. The detached process does not inherit the
loader's captured output pipe, so it cannot hold suite post-processing open.
That Client retains the same `DETECT_ALERT_DIR` and `DETECT_ELF_PATH`, allowing
the exported alerts to be opened manually from the Detect dashboard while the
optional agent review runs.

## Artifact identity and files

For each alert, the Client reads the numeric Alert Type from the binary alert
header and the unique Session ID from the alert directory. If the Description
contains a matching A/B identity such as `Test 1019A`, that suffix is retained
to make paired alerts immediately recognizable. The build directory comes
from the alert's Revision metadata.

The generated files are:

```text
dfm_test_artifacts/<Revision>/alert-metadata-<test-id>[-A|-B]-<session-id>.txt
dfm_test_artifacts/<Revision>/eventlog-<test-id>[-A|-B]-<session-id>.txt
dfm_test_artifacts/<Revision>/coredump-<test-id>[-A|-B]-<session-id>.txt
```

The metadata file is written from the Receiver-created binary alert header and
payload headers. It records Alert Type, Description, Revision, device, Product
ID, Session ID, alert path, and payload numbers. Thus each review has compact
per-alert metadata beside its payload exports, while the complete raw Receiver
`--verbose` output remains in the loader log.

Each build also archives the generated `syscalls-v<zephyr-version>.xml` beside
its ELF. TraceRecorder logs reference this Tracealyzer extension; keeping it in
`TZ_CFG_PATH` is required for unattended `export-log-nots` operation.

Trace payloads use Tracealyzer's `export-log-nots` command. Coredump handlers
receive the optional final argument `--outfile <file>`. Without that argument
they retain the normal interactive GDB session. With it they run to completion,
write combined stdout/stderr, and add `bt -full`; that backtrace command is not
injected into the interactive mode.

## Completion status

The runner first writes an atomic `running` status to
`dfm_test_artifacts/detect-load-status.json`. After the synchronous loader
exits it atomically replaces that status with `complete` or `failed`, including
the run ID, timestamps, exit code, loader log, generated artifact list, and
captured error lines. The final status is also published as
`alert-files/load-status.json`. A consumer must match the current run ID and
require `state: complete`; an old status cannot be mistaken for the current
run because the artifact root is recreated and the run ID is unique.

## Agentic payload review

Only after successful text export does the runner ask:

```text
Start Agentic payload review? [y/N]
```

On consent, it locates the installed Codex CLI and removes API-key variables
from that child environment. It runs `codex login status` and proceeds only
when the CLI explicitly reports ChatGPT authentication. Unknown status or API
key authentication aborts the review before model execution, preventing an
unintended separate API charge.

Python starts exactly one independent `codex exec` process per logical test.
Each process gets a fresh context window, a read-only sandbox, a single-test
prompt, a manifest containing only that test, and a structured-output schema.
Processes run strictly one at a time in numeric Test ID order, beginning with
Test 1001: one test review must exit before Python starts the next. There is no
nested agent delegation or parent-agent wait, which keeps context isolated and
makes progress and manual interruption predictable.

After all per-test verdicts have been written, Python generates
`diagnostic_review.md` with a compact bullet-list overview followed by the
detailed evidence for each test. One final read-only Codex process reads only
that completed report and returns two to five high-level summary bullets. It
does not calculate statistics: Python derives the exact PASS count and failed
test IDs from the structured per-test results. The resulting block is printed
to the terminal and appended verbatim to `dfm_test_run.log`, for example:

```text
  PASS: 22/24
  Failed tests: 1022, 1023.
  See 'diagnostic_review.md' for details.
```

To keep reviews fast, Python extracts only the selected test's `### Test ...`
section from the authoritative `dfm_test_cases.md` and embeds it in that test's
manifest. The manifest also contains an explicit evidence allowlist. Each test
agent reads only:

- all matching alert-metadata, eventlog and coredump text files;
- the embedded per-test oracle;
- the preselected implementation files under `dfm_tests/`;
- a compact target-side `DFMT:` block embedded by Python;
- an explicit build contract and its pre-extracted Kconfig values.

The compact `dfm_payload_review_agent.md` protocol forbids broad repository
searches, whole-document reads, historical-report comparison, ELF inspection,
and file hashing. Missing or contradictory allowlisted evidence is reported as
FAIL rather than triggering open-ended discovery. `dfm_test_cases.md` remains
the single canonical oracle; the embedded excerpt is generated, not maintained
separately. Redundant full-file reads are avoided, but failed or truncated
commands are retried with narrower queries instead of becoming false product
failures. Python reads the target log before model execution and embeds only
the current test's contiguous `DFMT:` block, with original line numbers and
suite markers. The agent never opens the full `serial.log` or `qemu.log`.
Likewise, the agent never opens `zephyr.config`. Python embeds only the settings
listed by the variant's build contract. The historic `m3_*` profile names mean
portable common Cortex-M coverage, not a physical Cortex-M3 requirement, so
those profiles are valid on Cortex-M33 hardware. Only `m33_qual` asserts an
M33-specific CPU/configuration contract.

It checks payload presence/absence, registers and locals, backtraces, fault
data, TraceRecorder events and ordering. Missing, corrupt, contradictory, or
still-unreviewable evidence after narrow retries is a FAIL. Reports are written
to the aggregate
`dfm_test_artifacts/diagnostic_review.md` and to each involved
`dfm_test_artifacts/<Revision>/diagnostic_review.md`. A combined structured
result is stored as `payload-review-result.json`; each test also retains
`payload-review-manifest-<test-id>.json`,
`payload-review-result-<test-id>.json`, and
`payload-review-codex-<test-id>.jsonl` for auditability and progress diagnosis.
The final pass additionally retains `payload-review-summary.json`,
`payload-review-summary-schema.json`, and
`payload-review-codex-summary.jsonl`.

The ordinary review can override the Codex model and reasoning effort. If the
arguments are omitted, the current Codex configuration is used. Every agent
process records elapsed time and the input, cached-input, cache-write, output,
and reasoning token fields from the Codex JSONL stream. Totals and averages are
printed to the console and saved as
`dfm_test_artifacts/payload-review-metrics.json`:

```powershell
python dfm_tests/run_suite.py --yes `
  --model 5.6-Sol --reasoning-effort medium
```

To repeat only the Agentic review over an already completed Detect text export,
without building, starting QEMU, clearing artifacts, or running the loader:

```powershell
python dfm_tests/run_suite.py --agent-review-only `
  --model 5.6-Sol --reasoning-effort medium
```

`--testcase` or `--variants` can narrow this review-only mode to tests already
present in `detect-load-status.json`. A payload `FAIL`, a missing structured
verdict, or an agent infrastructure error makes the command fail.

## Agent-review benchmark

The reviewer benchmark uses the first N tests in the existing payload export;
N defaults to 3 when omitted:

```powershell
python dfm_tests/run_suite.py --benchmark-agent-review
python dfm_tests/run_suite.py --benchmark-agent-review 5
```

It runs this fixed matrix:

- 5.6-Luna: `low`, `medium`, `ultra`;
- 5.6-Terra: `low`, `medium`, `ultra`;
- 5.6-Sol: `low`, `medium`, `xhigh`.

Each configuration reviews N unmodified copies, which must all pass, followed
by N fault-injected copies, which must all fail. The injected copies contain
invalid metadata, removed or malformed TraceRecorder evidence, and simulated
GDB output ending in `ELF file not found. <eof>`. Baseline payloads are never
modified. With the default N=3 this is 54 logical agent passes.

The benchmark omits the extra agent-written final summary for each
configuration. Python deterministically evaluates the expected PASS and FAIL
verdicts, includes retry cost in the totals, and divides by `2*N` when
reporting average time and tokens per logical pass. Reports are written below
an ignored `build/agent-review-benchmark-*` directory.

## Agent-review fault injection

After a completely green run, the reviewer can be checked without rerunning
QEMU or reloading Detect:

```powershell
python dfm_tests/run_fault_injection_review.py
```

The command verifies that tests 1001, 1002, 1003, and 1012 were green and
copies only their evidence below an ignored
`build/fault-injection-review-*` directory. It then injects deterministic
coredump, event-log, metadata, missing-payload, and simulated GDB/ELF defects.
The original `dfm_test_artifacts` tree is not modified.

The summary lists tests that failed as expected, unexpected PASS verdicts,
explicitly detected injected faults, and faults not mentioned by the agent.
The command returns zero only when every affected test receives `FAIL`; missed
individual fault details are still reported. Use `--prepare-only` to create
and inspect the copies without starting Codex:

```powershell
python dfm_tests/run_fault_injection_review.py --prepare-only
```

The model and reasoning level can also be overridden with `--model` and
`--reasoning-effort`.

During a review, `Inspecting:` lines describe distinct read/search operations;
they do not mean that the complete analysis has restarted. Successful command
completion is intentionally silent. A search with no match or another
non-zero evidence command is shown as a warning and explicitly distinguished
from the test verdict. Only `Review N/M complete - test <id>: PASS|FAIL`
reports the validated final verdict for that test. `Agent note:` lines are
provisional progress summaries, not additional agents or final results. The
`Review N/M` header identifies the active test; individual progress lines are
indented without repeating that index or the generic PowerShell launcher.

Interactive terminal output uses one semantic ANSI palette throughout the
suite and review: yellow for phase/review headings and warnings, cyan for active
steps and evidence operations, blue for informational lines and agent notes,
green for PASS/success, and red for FAIL/errors. ANSI escapes are emitted only
to an interactive terminal and never written to the suite, Receiver, or Codex
event-log files. Setting `NO_COLOR` disables them.

## Failure behavior

- A Receiver, payload reconstruction, Tracealyzer, GDB, or Client error fails
  the loader phase and no agent review is offered.
- Declining Agentic review leaves all text files available for manual review.
- If Codex is absent, is not ChatGPT-authenticated, exits unsuccessfully, or
  omits/reorders a test result, the review fails without changing test data.
- Any per-test payload verdict of `FAIL` makes the Agentic review command fail.
- If the final Codex summary fails, deterministic PASS/FAIL statistics are
  still printed and logged with an explicit summary-unavailable message, and
  the review returns failure.
- The Agentic review is read-only and is explicitly forbidden from invoking
  the suite, loader, Receiver, Detect, or network operations.
