# FreeRTOS DFM/TraceRecorder test suite

This suite is the FreeRTOS/QEMU port of the sibling `ZephyrDemo/dfm_tests`
suite. The host protocol, test IDs, build labels, COM-port reader, Detect
pipeline, and review workflow intentionally remain as close to the Zephyr
implementation as the platform permits.

## Current scope

Only QEMU `mps2-an385`/Cortex-M3 execution is supported. The implemented suite
contains tests 1001–1021, 1024, and the FreeRTOS-specific real HardFault test
1025. Tests 1022 and 1023 are Cortex-M33/hardware qualification cases and are
deferred.

The port uses:

- FreeRTOS with the GCC ARM_CM3 port;
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

Run all QEMU variants without invoking Detect:

```powershell
python dfm_tests/run_suite.py --skip-payload-processing
```

Focused runs use the same interface as the Zephyr suite:

```powershell
python dfm_tests/run_suite.py --variants m3_os --skip-payload-processing
python dfm_tests/run_suite.py --testcase 1025 --skip-payload-processing
```

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

Detect alerts remain in the project-local `freertos-test` directory. Suite
alerts select their ELF by the DFM Revision field. A newer manual F5 log uses
`build/debug/Demo-FreeRTOS-QEMU.elf` instead.

## Hardware work still required

The pyserial reader, 8-N-1 setup, descending COM-number auto-detection, 1 KiB
`Percepio` identity probe, continuous capture, and fresh-run marker validation
are ported and unit-tested. The CLI retains `--board`, `--com auto-detect`, and
`--runner`, but currently rejects physical execution before a build because no
FreeRTOS hardware image/flash adapter exists yet.

The recommended first target is the STM32U585-based B-U585I-IOT02A. Remaining
work is to add ST startup/vector and clock/UART setup, a board linker script,
the Cortex-M33 FreeRTOS port and FPU/stack-limit configuration, and a build and
flash runner that can be called while the selected serial port is open. The ST
startup basis can be taken from:

https://github.com/percepio/Tracealyzer-STM32U5-FreeRTOS-JLinkRTT

After that adapter exists, enable the currently deferred 1022/1023
Cortex-M33 qualification profiles and connect the already present serial
capture path instead of introducing a second host protocol.

## F5 debugging

The workspace's default F5 configuration builds the unchanged `demo_app`,
starts QEMU with a GDB server on TCP port 1234, attaches Cortex-Debug, and
captures UART output in `qemu_last_session.log`. The normal demo remains the
default CMake build; test firmware is enabled only with
`-DDFM_TESTS_ENABLED=ON` or through `run_suite.py`.

See `testing-docs/dfm_test_cases.md` for the per-test payload oracle.
