# Percepio Detect for FreeRTOS

This demo lets you run Percepio Detect and Tracealyzer examples on FreeRTOS
with QEMU, without needing a physical board. It uses Percepio TraceRecorder
and the DFM library, and supports QEMU `mps2-an385` (Cortex-M3) and the
ST B-U585I-IOT02A board (STM32U585/Cortex-M33).

The default application cycles through examples of kernel tracing, data and
state logging, crash and custom alerts, stack corruption detection, latency
monitoring, and task CPU usage monitoring. Deliberate faults and resets are
part of the demo.

See the [repository guide](../README.md) for feature descriptions and screenshots.

## Sources and requirements

Clone the complete repository: the build uses shared sources outside this
directory. These must be available before configuring; CMake does not download
them. The included sources are:

- `../UsageExamples` — shared demo runner and examples;
- `../PercepioLibs/TraceRecorder` — Percepio TraceRecorder 4.12.0;
- `../PercepioLibs/CrashCatcher` — CrashCatcher;
- `../PercepioLibs/DFM` — Percepio DFM 2.2.0;
- `third_party/FreeRTOS-Kernel` — included FreeRTOS-Kernel V11.3.1.

The build uses the Percepio libraries in `../PercepioLibs` by default.
All three library paths are derived from `PERCEPIO_LIBS_DIR`; old cached
`DFM_DIR`, `TRACERECORDER_DIR` and `CRASHCATCHER_DIR` values are ignored.
To use another complete library directory, configure with
`-DPERCEPIO_LIBS_DIR=C:/path/to/PercepioLibs`.
After updating an existing checkout, run `cmake --fresh --preset debug` once
to clear any outdated toolchain paths as well.

The supplied scripts target Windows with PowerShell, CMake 3.25 or newer
(for the presets), Ninja, QEMU 10 or newer, and an Arm GCC/GDB toolchain with Picolibc.
QEMU 10.0.2 and GCC 14.3.0 have been used with this project. Put CMake and
Ninja on `PATH` and set your toolchain location, for example:

```powershell
$env:ARM_TOOLCHAIN_ROOT = 'D:\toolchains\arm'
```

Set this to the directory containing the toolchain's `bin` folder.
Alternatively, set `ARM_SDK_INSTALL_DIR` to the SDK root for the bundled
directory layout used by [arm-gcc-toolchain.cmake](cmake/arm-gcc-toolchain.cmake).
The toolchain file specifies the expected executable names; its fallback path
points to the original developer's installation.

CMake finds QEMU in the SDK or on `PATH`. Override the executable with
`cmake --preset debug -DQEMU=C:/path/to/qemu-system-arm.exe` if needed.

## Quick start: QEMU

Run these commands from this project directory:

```powershell
cmake --fresh --preset debug -DDEMO_TARGET=qemu_mps2_m3
cmake --build --preset debug
cmake --build --preset debug --target run
```

