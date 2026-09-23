# DFM_TRAP Test Harness Design

This document contains implementation details for the target-side sequential
runner and the portable host script. The shorter
[test plan](dfm_trap_cortex_m_test_plan.md) defines the verification process,
and [DFM test cases](dfm_test_cases.md) is the authoritative case catalog.

## 1. Project Integration

Keep all test-specific files under `dfm_tests/`. The public target-side entry
point is:

```c
int run_tests(void);
```

Keep the application-mode switch visible near the beginning of `main.c`:

```c
#define RUN_TESTS_ONLY 1
```

Use `#if RUN_TESTS_ONLY`, not `#if defined(RUN_TESTS_ONLY)`, so setting the
value to zero selects `demo_app()`.

The local macro is visible only in `main.c`. Version 1 may therefore link demo
and test sources while calling only one entry point. Test `SYS_INIT` hooks must
remain inert unless valid persistent state explicitly arms their test. If
source exclusion later matters, replace the local macro with one shared value
used by both CMake and C; do not create two independent switches.

## 2. Target-Side Registry

Each firmware variant contains a fixed registry of compatible cases.
`run_tests()` runs them in order without recompilation or manual resets.

Each registry entry contains:

- stable test ID;
- fixture function or startup-hook type;
- expected control-flow outcome: return, DFM reboot, startup reboot, or
  fault-handler reboot;
- cleanup required before the next test.

The test ID does not change if the registry order changes. The runner emits:

```text
DFMT:SUITE_BEGIN:<variant>:<run-id>
DFMT:BEGIN:<test-id>:<sequence-index>
DFMT:RETURNED:<test-id>
DFMT:REBOOT_EXPECTED:<test-id>
DFMT:RESUMED:<test-id>:<next-test-id>
DFMT:SUITE_COMPLETE:<variant>:<run-id>
```

These markers prove runner control flow only. They are not verdicts for alert,
coredump, unwind, or trace content.

## 3. Persistent Progress State

Use a dedicated `.noinit` structure instead of an unchecked counter. It
contains at least:

- magic and state-format version;
- firmware-variant cookie;
- run ID;
- next registry index;
- armed test ID;
- execution phase;
- reboot count; and
- checksum, complement, or equivalent consistency field.

Accept the state only if its identity, range, variant cookie, and consistency
checks pass. Otherwise initialize a new run at index zero. The consistency
field is written last so an interrupted update cannot authorize skipping a
test.

Use simple fixed-width stores while interrupts are briefly locked. Pre-kernel
code must not require mutexes, heap allocation, timers, or initialized logging
services.

The important transitions are:

- On a normal case, keep the current index while the fixture runs. Advance only
  after local observations and cleanup are complete.
- Before Test 1008 calls `DFM_TRAP(..., 1)`, store the following index and phase
  `EXPECT_DFM_REBOOT`. The next boot reports the resume and starts Test 1009.
- If Test 1008 unexpectedly returns, record the control-flow failure and continue
  instead of entering a loop.
- Before Test 1025 executes its undefined instruction, store the following
  index and phase `EXPECT_FAULT_REBOOT`. The fatal handler records the Zephyr
  reason without converting this expected fault into an unexpected-fatal
  failure. The next boot checks `K_ERR_ARM_USAGE_UNDEFINED_INSTRUCTION`,
  reports the resume, and completes the variant.
- At the end, store `COMPLETE`. A later reboot reports completion and stays
  idle instead of repeating the suite.

Each host-script variant run starts a fresh QEMU process and therefore a fresh
RAM image. No command-line state-reset mechanism is needed. A variant cookie
prevents state retained across an in-process cold reboot from being
accepted by another firmware image.

For a physical board, the host script compiles one random run cookie into all
images built by that invocation. The variant ID still separates images within
the invocation, while the run cookie prevents a repeated flash of the same
variant from accepting valid `.noinit` state left by an earlier invocation.

The demo already relies on a `.noinit` counter. Even so, retention must be
verified over the exact `sys_reboot(SYS_REBOOT_COLD)` path used by DFM before
the test harness is trusted. Retention across stopping and restarting the QEMU
host process is not required.

## 4. Startup Tests

Test 1005 and Test 1010 must execute through `SYS_INIT`, not as ordinary calls.

For either test, the runtime runner:

