# FreeRTOS DFM/TraceRecorder test suite

This suite is the FreeRTOS/QEMU port of the sibling `ZephyrDemo/dfm_tests`
suite. The host protocol, test IDs, build labels, COM-port reader, Detect
pipeline, and review workflow intentionally remain as close to the Zephyr
implementation as the platform permits.

## Current scope

QEMU `mps2-an385`/Cortex-M3 and physical B-U585I-IOT02A/STM32U585 targets are
supported. QEMU runs tests 1001–1021, 1024, and the FreeRTOS-specific real
HardFault test 1025. Physical runs execute those portable profiles plus the
hardware-only Cortex-M33 qualification tests 1022 and 1023.

The port uses:

- FreeRTOS with the GCC ARM_CM3 or ARM_CM33_NTZ port;
- DFM from `../ZephyrDemo/modules-staging/modules/debug/percepio/DFM`;
- CrashCatcher from `../PercepioLibs/CrashCatcher`;
- TraceRecorder 4.11.0 (`Tz4/4.11/v4.11.0`, commit
  `2f888cb9e6240c88e33eacd5acd50555fb13fbf5`) with only the FreeRTOS kernel
  port and RingBuffer stream port.

`DFM_TRAP()` exports CrashCatcher data as `trap.dmp`. A processor fault handled
by `DFM_Fault_Handler` exports `fault.dmp`. The suite explicitly exercises
traps from pre-scheduler `main()` on MSP, an external interrupt on MSP, a
FreeRTOS task on PSP, a temporary Thread/MSP stack, a timer-daemon callback,
and a deliberate HardFault.

## Run

Install the host requirements once if pyserial is not already available:

```powershell
python -m pip install -r dfm_tests/requirements.txt
```

### Recommended complete test runs

These commands build and run every variant supported by the selected target,
load the resulting alerts into Detect, and perform the Agentic payload review.
Luna with high reasoning effort is the recommended review configuration.
Automatic COM-port detection is recommended for the hardware target.

Recommended STM32U585 hardware run:

```powershell
python dfm_tests/run_suite.py --board b_u585i_iot02a `
  --com auto-detect --runner openocd `
  --model gpt-5.6-luna --reasoning-effort high --yes
```

The board must be connected and available because this command flashes it and
opens its ST-LINK VCP. `autodetect` remains accepted as an alias for
`auto-detect`.

Corresponding recommended QEMU run:

```powershell
python dfm_tests/run_suite.py --board qemu_mps2_an385 `
  --model gpt-5.6-luna `
  --reasoning-effort high --yes
```

Run all QEMU variants without invoking Detect:

```powershell
python dfm_tests/run_suite.py --skip-payload-processing
```

Focused runs use the same interface as the Zephyr suite:

```powershell
python dfm_tests/run_suite.py --variants m3_os --skip-payload-processing
python dfm_tests/run_suite.py --testcase 1025 --skip-payload-processing
```

Run the complete hardware suite after installing pyserial and an
STM32U5-capable OpenOCD. The runner finds the build bundled with Zephyr SDK as
well as STM32CubeCLT/STM32CubeIDE installations:

```powershell
python dfm_tests/run_suite.py --board b_u585i_iot02a `
  --com auto-detect --runner openocd --skip-payload-processing
