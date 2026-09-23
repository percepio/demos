# DFM test suite: start here

This is the entry point for running or handing off the Zephyr DFM test suite.
Run all commands from the repository root. The executable entry point is
`dfm_tests/run_suite.py`.

Before an automated agent does any work, it must read the repository-root
`AGENTS.md`. In particular, an agent may run the suite but must not run the
Detect loader, Receiver, REST verification, or any Detect cleanup/start/stop
operation without explicit user permission. Because a full successful suite
now invokes the loader automatically, an agent without that permission must
pass `--skip-payload-processing`.

## Prerequisites

- A working Zephyr workspace, SDK, and `west`. The runner discovers `west` on
  `PATH` or in the workspace-local Python environment.
- QEMU from the Zephyr SDK for QEMU runs.
- A board-compatible west flash runner for physical runs.
- pyserial for physical runs:

```powershell
python -m pip install -r dfm_tests/requirements.txt
```

Close VS Code Serial Monitor and every other terminal that has the target COM
port open. The Python runner requires exclusive access to it.

Check the complete current CLI at any time with:

```powershell
python dfm_tests/run_suite.py --help
```

## Run on QEMU

The shortest full QEMU invocation is:

```powershell
python dfm_tests/run_suite.py
```

This is equivalent to selecting `qemu_cortex_m3` and the project-root
`qemu_last_session.log`. The fully explicit form is:

```powershell
python dfm_tests/run_suite.py `
  --board qemu_cortex_m3 `
  --devicelog qemu_last_session.log
```

QEMU runs all compatible M3 variants by default. The hardware-only `m33_qual`
variant is excluded. `--devicelog` selects the raw accumulated QEMU output;
the selection remains fixed for the whole invocation.

Examples of focused runs:

```powershell
python dfm_tests/run_suite.py --variants m3_os
python dfm_tests/run_suite.py --testcase 1016
python dfm_tests/run_suite.py --variants m3_no_trace
python dfm_tests/run_suite.py --variants m3_retained
```

Pass `-y` (or `--yes`) to answer yes to every post-suite confirmation prompt.
For a focused, failed, or interrupted run this authorizes both the full Detect
load/text export and the subsequent Agentic payload review. It has no effect
when `--skip-payload-processing` is also selected.

A standalone `dfm_tests/log_watchdog.py` process checks the size of
`dfm_test_run.log` once per minute while the target suite is running. After 15
unchanged checks it signals the runner, which performs its normal child-process
cleanup and exits with status 124. The watcher stops before optional Detect
loading and Agentic payload review begin.

## Run on physical hardware

The recommended explicit form is:

```powershell
python dfm_tests/run_suite.py `
  --board b_u585i_iot02a `
  --com auto-detect `
  --runner openocd
```

Replace the board and runner with values supported by the connected hardware.
`--runner` may be omitted to use the board's default. For
`b_u585i_iot02a`, the default is `stm32cubeprogrammer`; use `openocd` when the
STM32CubeProgrammer CLI is not installed. Use `jlink` only with a J-Link probe
that is licensed for and physically connected to the selected target. A
Nordic-specific J-Link OB is not a general STM32 programmer.

A physical run with no `--variants` selection includes all compatible M3
variants plus the hardware-only `m33_qual` variant. Use `--variants` or
`--testcase` when the connected board cannot execute the complete set.

For non-QEMU boards, `--com auto-detect` is also the default when `--com` is
omitted. The `boards/b_u585i_iot02a.overlay` file sets that board's console to
460800 baud (4 x 115200), and the runner automatically opens it at the same
rate. Other physical boards default to 115200 baud unless both their overlay
and host mapping are updated. The runner builds the first image, opens
candidate ports in descending COM-number order, and flashes while each reader
is already active. It accepts a port only when `Percepio` appears within the
first 1024 bytes received within five seconds after flashing. If a complete pass fails,
it warns and repeats until interrupted or a port matches. The selected COM
port and its live reader are then locked for the complete suite. The successful
detection flash is also the first authoritative test run: its existing byte
stream continues without closing the port, clearing the log, or flashing the
image a second time.

Use an explicit port when known:

```powershell
python dfm_tests/run_suite.py `
  --board b_u585i_iot02a `
  --com COM17 `
  --runner openocd `
  --testcase 1022