1. stores its ID and phase `ARMED_STARTUP_TEST`;
2. leaves the registry index on that test;
3. requests a controlled cold reboot; and
4. waits until the next boot has recorded the hook result before advancing.

Each hook validates the raw persistent state and does nothing unless its own ID
is armed. It records startup-safe observations and completion. `run_tests()`
interprets and logs the result after `main()` starts.

Test 1010 runs at `PRE_KERNEL_1` and cannot assume timers or logging are initialized.
Test 1005 runs at `APPLICATION` priority 1, after the DFM initialization at priority
0. The harness must not initialize DFM a second time. Test 1010 is the final `m3_os`
case so a future regression in pre-initialization handling cannot prevent the
ordinary `-Os` cases from running.

## 5. Isolation and Recovery

- Test 1017 leaves tracing stopped for its oracle. Harness cleanup may restart it
  only after the observation is recorded.
- Tests 1006 and 1016 emit normal-PSP witness alerts only after returning from
  their alert-only ISR/MSP calls; Test 1016 restores PSP first.
- Test 1021 releases its outer scheduler lock and records the high-priority
  thread result before its witness alert.
- Tests 1019 and 1020 record return from their first call in TraceRecorder,
  then complete a short witness trap before advancing.
- Test 1026 proves that a running recorder remains enabled around a no-trace
  `DFM_TRAP`; Test 1025 then proves the no-trace fault path and expected fatal
  reboot in the same build.
- An unexpected fatal handler records test and phase before reboot. The runner
  may continue, but it must preserve the failure evidence.
- A hang cannot update progress safely. The host times out, records a failed
  run, and continues with the next selected firmware variant. Test 1010 remains
  last in its image as protection against a regression in its early-return path.

An optional delay between returning runtime cases may let output drain. It is
not used by pre-kernel hooks and is not part of a product oracle.

## 6. Portable Host Script

`dfm_tests/run_suite.py` is intended for an ordinary Windows, Linux, or macOS
terminal. Physical-board mode additionally uses pyserial, pinned in
`dfm_tests/requirements.txt`; QEMU mode has no non-standard Python dependency.
A Zephyr workspace, toolchain, and `west` remain prerequisites; QEMU or a
board-compatible flash runner is needed for the selected execution mode. The
script finds `west` on `PATH` or invokes it through a workspace-local Python
environment without requiring manual environment activation.

### Loading saved alerts into Detect

> **Permission boundary:** `load-zephyr-alerts.bat` deliberately deletes the
> existing Detect database and alert files. An automated agent must not invoke
> the loader, Receiver, or Detect REST verification without explicit user
> permission. Since a full successful `run_suite.py` invocation now enters the
> loader automatically, an agent that lacks that permission must pass
> `--skip-payload-processing`.

Run the project-root `load-zephyr-alerts.bat`, or use the VS Code
`Detect: Load alerts` task, after the suite has created the stable per-image
artifacts. With no arguments, the script identifies the latest suite type from
the artifact tree and invokes the Receiver once for every
`dfm_test_artifacts\Build-*\qemu.log` or every
`dfm_test_artifacts\Build-*\serial.log`, in sorted directory order. A tree that
contains both types is rejected as ambiguous. If neither type exists, the
standalone-QEMU `qemu_last_session.log` is used as a compatibility fallback.
The same log also takes precedence when its timestamp is newer than every file
below `dfm_test_artifacts`, which identifies a manual F5 run performed after
the latest suite.

The suite invokes the same full loader with `--suite-artifacts`, which disables
the manual-F5 timestamp preference and guarantees that only the artifact tree
recreated by that suite invocation is used. In `DETECT_CLIENT_TEXT_OUTPUT=1`
mode the Client processes every payload synchronously and returns only after
the text artifacts are complete. The loader then clears the text-mode flag for
a second Client process and starts it in normal interactive mode, retaining the
same alert directory and revision-based ELF mapping for dashboard review. See
`automated_payload_review.md` for the status and optional Codex-review protocol.

The script validates all paths before changing external state and calls
`percepio-server.bat cleanup` with confirmation supplied through stdin. It
verifies that the Detect containers and database volume were removed, stops the
Client once, deletes the old project-local alert files, and processes all
selected logs. Finally, it starts the Detect server and Client once and verifies
that all server containers are running. `--serial-log` can still select one
explicit hardware log, while `--dry-run` reports the automatic selection
without changing Detect state.

