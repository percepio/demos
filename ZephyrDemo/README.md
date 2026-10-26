# Percepio Detect for Zephyr

This demo lets you run Percepio Detect and Tracealyzer examples on Zephyr
with QEMU, without needing a physical board. It also works on physical
Arm Cortex-M boards supported by Zephyr, with minor board-specific adjustments
to devicetree overlay files, such as console configuration and retained-memory
settings. See [boards/](boards/) for examples.

It has been verified on `qemu_cortex_m3` and the ST B-U585I-IOT02A
(STM32U585/Cortex-M33) with Zephyr 4.4 and 4.5.

The demo cycles through examples of kernel tracing, data and
state logging, crash and custom alerts, stack corruption detection, latency
monitoring, and task CPU usage monitoring. Deliberate faults and resets are
part of the demo.

See the [repository guide](../README.md) for feature descriptions and screenshots.

## Requirements

- Clone the complete repository: the demo uses shared sources in
  `../UsageExamples` and `../PercepioLibs`.
- Have a configured Zephyr west workspace and its Python environment, with
  CMake and Ninja on `PATH`.
- Verified QEMU setup: Windows, Zephyr 4.5.0-rc1 (revision `ca10f7fc7a5b`),
  and Zephyr SDK 1.0.1. Console logging during debugging requires QEMU 10 or newer.

## Quick start: QEMU

From `ZephyrDemo/`, activate your Zephyr environment and build the demo.
Adjust these example installation paths to match your setup:

```powershell
& "$env:USERPROFILE\zephyrproject\.venv\Scripts\Activate.ps1"
$env:ZEPHYR_BASE = "$env:USERPROFILE\zephyrproject\zephyr"
$env:ZEPHYR_SDK_INSTALL_DIR = "$env:USERPROFILE\zephyr-sdk-1.0.1"
python -m west build -b qemu_cortex_m3 -p always -d build .
python -m west build -d build -t run
```