```

Tests 1022 and 1023 belong to the hardware-only `m33_qual` variant. Their
implementation has been build-validated for `b_u585i_iot02a`, but their final
alert, coredump, and unwind evidence still requires a physical run and manual
review. Test 1022 does not require FP-register values in the coredump output:
this Zephyr release exports only core registers. It still requires a created
coredump, valid core-register decoding and unwind, intact target-side FP
context, and normal return. The variant uses a 2048-byte coredump buffer so
Test 1023's protected thread stack can be captured.

Tests 1025 and 1026 belong to the QEMU-compatible `m3_no_trace` variant. It
sets `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n` while keeping coredumps enabled;
1026 exercises a returning `DFM_TRAP`, and 1025 exercises the real fault path
and expected reboot.

Test 1027 belongs to `m3_retained`. It records timing events around a returning
trap, captures them with a second restarting trap, and sends the retained alert
from `main()` after reboot.

If flashing fails, first run the exact logged `west flash` command after the
suite has stopped. That isolates the flash runner from serial capture and
usually exposes the runner's native diagnostic. `west flash --context
--build-dir <build-directory>` lists the runners supported by that build.

## Output and result interpretation

Every invocation recreates `dfm_test_artifacts/`; archive evidence before
starting a different or focused run if it must be retained. The first selected
firmware build uses `--pristine=always`. Later builds in
the same invocation use `--pristine=auto`, allowing west to reuse a valid
build directory while still rebuilding automatically when required.

The important outputs are:

- `dfm_test_run.log`: commands, build output, target output, and orchestration
  results;
- `qemu_last_session.log` or the chosen `--devicelog`: raw QEMU target output
  for the whole invocation;
- `dfm_test_artifacts/<build-label>/zephyr.elf` and `zephyr.config`: the exact
  image and configuration;
- `dfm_test_artifacts/<build-label>/syscalls-v*.xml`: the matching Tracealyzer
  syscall extension required to export TraceRecorder logs;
- `dfm_test_artifacts/<build-label>/qemu.log` or `serial.log`: raw output from
  that image only;
- `dfm_test_artifacts/<build-label>/alert-metadata-*.txt`, `eventlog-*.txt`, and
  `coredump-*.txt`: per-alert metadata and text-mode payload evidence keyed by
  test and unique Session ID;
- `dfm_test_artifacts/<build-label>/diagnostic_review.md`: optional Codex
  second-opinion verdicts for that build;
- `dfm_test_artifacts/diagnostic_review.md`: aggregate bullet-list overview and
  detailed evidence, summarized by one final Codex run whose exact PASS/FAIL
  statistics are also appended to `dfm_test_run.log`.

The runner prints `TEST PASS` or `TEST FAIL` for every selected case and one
final `SUITE PASS` or `SUITE FAIL`. A successful build or `Process cleanup
verified` is not a suite verdict. The process exit code is zero only when the
automated suite checks pass. Payload content, coredump unwinding, and trace
semantics still require the manual oracle in `dfm_test_cases.md`.

## Documentation map

- `running_on_real_board.md`: detailed serial discovery and hardware behavior.
- `dfm_test_cases.md`: authoritative per-test specification and manual oracle.
- `dfm_trap_cortex_m_test_plan.md`: variants, execution, and evidence plan.
- `dfm_trap_test_harness_design.md`: target/host implementation design.
- `automated_payload_review.md`: synchronous text exports, completion status,
  ChatGPT-authenticated Codex review, and failure behavior.
- `dfm_payload_review_agent.md`: compact allowlisted evidence protocol used by
  each per-test Codex review process.
- `host_device_log_architecture.md`: high-level serial/QEMU changes and notes
  for porting the same approach to the FreeRTOS sister project.
- `test-reports/dfm_test_review_instructions.md`: entry point for a later
  payload-review session. The report overview is maintained by the user and
  must not be edited by an automated agent.
