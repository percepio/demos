# DFM_TRAP on Arm Cortex-M: Test Plan

This plan covers execution and manual review. The authoritative descriptions
and oracles are in [DFM test cases](dfm_test_cases.md), and the selected test
dimensions are in the [test space](dfm_trap_cortex_m_test_space.md). Product
white-box details are in the
[white-box appendix](dfm_trap_cortex_m_white_box_appendix.md). Target-runner
and host-script details are in the
[test harness design](dfm_trap_test_harness_design.md).

## 1. Objective and Scope

Version 1 verifies `DFM_TRAP()` end to end:

```text
test fixture -> target/QEMU -> Detect Receiver -> Detect dashboard/client
             -> manual coredump and trace review -> recorded verdict
```

It includes:

- 22 GCC tests on `qemu_cortex_m3`;
- whole-image `-O0` and `-Os`, plus one `-Og` comparison;
- two separately reported Armv8-M tests in a hardware-only M33 variant;
- sequential execution of compatible cases without rebuilding between them;
- automatic continuation after expected cold reboots by using `.noinit` state;
  and
- one portable host script that builds and runs all required variants.

The product verdict remains manual. The current harness also performs
synchronous Receiver/Client text export after the suite and can start an
opt-in, ChatGPT-authenticated Codex review as an independent second opinion;
see `automated_payload_review.md`.

## 2. Test Identity and Target Markers

Use the numeric alert type as the official test ID. Reserve types 1001 and
above for this suite so they do not collide with product alert types in
`dfmCodes.h`. The supplied message contains only the test ID; the manual-review
oracle remains in `dfm_test_cases.md`, and detailed runtime evidence is logged
as short `DFM Tests` events. A message must not claim that its own
`DFM_TRAP()` returned, because payload capture occurs before return:

```text
Test <test-id>
```

Examples:

```c
DFM_TRAP(1001, "Test 1001", 0);
DFM_TRAP(1006, "Test 1006A", 0);
DFM_TRAP(1008, "Test 1008", 1);
```

The DFM Trap viewer does not issue a backtrace command automatically. The
reviewer runs `info registers` and `bt full` where specified.

Every ordinary runtime case logs `T<test-id> BEGIN` on the TraceRecorder
`DFM Tests` channel. Selected fixtures add short events labelled `PATH`,
`ARGS`/`DATA`, `CTX`, `RETURN`, or `POST`. This vocabulary and short lines make
the event list scannable without opening source code. Trace logging is kept
outside register-capture leaves where it would perturb caller-saved register
oracles. Review every `DFM Tests` row for the current test, including complete
formatted values, multiplicity, and order; do not inspect only `[ALERT]`.

Tests 1006, 1007, 1016, 1019, 1020, and 1021 use two alerts, suffixed `A`/`B`
in their descriptions where useful but sharing one numeric alert type. An
event written after the first trap returns is included in the second alert's
trace payload. This makes return and later postconditions reviewable from DFM
payloads without multiplying the logical test count. Do not add a witness
alert where a target marker is sufficient and payload-level proof adds little.

`CONFIG_PERCEPIO_DFM_CFG_DESCRIPTION_MAX_LEN=96` is used. DFM rounds this to a
104-byte internal field for termination and alignment; that remains below the
255-byte serialized-size limit and fits the checked entry buffer. `DFM_TRAP`
formats the message plus appended filename and line into
`cDfmPrintBuffer[128]`. Test descriptions, including the appended callsite,
must contain fewer than 50 characters so both metadata and `[ALERT]` remain
complete. Detect currently persists `alert_description` in a 100-character
database field, and the host harness retains its independent absolute-limit
check. Test 1019 verifies suffixed short identities and recovery across two
alerts.

The runner emits concise control-flow markers:

```text
DFMT:SUITE_BEGIN:<variant>:<run-id>
DFMT:BEGIN:<test-id>:<sequence-index>
DFMT:RETURNED:<test-id>
DFMT:REBOOT_EXPECTED:<test-id>
DFMT:RESUMED:<test-id>:<next-test-id>
DFMT:SUITE_COMPLETE:<variant>:<run-id>
```

These markers prove sequence progress only. They are not product verdicts.

## 3. Demo Integration and Sequential Runner

Place the test suite under `dfm_tests/` and expose:

```c
int run_tests(void);
```

Keep the mode switch visible near the beginning of `main.c`:

```c
#define RUN_TESTS_ONLY 1
```

Use `#if RUN_TESTS_ONLY` to call `run_tests()` when the value is one and
`demo_app()` when it is zero. The CMake build includes the complete registry
for a firmware variant; it never selects an individual test ID.