`--receiver-only` skips all Docker, server, database, and Client handling. It
only clears the project-local `alert-files` directory and invokes the Receiver
for the selected logs. This is useful for isolating Receiver parsing problems;
combine it with `--dry-run` to verify selection without changing any files.

Suite logs keep the Revision-based Client path
`dfm_test_artifacts/${revision}/zephyr.elf`. A selected manual F5 log instead
uses the static `build/zephyr/zephyr.elf` produced immediately before QEMU was
started. The F5 build includes `.vscode/f5-debug.conf`, giving it Revision
`Manual-QEMU`, but no Revision substitution is needed for this single-image
log. Thus manual debugging neither overwrites nor adds files to the current
suite artifact tree.

Receiver failures do not prevent later logs from being attempted, and the
script still attempts to restart Detect before reporting failure. It does not
copy a single ELF: each alert's Revision metadata resolves the matching ELF
below `dfm_test_artifacts`.

The script is reviewed test-harness code. Keep it intentionally straightforward,
well commented, and understandable without a test framework. Prefer explicit
variant definitions and commands over clever abstractions.

Each command invocation must own its complete descendant process tree. After
success, failure, timeout, or interruption, every `west`, CMake, Ninja, shell,
and QEMU process started by that invocation must be terminated. Cleanup is
verified before the next variant starts. If the harness cannot guarantee this,
the variant and suite fail.

