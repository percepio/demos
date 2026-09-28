# Percepio FreeRTOS demo for QEMU MPS2 and STM32U585

This project demonstrates Percepio TraceRecorder and the DFM library for
Percepio Detect on FreeRTOS. It supports QEMU `mps2-an385` (Cortex-M3, no board
required) and the B-U585I-IOT02A board (STM32U585/Cortex-M33).

The default application cycles through examples of kernel tracing, data and
state logging, crash and custom alerts, stack corruption detection, latency
monitoring, and task CPU usage monitoring. Deliberate faults and resets are
part of the demo.

## Sources and requirements

The build uses shared sources outside this directory. These must be available
before configuring; CMake does not download them. The default layout is:

- `../UsageExamples` — shared demo runner and examples;
- `../PercepioLibs/TraceRecorder` — TraceRecorder 4.11.0;
- `../PercepioLibs/CrashCatcher` — CrashCatcher;
- `../ZephyrDemo/modules-staging/modules/debug/percepio/DFM` — staging DFM;
- `third_party/FreeRTOS-Kernel` — included FreeRTOS-Kernel V11.3.1 with
  GCC ARM_CM3/ARM_CM33_NTZ ports and `heap_4.c`.

The sibling locations can be overridden with the CMake cache variables
`USAGE_EXAMPLES_DIR`, `TRACERECORDER_DIR`, `DFM_DIR`, and `CRASHCATCHER_DIR`.
The build uses TraceRecorder's FreeRTOS kernel port and RingBuffer stream port.

The supplied scripts target Windows with PowerShell, CMake 3.25 or newer
(for the presets), Ninja, QEMU, and the Zephyr SDK ARM GCC/GDB toolchain.
QEMU 10.0.2 and Zephyr SDK 1.0.1 have been used with this project. Put CMake
and Ninja on `PATH` and set your toolchain location, for example:

```powershell
$env:ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT = 'D:\sdk\gnu\arm-zephyr-eabi'
```

Alternatively, set `ZEPHYR_SDK_INSTALL_DIR` to the SDK root. The toolchain file
expects `arm-zephyr-eabi-*.exe` and Picolibc. Its fallback path points to the
original developer's installation.

Set the default `$Qemu` path in `cmake/Invoke-Qemu.ps1` to your
`qemu-system-arm.exe` before using the `run` target. For a direct script
invocation, use its `-Qemu` argument instead.

## Build and run the demo

Run these commands from this project directory:

```powershell
cmake --fresh --preset debug -DDEMO_TARGET=qemu_mps2_m3
cmake --build --preset debug
cmake --build --preset debug --target run
```

Outputs are `build/debug/Demo-FreeRTOS-QEMU.elf` and
`build/debug/Demo-FreeRTOS-QEMU.map`. The run target starts QEMU in the current
terminal. Stop it with Ctrl+C.

For STM32U585, startup, CMSIS, HAL and linker sources are included. The board
must use a TrustZone-disabled, single-image configuration.

```powershell
cmake --fresh -G Ninja -S . -B build/stm32u585 `
  "-DCMAKE_TOOLCHAIN_FILE=cmake/arm-zephyr-eabi-toolchain.cmake" `
  "-DDEMO_TARGET=b_u585i_iot02a"
cmake --build build/stm32u585
```

This produces ELF, HEX and BIN images in `build/stm32u585`. The board console
uses USART1 over ST-LINK VCP at 460800 baud. F5 is configured for QEMU only.

The QEMU scripts add `C:\Program Files\Git\mingw64\bin` to `PATH` when available
for MinGW runtime libraries.

## VS Code debugging

Open this directory as the VS Code workspace, install the recommended
Cortex-Debug extension, and configure the QEMU build as above. Set `gdbPath`
and `armToolchainPath` in `.vscode/launch.json` to your SDK installation;
these do not follow the CMake toolchain environment variables. Also update
the default `$Qemu` path in `.vscode/Invoke-QemuGdbServer.ps1`,
`.vscode/Stop-QemuGdbServer.ps1`, and `.vscode/Watch-QemuSerial.ps1`.

- `Ctrl+Shift+B` runs the default task **CMake: clean build (debug)**.
- **CMake: build (debug)** performs an incremental build.
- `F5` stops an earlier project QEMU, builds the configured `debug` image,
  starts QEMU's GDB server on TCP port 1234, and attaches Cortex-Debug at
  `main`. Continue execution to run the demo.

The launcher copies the image to `Demo-FreeRTOS-QEMU.qemu.elf` so a running
QEMU process cannot lock the build output. UART output is shown in the
**QEMU: watch serial output** terminal and saved to `qemu_last_session.log`.
QEMU errors go to `qemu-gdb.error.log` for F5 and `build/debug/qemu.error.log`
for the `run` target. Both modes pace virtual time against the host clock.

## Load captured alerts into Percepio Detect

This optional step requires a local Detect Receiver, server and client, plus
Docker for the server. Adapt the paths at the top of `load-freertos-alerts.bat`
to your installation: `DETECT_ROOT` defaults to `C:\src\DetectRepo`. The
default ELF path is resolved from the project directory.

After capturing a QEMU session with F5, use the VS Code task
**Detect: Load alerts** to run this loader. The F5 session log is
`qemu_last_session.log`, with `build/debug/Demo-FreeRTOS-QEMU.elf` as its
matching firmware image. Keep that ELF matched to the captured log and check
the selected input with `--dry-run` before loading.

By default, the loader uses an already running Detect server, replaces the
alert files in the project's `ALERT_DIR` (`freertos-test` by default), and
restarts the client using that directory. The server and its existing
database are retained. Check paths and preview the actions:

```powershell
.\load-freertos-alerts.bat --dry-run
```

An existing Detect server may be monitoring a different alert directory.
To reset the server and restart it with this project's alert directory, run
the command below. **This deletes the existing Detect database.**

```powershell
.\load-freertos-alerts.bat --reset_and_restart_server
```

Preview this mode with `--dry-run --reset_and_restart_server`.

`--receiver-only` replaces the alerts in `ALERT_DIR` without changing the
Detect server or client; it cannot be combined with `--reset_and_restart_server`.

## Configuration

FreeRTOS settings are in `include/FreeRTOSConfig.h`; DFM and TraceRecorder
settings are in `config/`. The defaults use a 10 KiB overwrite-mode trace
RingBuffer, the DFM serial cloud port, and dummy storage. CrashCatcher payloads
are named `trap.dmp` for `DFM_TRAP()` and `fault.dmp` for processor faults.