`run_tests()` executes the fixed registry in order. It keeps validated progress
in a dedicated `.noinit` structure containing state-format and variant identity,
the next index, armed test, phase, reboot count, and a consistency check.
Invalid or stale state starts at index zero.

Before Test 1008 calls `DFM_TRAP(..., 1)`, the runner commits Test 1009 as the next case.
After DFM performs the cold reboot, the suite reports the resume and continues
at Test 1009 without repeating Test 1008.

Test 1005 and Test 1010 require one-shot `SYS_INIT` hooks. The runner arms the selected
hook in `.noinit` and performs a controlled reboot. The hook runs at its real
startup phase, records startup-safe observations, and remains inert on all
other boots. `run_tests()` interprets the result after `main()` starts and then
continues the registry.

Mark state `COMPLETE` after the final case so another reboot does not start the
suite again. Starting a new run must explicitly reset the harness state. First
verify `.noinit` retention over the actual QEMU cold-reboot path; do not infer
it only from linker placement.

Detailed state transitions, startup restrictions, cleanup, and failure
recovery are specified in the harness design.

## 4. Required Firmware Variants

Optimization and DFM Kconfig choices cannot change at runtime. Build seven M3
images for QEMU. A complete compatible physical-board run also builds one M33
qualification image.

The general coredump images use
`CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=-1`; stack capture begins at the
live stack pointer but is not truncated at an arbitrary byte count. Only the
dedicated Test 1024 image restores the 128-byte limit.

### 4.1 `m3_o0`

Configuration: whole-image `-O0`.

Sequence: Test 1001, Test 1003, Test 1012.

### 4.2 `m3_og`

Configuration: whole-image `-Og`.

Sequence: Test 1013.

This targeted image exists only for the direct
Test 1001/Test 1013/Test 1014 compiler comparison.

### 4.3 `m3_os`

Configuration: whole-image `-Os`.

Sequence: Test 1002, Test 1004, Test 1005, Test 1006, Test 1007, Test 1008,
Test 1009, Test 1011, Test 1014, Test 1016, Test 1017, Test 1018, Test 1019,
Test 1021, Test 1010.

Test 1005 and Test 1010 use harness-requested startup reboots. Test 1008 uses the
DFM-requested reboot. The other cases continue in the same boot after cleanup.
Test 1010 is intentionally last because it runs before DFM initialization; a
future regression in its early-return behavior must not hide the evidence from
the other `-Os` cases.

### 4.4 `m3_no_coredump`

Configuration: `-Os` and
`CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS=n`, with trace capture independently
enabled by `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=y`.

Sequence: Test 1015.

### 4.5 `m3_small_coredump`

Configuration: `-Os` and an intentionally undersized
`CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE`.

Sequence: Test 1020.

### 4.6 `m3_stack128`

Configuration: whole-image `-O0` and a deliberate
`CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=128`.

Sequence: Test 1024, using the same reference chain as Test 1001.

### 4.7 `m3_no_trace`

Configuration: `-Os`, coredumps enabled, and
`CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n`.

Sequence: Test 1026 exercises a returning `DFM_TRAP`; Test 1025 then executes
an undefined instruction, exercises the real Zephyr fault path, and resumes
the harness after the expected fatal reboot. Both alerts require a coredump
and forbid a TraceRecorder payload.

### 4.8 `m33_qual`

Configuration: Armv8-M Mainline with FPU support, FPU context sharing,
hardware stack protection, and
`CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE=2048`. The tested reference board
configuration is `b_u585i_iot02a`.

Sequence: Test 1022, Test 1023.

Test 1022 qualifies coredump creation, core-register decoding, unwind, and
normal return while an FP context is active. Zephyr's coredump format in this
release does not export `s0`–`s31` or `FPSCR`, so those registers are not part
of the test oracle. Test 1023 uses the larger buffer because its live stack
interval and thread metadata do not fit in the default 1000-byte buffer.

This variant is hardware-only. It is included by default for physical-board
runs and excluded by default for QEMU. Selecting it explicitly with a QEMU
board is rejected before any build starts.

The M3 scope is seven builds for 24 tests and the M33 qualification is one build
for two tests, not one build per test. Preserve each build and exact ELF so it
can be rerun without recompilation.

## 5. Portable Host Script

Use `dfm_tests/run_suite.py` as the single host entry point. It can be launched
from an ordinary Windows, Linux, or macOS terminal. Physical-board mode uses
the pyserial dependency in `dfm_tests/requirements.txt`; QEMU mode uses only
the Python standard library. No virtual environment must be activated
manually. A valid Zephyr workspace, toolchain, and `west` are still
prerequisites; QEMU or a board-compatible flash runner is needed for the
selected execution mode.

