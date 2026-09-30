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
(for the presets), Ninja, QEMU 10 or newer (for F5 console logging), and the
Zephyr SDK ARM GCC/GDB toolchain.
QEMU 10.0.2 and Zephyr SDK 1.0.1 have been used with this project. Put CMake
and Ninja on `PATH` and set your toolchain location, for example:

```powershell
$env:ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT = 'D:\sdk\gnu\arm-zephyr-eabi'
```

Alternatively, set `ZEPHYR_SDK_INSTALL_DIR` to the SDK root. The toolchain file
expects `arm-zephyr-eabi-*.exe` and Picolibc. Its fallback path points to the
original developer's installation.

CMake finds QEMU in the Zephyr SDK or on `PATH`. Override the executable with
`cmake --preset debug -DQEMU=C:/path/to/qemu-system-arm.exe` if needed.

## Build and run the demo

Run these commands from this project directory:

```powershell
cmake --fresh --preset debug -DDEMO_TARGET=qemu_mps2_m3
cmake --build --preset debug
cmake --build --preset debug --target run
```

Outputs are `build/debug/Demo-FreeRTOS-QEMU.elf` and
`build/debug/Demo-FreeRTOS-QEMU.map`. The run target starts QEMU in the current
terminal without changing `qemu_last_session.log`. Exit QEMU with Ctrl+A,
then X, as in ZephyrDemo.

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

QEMU may need MinGW runtime libraries on Windows. For command-line runs, add
their directory (normally `C:\Program Files\Git\mingw64\bin`) to `PATH`.

## VS Code debugging

Open this directory as the VS Code workspace, install the recommended
Cortex-Debug extension, and configure the QEMU build as above. Set `gdbPath`
and `armToolchainPath` in `.vscode/launch.json` to your SDK installation;
these do not follow the CMake toolchain environment variables. Update the
`-GdbPath` argument in `.vscode/tasks.json` to match your SDK.
Set `freertos.qemuWindowsRuntimePath` in `.vscode/settings.json` to the MinGW
runtime directory. Terminal scrollback is set to 100,000 lines.

- `Ctrl+Shift+B` runs the default task **CMake: clean build (debug)**.
- **CMake: build (debug)** performs an incremental build.
- **QEMU: run** builds and starts the demo in the task terminal without GDB.
- `F5` stops an earlier project QEMU, builds the configured `debug` image,
  starts QEMU's GDB server on TCP port 1234, and attaches Cortex-Debug at
  `main`. Continue execution to run the demo.

The ELF stores repository source paths under `src/` for the debug bundle.
The launch configuration uses `set substitute-path src ..` with GDB running
in `${workspaceFolder}`, covering both this project and the shared sources.
The relative path avoids Windows backslashes being interpreted as escapes
when Cortex-Debug forwards the command to GDB. If you change this mapping,
stop debugging and press `F5` to start a new session so the launch commands
run again.

The background task follows ZephyrDemo's launcher and invokes the CMake target
`debugserver_qemu_logged`, which runs QEMU directly. The launcher
waits for QEMU's GDB port before letting Cortex-Debug connect. QEMU's hub
sends UART output directly to both the **QEMU: start GDB server** terminal
and `qemu_last_session.log` in this project directory. Each F5 session
replaces the log; repeated Windows CR characters before LF are normalized
after QEMU exits. Terminal input goes directly to the guest UART.

QEMU loads `build/debug/Demo-FreeRTOS-QEMU.elf` directly and writes its PID to
`build/debug/qemu.pid`. The F5 sequence stops the previous QEMU before building
so its ELF file is no longer locked. The stop task first requests `monitor quit`
through GDB, with forced termination as a fallback. QEMU diagnostics appear
in the task terminal, as in ZephyrDemo.

Run and debug modes use ZephyrDemo's timing options:
`-icount shift=6,align=off,sleep=on -rtc clock=vm`. The QEMU FreeRTOS platform
enables an idle hook with `WFI`, matching Zephyr's CPU idle behavior. This is
needed for `sleep=on` to pace idle time; a spinning idle task allows virtual
time to run ahead of wall-clock time. The STM32 configuration is unchanged.

For a logged debug server outside VS Code, run
`cmake --build --preset debug --target debugserver_qemu_logged`. The ordinary
`debugserver` target provides a terminal console without replacing the log.

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