The console shows `Starting Percepio Detect demo`, followed by numbered
examples. **Deliberate faults and resets are part of the demo.** Exit QEMU
with Ctrl+A, then X. For Windows DLL errors, see [Troubleshooting](#troubleshooting).

## Troubleshooting

### QEMU fails to start on Windows

In the verified Windows setup, QEMU 10.0.2 from Zephyr SDK 1.0.1 failed to
start because its MinGW runtime DLLs were not on the DLL search path.
The workaround was to use `libgcc_s_seh-1.dll` and `libwinpthread-1.dll`
already installed by Git for Windows in `C:\Program Files\Git\mingw64\bin`.

For command-line runs, add this directory to the current PowerShell session's
`PATH` before starting QEMU:

```powershell
$env:PATH += ";C:\Program Files\Git\mingw64\bin"
```

For VS Code runs, `zephyr.qemuWindowsRuntimePath` in
[settings.json](.vscode/settings.json) is already set to this directory.
The Run task and debug launcher add it to QEMU's `PATH`. Adjust the setting if
Git for Windows is installed elsewhere.

## Debug in VS Code

Open [ZephyrDemo.code-workspace](ZephyrDemo.code-workspace) and install
Cortex-Debug. Update the Python and Zephyr/SDK paths in
[tasks.json](.vscode/tasks.json), and the GDB/toolchain paths in
[launch.json](.vscode/launch.json), to match your installation.

| Action | Shortcut |
| --- | --- |
| Build from scratch (`-p always`) | Ctrl+Shift+B |
| Start debugging (`--pristine=auto` build) and stop in `main` | F5 |
| Continue execution | F5 while paused |
| Stop debugging | Shift+F5 |

Console output appears in the **Zephyr: QEMU GDB server** terminal and is saved
to `qemu_last_session.log`. Each debug session replaces this log. The command-line
`run` target above displays output without creating the log file.

## View alerts in Percepio Detect

Install the Detect Receiver, server, and client, with Docker for the server.
See the [Detect guide](../README.md#percepio-detect-demos) for setup and viewing
traces and core dumps. Then:

1. Start a [debug session in VS Code](#debug-in-vs-code), choose **Continue**
   (F5) at `main`, and let the demo generate alerts. Stop debugging (Shift+F5).

2. Follow the instructions in `Percepio Detect Demo Guide.pdf`, found in the
   root of the Detect folder. Make sure to start the Detect server and client.

3. Copy `build/zephyr/zephyr.elf` from this folder to
   `demo-data/zephyr-demo-v1.0.elf` in your Detect folder. This matches the
   client's default `project-settings.py`, where `ELF_PATH` is set to
   `../demo-data/${revision}.elf` and `${revision}` comes from
   `CONFIG_PERCEPIO_DFM_CFG_FIRMWARE_VERSION` in `prj.conf`. If each build has
   a unique Firmware Revision value, the client can find the correct ELF file
   even when alerts from multiple builds are mixed.

4. In the Detect folder, open `percepio-receiver/receiver-demo.bat` (or `.sh`
   on Linux) in a text editor and set the input path (e.g. `logfile`) to your
   device log file. With the default QEMU setup, this is `qemu_last_session.log`. On a
   physical board, capture the device output to a log file using a serial
   terminal application. Make sure to provide the full path to this log file
   in the `receiver-demo` script.

5. Run the `receiver-demo` script to write alert data files to the alert folder.
   The Detect server monitors this folder by default, so the alerts should
   appear at http://localhost:8080 within 5-10 seconds.

## Advanced

### Windows setup

The VS Code paths default to `%USERPROFILE%\zephyrproject` and
`%USERPROFILE%\zephyr-sdk-1.0.1`. If using the Percepio Trace Exporter extension,
configure its Tracealyzer installation path through the extension.

### Local or upstream Percepio libraries

The source selection applies to both DFM and TraceRecorder, including Kconfig:

| `DEMO_PERCEPIO_SOURCE` | Sources |
| --- | --- |
| `local` (default) | `../PercepioLibs`, using this demo's `modules/percepio` adapter |
| `upstream` | The Percepio module in your Zephyr west workspace |

**Use `local` for this release.** The required changes are not yet available
upstream. Select `upstream` once that module supports the demo's options and APIs.
No library files need to be copied into the Zephyr workspace.

In VS Code, set `zephyr.percepioSource` to `local` or `upstream` in
[settings.json](.vscode/settings.json). Both build tasks pass this value,
including during pristine builds. From the command line, select explicitly:

```powershell
python -m west build -b qemu_cortex_m3 -p always -d build . -- -DDEMO_PERCEPIO_SOURCE=upstream
```

Replace `upstream` with `local` to switch back. The command-line selection is
cached per build directory; a pristine build without it uses `local`.

### Arm Cortex-M hardware

For the verified B-U585I-IOT02A board, build with TrustZone disabled:

```powershell
python -m west build -b b_u585i_iot02a -p always -d build/stm32u585 .
```

Images are generated under `build/stm32u585/zephyr`. Flash with a
Zephyr-supported runner for the board. The console uses USART1 over ST-LINK
VCP at 460800 baud. The supplied VS Code debug configuration is for QEMU only.

For other Arm Cortex-M boards, select the corresponding Zephyr board target
and adjust the console settings and any retained-memory overlays to match.

### Firmware configuration

Settings are in [prj.conf](prj.conf), with board settings and overlays in
[boards/](boards/). Defaults use a 4 KiB trace RingBuffer, serial alert output,
and immediate core dump transmission through Zephyr's core dump backend.

For retained-memory mode, also select the matching
`boards/qemu_cortex_m3_retained.overlay` or
`boards/b_u585i_iot02a_retained.overlay` through `EXTRA_DTC_OVERLAY_FILE`.
These reserve the top of SRAM and reduce the normal `sram0` region; use one
matching overlay and adjust its addresses and size when porting to another board.