The script builds each selected variant, logs the exact build and ELF paths,
runs QEMU, streams its output, waits for the matching `SUITE_COMPLETE` marker,
applies fixed total and no-output safety timeouts, and moves to the next
variant. Running it without arguments executes everything on
`qemu_cortex_m3`. `--variants` selects a focused variant rerun. `--testcase`
builds a singleton target registry and automatically selects the case's owning
variant; the two selection options are mutually exclusive. Physical-board
mode uses `--board`, `--com` (default `auto-detect`), and optional `--runner`.
QEMU boards use `--devicelog`, defaulting to `qemu_last_session.log`.
`--com` and `--devicelog` are mutually exclusive; see
`running_on_real_board.md`.

The script is reviewed harness code. It must remain straightforward, readable,
and well commented. Every step, resolved command, child-process output line,
marker, timeout, and result is written to persistent plain-text logs as well as
the console. Successful build/run steps use green `PASS`; failures use red
`FAIL`. Every selected test also receives an explicit `TEST PASS` or
`TEST FAIL`, followed by one final `SUITE PASS` or `SUITE FAIL`. When color is
unavailable, the literal labels remain visible.

Every command run owns its full descendant process tree. The harness must stop
all `west`, CMake, Ninja, shell, and QEMU processes that it started after a
successful run, failure, timeout, or interruption, then verify cleanup before
continuing. Inability to guarantee cleanup is a test failure. Windows uses a
kill-on-close Job Object; Linux and macOS use a dedicated process group with
`SIGTERM`/`SIGKILL`. A fresh QEMU PID file provides an independent check on all
platforms.

The fixed build root is `build/dfm_tests/`. Harness steps, build output, and
results are written to the visible project-root file `dfm_test_run.log`. Raw
QEMU output from every selected variant is written to the central
`qemu_last_session.log` file. Both files are cleared once at the start of a
suite-script invocation. Each QEMU run then appends to the same QEMU log, so
DFM output from all builds in that invocation remains available together. The
normal demo mode is unchanged: each demo QEMU invocation overwrites
`qemu_last_session.log` as before.

After command-line validation, the complete `dfm_test_artifacts/` tree is
deleted and recreated at the start of every test run. Every build that succeeds
in that run is then saved under a stable build-configuration path, such as
`dfm_test_artifacts/Build-M3-O0/`. The directory contains the exact
`zephyr.elf`, `zephyr.config`, and an image-specific `qemu.log`. That QEMU log
is cleared before the new image runs and therefore cannot contain alerts from
an earlier build. Stable, non-timestamped paths let Detect select the correct
ELF without configuration changes between suite runs. Unselected variants,
failed builds, and extra files from an earlier invocation are absent.

DFM's firmware-version metadata, shown as `Revision` in the Client, contains
only the matching build label, for example `Build-M3-O0`. The configured Client
path `../../demos/ZephyrDemo/dfm_test_artifacts/${revision}/zephyr.elf`
therefore resolves the exact ELF for the alert. Build labels describe firmware
images rather than test ranges because every test in one directory uses the
same image. They have no spaces and are limited to 18 characters. This stays
within the current downstream 20-character Revision limit with margin, even
though target-side DFM is configured for a maximum firmware-version length of
64. Every build must verify its exact Revision in the generated `.config`
before QEMU starts.

The host script changes firmware variants only. Individual test progress stays
on the target so DFM-triggered reboot handling does not race with the host.
Missing completion, timeout, build error, run error, `DFMT:HARNESS_FAIL`, or a
failed `DFMT:CHECK` gives a non-zero script exit. So does any mismatch between
the expected and decoded serialized DFM alert types or counts; a missing or
damaged header therefore cannot pass as absent metadata. A failed build or run
is recorded, but does not prevent the script from attempting the remaining
selected variants. Coredump, unwind, and trace-content product verdicts remain
manual.

## 6. Preconditions

Before the full run, record or verify:

- Git revision and local modifications;
- Zephyr, SDK, GCC, GDB, Receiver, and Client versions;
- complete `.config`, compiler flags, board, variant cookie, and exact ELF for
  every variant;
- firmware/build-ID-to-ELF mapping;
- Receiver readiness and result storage;
- per-variant timeout and QEMU termination behavior;
- `.noinit` retention and state validation over cold reboot.

## 7. Version 1 Execution and Review

1. Start the Detect Receiver and verify readiness.
2. Invoke `run_suite.py` once for all compatible variants (seven M3 variants in
   QEMU mode, or the selected physical-board variants).