Outputs are `build/debug/Demo-FreeRTOS-QEMU.elf` and
`build/debug/Demo-FreeRTOS-QEMU.map`. The run target starts QEMU in the current
terminal without changing `qemu_last_session.log`. The console shows
`Booting Percepio FreeRTOS demo`, followed by numbered examples.
Exit QEMU with Ctrl+A, then X. For Windows DLL errors, see
[Troubleshooting](#troubleshooting).

## Troubleshooting

### QEMU fails to start on Windows

QEMU may need the MinGW runtime DLLs `libgcc_s_seh-1.dll` and
`libwinpthread-1.dll` on Windows. Git for Windows normally provides them in
`C:\Program Files\Git\mingw64\bin`. For command-line runs, add this directory
to the current PowerShell session's `PATH` before starting QEMU:

```powershell
$env:PATH += ";C:\Program Files\Git\mingw64\bin"
```

For VS Code runs, `freertos.qemuWindowsRuntimePath` in
[settings.json](.vscode/settings.json) is already set to this directory.
The **QEMU: run** task and debug launcher add it to QEMU's `PATH`.
Adjust the setting if Git for Windows is installed elsewhere.

## Debug in VS Code

Open [Demo-FreeRTOS-QEMU.code-workspace](Demo-FreeRTOS-QEMU.code-workspace)
or this directory in VS Code and install the recommended Cortex-Debug extension.
Press Ctrl+Shift+B and choose `qemu_cortex_m3` or `b_u585i-iot02a`
(ST B-U585I-IOT02A, STM32U585/Cortex-M33). This always configures and builds
from scratch and saves the selection in `build/selected-target.txt`.
Both VS Code targets use `build/debug` for their outputs.

F5 uses the last selected target without prompting and applies `pristine=auto`:
it rebuilds from scratch if the build configuration is missing or incompatible
(for example after switching target), otherwise it builds incrementally.
Before a target has been selected, it uses the existing build target or defaults
to QEMU. Set `gdbPath`
and `armToolchainPath` in [launch.json](.vscode/launch.json) to your SDK installation;
these do not follow the CMake toolchain environment variables. Update the
`-GdbPath` argument in [tasks.json](.vscode/tasks.json) to match your SDK.
Terminal scrollback is set to 100,000 lines. If using the Percepio Trace Exporter
extension, configure its Tracealyzer installation path through the extension.

| Action | Shortcut or task |
| --- | --- |
| Choose target and build from scratch | Ctrl+Shift+B — **CMake: clean build (debug)** |
| Build last selected target (`pristine=auto`) | **CMake: build (debug)** |
| Select QEMU, build and run in the task terminal without GDB | **QEMU: run** |
| Debug last selected target (`pristine=auto`) and stop in `main` | F5 |
| Continue execution | F5 while paused |
| Stop debugging | Shift+F5 |

QEMU console output appears in the **Debug: start GDB server** terminal and is saved
to `qemu_last_session.log`. Each debug session replaces this log. The command-line
`run` target above displays output without creating the log file.

For STM32, connect the board's ST-LINK USB port. The debug launcher finds
OpenOCD and its ST scripts in STM32CubeIDE installations under `C:/ST`.
For another installation, set `freertos.openOcdPath` (the executable) and
`freertos.openOcdScripts` (the directory containing `interface/` and `target/`)
in [settings.json](.vscode/settings.json). F5 programs the firmware via ST-LINK
and stops in `main`; the board's console uses the separate ST-LINK serial port.

## View alerts in Percepio Detect

Download and install the Percepio Detect package and see the [Detect guide](../README.md#percepio-detect-demos) for setup and viewing
traces and core dumps. Then:

1. Start a [debug session in VS Code](#debug-in-vs-code), choose **Continue**
   (F5) at `main`, and let the demo generate alerts. Stop debugging (Shift+F5).

2. Follow the instructions in `Percepio Detect Demo Guide.pdf`, found in the
   root of the Detect folder. Make sure to start the Detect server and client.

3. Copy `build/debug/Demo-FreeRTOS-QEMU.elf` from this folder to
   `demo-data/freertos-demo-v1.0.elf` in your Detect folder. This matches the
   client's default `project-settings.py`, where `ELF_PATH` is set to
   `../demo-data/${revision}.elf` and `${revision}` comes from
   `DFM_CFG_FIRMWARE_VERSION` in [config/dfmConfig.h](config/dfmConfig.h).
   Keep the ELF matched to the captured log. If each build has a unique
   Firmware Revision value, the client can find the correct ELF file even when
   alerts from multiple builds are mixed. If building for STM32U585, copy 
   `build/stm32u585/Demo-FreeRTOS-QEMU.elf` instead when using the manual build
   commands below. VS Code builds use `build/debug` for both targets.

4. In the Detect folder, open `percepio-receiver/receiver-demo.bat` (or `.sh`
   on Linux) in a text editor and set the input path (e.g. `logfile`) to your
   device log file. With the default QEMU setup, this is `qemu_last_session.log`
   in this project directory. On a physical board, capture the device output
   to a log file using a serial terminal application. Make sure to provide the
   full path to this log file in the `receiver-demo` script.

5. Run the `receiver-demo` script to write alert data files to the alert folder.
   The Detect server monitors this folder by default, so the alerts should
   appear at http://localhost:8080 within 5-10 seconds.

## Advanced

### STM32U585 hardware

For STM32U585, startup, CMSIS, HAL and linker sources are included. The board
must use a TrustZone-disabled, single-image configuration.

```powershell
cmake --fresh -G Ninja -S . -B build/stm32u585 `
  "-DCMAKE_TOOLCHAIN_FILE=cmake/arm-gcc-toolchain.cmake" `
  "-DDEMO_TARGET=b_u585i_iot02a"
cmake --build build/stm32u585
```

This produces ELF, HEX and BIN images in `build/stm32u585`. The board console
uses USART1 over ST-LINK VCP at 460800 baud. To build and debug this board
in VS Code, select `b_u585i-iot02a` with Ctrl+Shift+B, then press F5.


### Library settings

FreeRTOS settings are in [include/FreeRTOSConfig.h](include/FreeRTOSConfig.h);
DFM and TraceRecorder settings are in [config/](config/).
The defaults use a 10 KiB overwrite-mode trace
RingBuffer, the DFM serial cloud port, and dummy storage. CrashCatcher payloads
are named `trap.dmp` for `DFM_TRAP()` and `fault.dmp` for processor faults.
