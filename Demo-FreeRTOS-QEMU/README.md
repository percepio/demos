# Percepio FreeRTOS demo for QEMU MPS2 and STM32U585

This is a standalone bare-metal FreeRTOS demo for QEMU
`mps2-an385`/Cortex-M3 and B-U585I-IOT02A/STM32U585. The normal build keeps the
shared `demo_app` example flow. A separate build option adds the
DFM/TraceRecorder/CrashCatcher test suite ported from the sibling `ZephyrDemo`
repository.

## Sources and requirements

The expected sibling layout is:

- `../UsageExamples` — shared demo runner and examples;
- `../PercepioLibs/TraceRecorder` — TraceRecorder 4.11.0;
- `../PercepioLibs/CrashCatcher` — CrashCatcher;
- `../ZephyrDemo/modules-staging/modules/debug/percepio/DFM` — staging DFM;
- `third_party/FreeRTOS-Kernel` — FreeRTOS-Kernel V11.3.1, GCC ARM_CM3 and
  ARM_CM33_NTZ ports,
  and `heap_4.c`.

TraceRecorder is pinned to upstream tag `Tz4/4.11/v4.11.0`, commit
`2f888cb9e6240c88e33eacd5acd50555fb13fbf5`. Only its FreeRTOS kernel port and
RingBuffer stream port are retained.

The project has been tested on Windows with CMake, Ninja, QEMU 10.0.2, and the
Zephyr SDK 1.0.1 ARM GCC/GDB toolchain. Building does not download source code.
To use another toolchain:

```powershell
$env:ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT = 'D:\sdk\gnu\arm-zephyr-eabi'
```

The sibling locations can be overridden with the CMake cache variables
`USAGE_EXAMPLES_DIR`, `TRACERECORDER_DIR`, `DFM_DIR`, and `CRASHCATCHER_DIR`.

## Build and run the demo

```powershell
cmake --preset debug
cmake --build --preset debug
cmake --build --preset debug --target run
```

Outputs are `build/debug/Demo-FreeRTOS-QEMU.elf` and
`build/debug/Demo-FreeRTOS-QEMU.map`. The run target starts QEMU in the current
terminal. Stop it with Ctrl+C.

The checked-in STM32U585 startup, CMSIS, HAL and linker sources can also build
the normal demo without downloading board support:

```powershell
cmake --fresh -G Ninja -S . -B build/stm32u585 `
  "-DCMAKE_TOOLCHAIN_FILE=cmake/arm-zephyr-eabi-toolchain.cmake" `
  "-DDEMO_TARGET=b_u585i_iot02a"
cmake --build build/stm32u585
```

This produces ELF, HEX and BIN images. Flashing and serial orchestration are
provided by the test runner described below; F5 intentionally remains QEMU
only.

The QEMU path can be overridden with the `-Qemu` argument to
`cmake/Invoke-Qemu.ps1`. On Windows the scripts add
`C:\Program Files\Git\mingw64\bin` to `PATH` when available, for QEMU's MinGW
runtime libraries.

## F5 debugging

Open this directory as the VS Code workspace and install the recommended
Cortex-Debug extension.

- `Ctrl+Alt+B` runs **CMake: clean build (debug)**.
- **CMake: build (debug)** performs an incremental build.
- `F5` stops an earlier project QEMU, builds the normal demo, starts QEMU's GDB
  server on TCP port 1234, and attaches Cortex-Debug.

The launcher copies the image to `Demo-FreeRTOS-QEMU.qemu.elf` so a running
QEMU process cannot lock the build output. It validates the project PID and
executable before stopping a process. UART output is shown in the
**QEMU: watch serial output** terminal and saved to `qemu_last_session.log`;
QEMU errors go to `qemu-gdb.error.log`.

Both normal and debug runs use:

```text
-icount shift=6,align=on,sleep=on -rtc clock=vm
```

With QEMU 10, `align=on` throttles virtual time to the host clock and requires
`sleep=on`. This keeps FreeRTOS delays paced against wall-clock time.

## DFM/TraceRecorder test suite

Run the full QEMU suite without invoking Detect:

```powershell
python dfm_tests/run_suite.py --skip-payload-processing
```

The default demo remains unchanged; test firmware is enabled only by the suite
or by configuring CMake with `-DDFM_TESTS_ENABLED=ON`. The suite covers normal
call chains, optimization variants, `main()` on MSP, an interrupt on MSP,
FreeRTOS task and timer-daemon contexts, a temporary Thread/MSP stack, reset
paths, buffer/stack boundaries, and a real HardFault. CrashCatcher payloads are
named `trap.dmp` for `DFM_TRAP()` and `fault.dmp` for processor faults.

See [dfm_tests/README.md](dfm_tests/README.md) for focused commands, artifacts,
payload review, COM auto-detection, and the STM32U585 hardware target. QEMU
remains the default; `--board b_u585i_iot02a` adds the hardware-only 1022/1023
qualification build and flashes it with the ST OpenOCD fork.

## Load captured alerts into Detect

The VS Code task **Detect: Load alerts** runs `load-freertos-alerts.bat`. It
selects either every fresh `dfm_test_artifacts/Build-*/qemu.log` from the suite
or a newer manual `qemu_last_session.log`. Suite alerts select their archived
ELF through DFM Revision; a manual F5 run uses
`build/debug/Demo-FreeRTOS-QEMU.elf`. Alerts remain in `freertos-test`.

A full load cleans Detect's state and database, stops an existing Detect
client, invokes the Receiver, restarts the server, and starts the client. Check
all paths and preview the actions without changing Detect:

```powershell
.\load-freertos-alerts.bat --dry-run
```

The loader also supports `--suite-artifacts`, `--serial-log FILE`,
`--device-name NAME`, and `--receiver-only`, matching the Zephyr suite.

## Implementation notes

- MPS2 RAM spans `0x20000000`–`0x203fffff`; `.noinit` state survives the QEMU
  resets used by multi-boot tests.
- MPS2 TIMER0 supplies DFM's free-running timestamp. SysTick belongs to the
  FreeRTOS scheduler.
- TraceRecorder uses a 10 KiB overwrite-mode RingBuffer. DFM uses its serial
  cloud port and dummy storage port.
- The serial cloud port computes the same CRC16-CCITT formulation as Zephyr's
  software implementation; the host verifies every block.
- QEMU instruction counting uses `align=on,sleep=on` so FreeRTOS delays follow
  wall-clock time. QEMU diagnostics are kept separate from the UART stream in
  `qemu.error.log` or `qemu-gdb.error.log`.
- TraceRecorder critical sections use Cortex-M `PRIMASK` because trace hooks
  can run from PendSV.
- The staging DFM has pre-existing warnings in `dfmTaskMonitor.c` and
  `dfmUtility.c`; they are not hidden by this project.