3. Let each image finish its complete target-side sequence and expected
   reboots.
4. Check that target markers are complete and ordered.
5. Locate every expected alert by numeric alert type and its exact short
   `Test <test-id>` or `Test <test-id><suffix>` message. Test 1025 instead
   uses DFM's Zephyr-generated description for architecture reason code 36.
6. Verify alert type, description, build identity, and payload names.
7. Open expected `trap.zpr` and `fault.zpr` payloads with the exact ELF.
8. Inspect the specified GDB frames, callsite, registers, arguments, and
   locals by running `info registers` and `bt full`; these are not shown by
   default for DFM Trap dumps.
9. Inventory every `[DFM Tests]` row in each event log and verify all
   current-test rows, values, multiplicity, and order against source and oracle.
10. Save the raw logs/payloads and useful exported text or screenshots.
11. Record `PASS`, `FAIL`, or `BLOCKED` for every logical test.

The runner does not hold the board or QEMU process open for manual verdicts.
After target execution it loads and exports the saved alerts, then asks whether
to start Agentic review. Tests 1006, 1007, 1016, 1019, 1020, and 1021 produce
two alerts within
one logical test. Test 1010 expects no alert. The first alert in Tests 1006 and
1016 is alert-only; both Test 1020 alerts omit `trap.zpr`. Test 1015 includes
`dfm_trace.psfs` but omits `trap.zpr`. The witness alerts for Tests 1006 and
1016 run on normal PSP and therefore include `trap.zpr`. Tests 1025 and 1026
run with `ADD_TRACE=n`; they require `fault.zpr` and `trap.zpr` respectively
and forbid `dfm_trace.psfs`.

## 8. Evidence and Verdicts

The script produces a central replayable QEMU/DFM log, a complete harness log,
and leaves the exact build artifacts in fixed directories:

```text
qemu_last_session.log
dfm_test_run.log
build/dfm_tests/<variant>/zephyr/zephyr.elf
build/dfm_tests/<variant>/zephyr/.config
```

Use `qemu_last_session.log` as the primary source when assessing DFM output or
replaying serial hex records into Detect. It contains raw QEMU output without
harness prefixes and appends all selected variant runs in execution order.
Use `dfm_test_run.log` to audit commands, builds, markers, timeouts, and harness
results. Starting a new suite invocation clears both logs once. Running QEMU in
normal demo mode retains the existing overwrite behavior for
`qemu_last_session.log`.

The reviewer chooses the long-term result archive. It should group each
test's verdict, alert metadata, payloads, exported GDB/trace text, and useful
screenshots with a copy or hash of the matching ELF and `.config`.

Each verdict records build/run identity, sequence index, observed control flow,
alert and payloads, GDB/trace observations, reviewer/date, defects, and notes.

- `PASS`: every required result in the test specification is observed.
- `FAIL`: behavior contradicts a requirement.
- `BLOCKED`: tooling, timeout, or correlation prevents a verdict.

Advancing to the next case proves only harness progress. Optimized-away values
are accepted only where the test specification permits them. Reproduce failures
once before triage unless repetition risks the target or data.

## 9. Future Automated Regression Testing

A later Receiver flow may detect the reserved numeric alert types and short
`Test <test-id>` descriptions, wait for complete payloads, resolve
the exact ELF, and ask a non-interactive Client to export structured coredump
and trace results. Deterministic checks can then compare frames, markers,
payloads, and state. Codex can summarize differences and help triage them.

This can be reliable only with exact ELF correlation, complete-payload
detection, versioned structured output, deterministic oracles, and timeouts.
Codex should remain a secondary reviewer; humans should review failures,
ambiguities, and a sample of passes. Receiver/Client API feasibility remains
unverified in this workspace.

## 10. Completion Criteria and Open Decisions

The M3 suite is ready when all seven variants build, startup hooks are inert
unless armed, reboot continuation passes its smoke test, Test 1001 reaches
Detect, and its coredump opens with the exact ELF and unwinds through
`dfm_t01_test_thread`.

The M3/GCC scope is complete when all 24 tests have evidence and a verdict, no
case remains `BLOCKED`, failures have triage decisions, and human review is
recorded. Test 1022 and Test 1023 are reported separately.

Before formal qualification is complete, decide:

1. permanent result storage and retention;
2. the firmware/build-ID-to-ELF archival convention.

`b_u585i_iot02a` is the current reference target for Test 1022 and Test 1023.
Another compatible Armv8-M Mainline board may be used if it provides the same
FPU-sharing and hardware-stack-protection capabilities.
