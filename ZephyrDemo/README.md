# Percepio Zephyr demo for QEMU Cortex-M3 and STM32U585

This project demonstrates Percepio TraceRecorder and the DFM library for
Percepio Detect on Zephyr. It supports `qemu_cortex_m3` (Cortex-M3, no board
required) and the B-U585I-IOT02A board (STM32U585/Cortex-M33).

The default application cycles through examples of kernel tracing, data and
state logging, crash and custom alerts, stack corruption detection, latency
monitoring, and task CPU usage monitoring. Deliberate faults and resets are
part of the demo.

## Sources and requirements

The build uses a Zephyr workspace and shared sources outside this directory.
These must be available before configuring. The expected sources are:

- `../UsageExamples` — shared demo runner and examples;
- a Zephyr west workspace, including `modules/debug/percepio`;
- `modules-staging/modules/debug/percepio` — the updated TraceRecorder and
  DFM sources required by this demo.

Apply the supplied Percepio sources to the workspace's `modules/debug/percepio`
directory. Also copy `modules-staging/CMakeLists.txt` to the workspace's
`zephyr/modules/percepio/CMakeLists.txt`. The application uses the workspace
modules; it does not automatically build from `modules-staging`. The build
uses TraceRecorder's Zephyr kernel port and RingBuffer stream port, together
with Zephyr's native core dump support.

The supplied VS Code tasks and Detect loader target Windows with PowerShell,
Python and west, CMake, Ninja, and the Zephyr SDK ARM GCC/GDB toolchain.
The tasks use Zephyr SDK 1.0.1; QEMU 10 or newer is required for F5 console
logging. Linux host operation has not been verified for this project version.

Activate your Zephyr Python environment and set the workspace and SDK paths,
for example:

```powershell
& "$env:USERPROFILE\zephyrproject\.venv\Scripts\Activate.ps1"
$env:ZEPHYR_BASE = "$env:USERPROFILE\zephyrproject\zephyr"
$env:ZEPHYR_SDK_INSTALL_DIR = "$env:USERPROFILE\zephyr-sdk-1.0.1"
```

Put CMake and Ninja on `PATH`. On Windows, QEMU may also need the MinGW runtime
DLLs `libgcc_s_seh-1.dll` and `libwinpthread-1.dll`. Add their directory to
`PATH` for command-line runs; Git for Windows normally provides them under
`C:\Program Files\Git\mingw64\bin`.

## Build and run the demo

Run these commands from this project directory:

```powershell
python -m west build -b qemu_cortex_m3 -p always -d build .
python -m west build -d build -t run
```

Outputs include `build/zephyr/zephyr.elf` and `build/zephyr/zephyr.map`.
The run target starts QEMU in the current terminal. Exit QEMU with Ctrl+A,
then X. This target uses Zephyr's `qemu_cortex_m3` machine (`lm3s6965evb`).

For STM32U585, board support comes from the Zephyr workspace. The board must
use the TrustZone-disabled configuration for this target:

```powershell
python -m west build -b b_u585i_iot02a -p always -d build/stm32u585 .
```

Firmware images are generated under `build/stm32u585/zephyr`. Flash the image
using a Zephyr-supported runner for the board. The board console uses USART1
over ST-LINK VCP at 460800 baud, as configured in
`boards/b_u585i_iot02a.overlay`. F5 is configured for QEMU only.

## VS Code debugging

Open this directory as the VS Code workspace, install Cortex-Debug, and
configure the QEMU build as above. Update the Python, `ZEPHYR_BASE` and
`ZEPHYR_SDK_INSTALL_DIR` paths in `.vscode/tasks.json`, and `gdbPath` and
`armToolchainPath` in `.vscode/launch.json`, to match your installation.
The checked-in paths use `%USERPROFILE%\zephyrproject` and
`%USERPROFILE%\zephyr-sdk-1.0.1`.

Set `zephyr.qemuWindowsRuntimePath` in `.vscode/settings.json` to your MinGW
runtime directory. If using the Percepio Trace Exporter extension, configure
its Tracealyzer installation path through the extension.

- `Ctrl+Shift+B` runs the default task **Zephyr: Build qemu_cortex_m3**, which
  performs a pristine build.
- **Zephyr: Run qemu_cortex_m3** builds and starts the demo.
- `F5` stops an earlier QEMU GDB server, builds the debug image, starts QEMU's
  GDB server on TCP port 1234, and attaches Cortex-Debug at `main`. Continue
  execution to run the demo.

UART output is shown in the **Zephyr: QEMU GDB server** terminal and saved to
`qemu_last_session.log`. Each F5 session replaces the log; the launcher
normalizes Windows line endings after QEMU exits. Both F5 and normal builds use
`CONFIG_PERCEPIO_DFM_CFG_FIRMWARE_VERSION` in `prj.conf` for the firmware Revision.
The F5 build clears `EXTRA_CONF_FILE` to remove any cached debug override.
The normal `run` target displays console output without creating this log.

## Load captured alerts into Percepio Detect

This optional step requires a local Detect Receiver, server and client, plus
Docker for the server. Adapt the paths at the top of `load-zephyr-alerts.bat`
to your installation: `DETECT_ROOT` defaults to `C:\src\DetectRepo`. The
default ELF path is resolved from the project directory.

After capturing a QEMU session with F5, use the VS Code task
**Detect: Load alerts** to run this loader. The F5 session log is
`qemu_last_session.log`, with `build/zephyr/zephyr.elf` as its matching firmware
image. Keep that ELF matched to the captured log and check the selected input
with `--dry-run` before loading.

By default, the loader uses an already running Detect server, replaces the
alert files in the project's `ALERT_DIR` (`alert-files` by default), and
restarts the client using that directory. The server and its existing
database are retained. Check paths and preview the actions:

```powershell
.\load-zephyr-alerts.bat --dry-run
```

An existing Detect server may be monitoring a different alert directory.
To reset the server and restart it with this project's alert directory, run
the command below. **This deletes the existing Detect database.**

```powershell
.\load-zephyr-alerts.bat --reset_and_restart_server
```

Preview this mode with `--dry-run --reset_and_restart_server`.

`--receiver-only` replaces the alerts in `ALERT_DIR` without changing the
Detect server or client; it cannot be combined with `--reset_and_restart_server`.

## Configuration

Zephyr, DFM and TraceRecorder settings are in `prj.conf`; board-specific
settings and devicetree overlays are in `boards/`. The defaults use a 4 KiB
trace RingBuffer, the DFM serial cloud port, and immediate core dump
transmission through Zephyr's core dump backend.

If enabling DFM retained-memory mode, also add the matching
`boards/qemu_cortex_m3_retained.overlay` or
`boards/b_u585i_iot02a_retained.overlay` through `EXTRA_DTC_OVERLAY_FILE`.
The ordinary board overlays do not reserve this RAM. The retained-memory
overlays reserve the top of SRAM and reduce the normal `sram0` region;
select only one and adjust its addresses and size when porting to another board.