On Windows, the script assigns a handshake-blocked launcher to a Job Object
configured with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` before it is allowed to
start `west`. Closing the job therefore covers every descendant, including an
orphaned shell or QEMU process. On Linux and macOS, the command starts in a
dedicated process session and process group; cleanup sends `SIGTERM`, then
`SIGKILL` if required. On all platforms, QEMU's freshly generated PID file is
an independent verification and fallback path.

Running the script without arguments processes all variants on
`qemu_cortex_m3`. `--variants` selects a focused rerun, for example:

```text
python dfm_tests/run_suite.py --variants m3_os
```

The focused stack-boundary rerun is:

```text
python dfm_tests/run_suite.py --variants m3_stack128
```

`--testcase` instead builds a one-entry target registry and automatically
selects the owning variant, for example:

```text
python dfm_tests/run_suite.py --testcase 1016
```

`--testcase` and `--variants` are mutually exclusive. Reboot and resume state
therefore follows the same target-side path for a singleton as for a complete
variant.

For a physical board, `--board` selects the Zephyr board target, `--com`
selects a port or `auto-detect`, and optional `--runner` overrides the board's
default west flash runner. For a board name containing `qemu`, `--devicelog`
selects the accumulated QEMU device log and defaults to
`qemu_last_session.log`. `--com` and `--devicelog` are mutually exclusive, and
the resolved source remains fixed for the whole suite. See
`running_on_real_board.md`. Build root, log names, and timeouts remain readable
constants near the beginning of the script. The build root is
`build/dfm_tests/`. The visible project-root file `dfm_test_run.log` records
harness steps, build output, target output, and results.

After command-line validation at the start of every test run, the harness
deletes and recreates the fixed `dfm_test_artifacts/` directory. It then keeps
each firmware build that succeeds in that run separate from the others.
Consequently, no unselected
variant, failed build, or extra file from an earlier run can survive. Each
build-configuration subdirectory contains the exact `zephyr.elf`, its
`zephyr.config`, and either `qemu.log` or `serial.log` containing only target
output produced by that image. The names contain no spaces and identify the
firmware configuration, for example `Build-M3-O0`. This is clearer than a
test-ID range because all tests in one directory use the same image. Stable
paths are intentional so Detect and review scripts do not need path updates
after every run.

Each image sets DFM's firmware-version metadata, displayed by the Client as
`Revision`, to its build label only. For example, the `m3_o0` alerts carry
`Build-M3-O0`. The Client setting
`../../demos/ZephyrDemo/dfm_test_artifacts/${revision}/zephyr.elf` then
selects the exact ELF. Build labels are limited to 18 characters and the host
script rejects a longer value before building. This leaves margin within the
current downstream 20-character Revision limit; target-side DFM itself is
configured for a maximum firmware-version length of 64. The host script
verifies the exact Revision in the generated `.config` before copying or
running an image.

For every selected variant the script:

1. builds with the matching overlay and `DFM_TEST_VARIANT`, using
   `--pristine=always` for the first selected variant and
   `--pristine=auto` for every following variant;
2. logs the command plus exact `.config` and ELF paths;
3. starts the configured west run target;
4. streams every output line to the console and `dfm_test_run.log`;
5. appends raw QEMU output to `qemu_last_session.log`;
6. copies the exact ELF and configuration into the matching build-configuration
   directory, clears that directory's `qemu.log`, and writes only this image's
   output there;
7. waits for `DFMT:SUITE_COMPLETE:<variant>`;
8. terminates the complete owned process tree on completion, total timeout,
   interruption, or a fixed period without output;
9. reads QEMU's freshly generated `qemu.pid`, stops that PID independently of
   the owned process tree, and verifies that both the launcher and QEMU are
   gone; and
10. reconstructs every Serial DFM block, verifies each nonzero transport
    CRC-16/CCITT, and fails on a mismatch or damaged block framing; checksum
    zero explicitly means that verification is unavailable for that block;
11. decodes every serialized DFM alert header and fails the run if a complete
    description exceeds Detect's 100-character storage limit; and
12. records the result before continuing.

In physical-board mode, the host auto-detects a COM port once (or uses the
explicit `--com` value), opens the locked port before each `west flash`, and
streams bytes directly with pyserial. Auto-detection tries ports in descending
COM-number order after the first image has been built. It opens and starts a
reader on each candidate before flashing that image, gives the port at most
five seconds after flashing, and requires `Percepio` in the first 1024 bytes.
This bootstrap flash makes discovery independent of the firmware previously
on the board. After every unsuccessful pass it warns and restarts from the
highest COM number. After selection, the successful bootstrap flash becomes
the authoritative first run. Its reader remains open and the same byte stream
continues through the matching completion marker into the image's
`serial.log`; there is no intervening second flash. Later variants use the
locked port and one flash per image.

At the start of one suite-script invocation, `dfm_test_run.log` is cleared. A
QEMU invocation also clears the selected `--devicelog` once, then appends every
selected variant's raw device output in execution order without harness
prefixes. This is the primary QEMU log for DFM output review and Detect replay.
Physical target bytes are mirrored to the console and `dfm_test_run.log` and
retained exactly in each image's `serial.log`.

The complete artifact root is reset at the beginning of an invocation. After a
successful build, `zephyr.elf` and `zephyr.config` populate that test group's
directory and its target log starts empty. A failed build leaves no artifact
directory for that variant in the current invocation.

Script status lines in `dfm_test_run.log` are plain text. The terminal renders
successful build/run steps as green `PASS` and failures as red `FAIL`. It also
emits one `TEST PASS` or `TEST FAIL` result for every selected test and one
final `SUITE PASS` or `SUITE FAIL` result for the complete invocation.

The host script orchestrates firmware variants. Individual test progress stays
on the target so a DFM-triggered reset cannot race with host bookkeeping. A
missing completion marker, timeout, build failure, run failure, incomplete
process cleanup, `DFMT:HARNESS_FAIL`, or failed `DFMT:CHECK` makes the script
return non-zero. The same applies when the decoded serialized DFM alert types
or multiplicities differ from the selected cases' expectations, including a
missing header or an unexpected alert in zero-alert Test 1010. The script still
attempts later selected variants, so one failure does not discard unrelated
evidence. Payload-content product verdicts remain manual; the optional Agentic
review is explicitly a second opinion.

The ordinary coredump variants resolve
`CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=-1`. The `m3_stack128` variant is
the sole deliberate 128-byte override and archives its matching ELF under
`dfm_test_artifacts/Build-M3-Stack128/`. The `m3_no_trace` variant explicitly
sets `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n` and archives its coredump-only
alerts under `dfm_test_artifacts/Build-M3-NoTrace/`. The `m3_retained` variant
reserves a separate 9,392-byte devicetree retention region with a four-byte
prefix and SUM32 checksum, keeps the harness state in ordinary
`.noinit`, and archives the post-reboot alert under
`dfm_test_artifacts/Build-M3-Retained/`. The `m3_retained_8k` variant uses the
same DFM settings with an intentionally small 8 KiB region and archives its
single positive-control alert under `dfm_test_artifacts/Build-M3-Ret8K/`.