```

The board console is USART1 over ST-LINK VCP at 460800 baud. The suite opens
the candidate COM port before each flash/reset, locks the detected port for the
rest of the run, and invokes OpenOCD only after serial capture is active. Set
`OPENOCD` to `openocd.exe` if it is not found automatically.

Each variant is configured from scratch below `build/dfm_tests`. Evidence is
recreated below `dfm_test_artifacts/Build-*` and contains the matching ELF,
linker map, `build-config.json`, and target log. The host validates target-side
checks, alert counts, description lengths, and every serial block's nonzero
CRC16 before reporting a suite PASS.

Without `--skip-payload-processing`, a full successful run invokes
`load-freertos-alerts.bat --suite-artifacts` and can optionally start the
read-only payload review. The loader resets Detect state and therefore should
be previewed independently before manual use:

```powershell
.\load-freertos-alerts.bat --dry-run
```

The ordinary review can override the Codex model and reasoning effort. If the
arguments are omitted, the current Codex configuration is used. Every agent
process records elapsed time and the input, cached-input, cache-write, output,
and reasoning token fields from the Codex JSONL stream. The console prints
totals and averages, and the complete data is saved as
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

### Agent-review benchmark

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
invalid metadata, removed/malformed TraceRecorder evidence, and simulated GDB
output ending in `ELF file not found. <eof>`. Baseline payloads are never
modified. With the default N=3 this is 54 logical agent passes.

The benchmark intentionally omits the extra agent-written final summary for
each configuration. Python deterministically evaluates the N expected PASS and
N expected FAIL verdicts, includes retry cost in the model/level totals, and
divides by `2*N` when reporting average time and tokens per logical agent pass.
The final console table and `benchmark-results.md` show model, reasoning effort,
accuracy PASS/FAIL, a short classification-error comment, average duration, and
average token consumption. All benchmark evidence and reports are written to
an ignored `build/agent-review-benchmark-*` directory.

### Agent-review fault injection

After a completely green run, the reviewer can be checked with a small negative
test without rerunning QEMU or reloading Detect:

```powershell
python dfm_tests/run_fault_injection_review.py
```

The command verifies that tests 1001, 1002, 1003, and 1012 were green and copies
only their evidence below the ignored `build/fault-injection-review-*`
directory. Test 1001 gets two coredump corruptions, test 1003 gets three
event-log corruptions, test 1012 gets inconsistent metadata plus a hidden
coredump payload, and test 1002 gets a simulated GDB export ending in
`ELF file not found. <eof>`. The original `dfm_test_artifacts` tree is not
modified.

Each affected test is tracked as expected to fail review. The final summary
lists tests that failed as expected, unexpected PASS verdicts, every explicitly
detected injected fault, and injected faults not mentioned by the agent. The
command returns zero only when every affected test receives `FAIL`; missed
individual fault details are still reported. Use `--prepare-only` to create and
inspect the injected copies without starting Codex:

```powershell
python dfm_tests/run_fault_injection_review.py --prepare-only
```

The model and reasoning level can be overridden for comparison runs. If omitted,
the current Codex configuration is used:

```powershell
python dfm_tests/run_fault_injection_review.py `
  --model 5.6-Sol --reasoning-effort medium
```

Detect alerts remain in the project-local `freertos-test` directory. Suite
alerts select their ELF by the DFM Revision field. A newer manual F5 log uses
`build/debug/Demo-FreeRTOS-QEMU.elf` instead.

## STM32U585 hardware target

The repository includes the STM32U585 startup/vector, linker script, CMSIS and
minimal HAL sources derived from
`percepio/Tracealyzer-STM32CubeIDE-SWO`, plus the matching FreeRTOS 11.3.1
Cortex-M33 port. TraceRecorder still uses this project's 4.11 FreeRTOS
kernelport and RingBuffer streamport; no SWO streamport is used.

Build and host orchestration have been verified without touching the board.
The first physical run still needs to verify OpenOCD/ST-LINK compatibility,
460800-baud VCP capture, clock/UART operation and the complete 1022/1023
payload/unwind oracle. The runner never changes STM32 option bytes and assumes
the board's TrustZone-disabled single-image configuration.

## F5 debugging

The workspace's default F5 configuration builds the unchanged `demo_app`,
starts QEMU with a GDB server on TCP port 1234, attaches Cortex-Debug, and
captures UART output in `qemu_last_session.log`. The normal demo remains the
default CMake build; test firmware is enabled only with
`-DDFM_TESTS_ENABLED=ON` or through `run_suite.py`.

See `testing-docs/dfm_test_cases.md` for the per-test payload oracle.
