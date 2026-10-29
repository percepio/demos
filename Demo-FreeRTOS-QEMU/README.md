# Percepio Detect for FreeRTOS: QEMU demo

Try the FreeRTOS tracing and diagnostic examples on Windows or Linux using QEMU.
No physical board is needed. The demo generates tracing data and alerts for
crashes, stack corruption, latency and CPU usage. Deliberate faults and restarts
are part of the examples.

A physical **ST B-U585I-IOT02A / STM32U585** board is also supported; see the
[STM32U585 hardware guide](docs/stm32u585.md).

**Before your first run, review the tool paths in
[.vscode/settings.json](.vscode/settings.json) as described in step 3.**

## 1. Install the dependencies

Install [VS Code](https://code.visualstudio.com/) and the tools for your operating
system below. Install tools in permanent directories outside the project's
`build/` directory.

### Windows

| Tool | Recommended installation |
| --- | --- |
| CMake | [CMake 3.25 or newer](https://cmake.org/download/). Enable the installer's option to add CMake to `PATH`. |
| Ninja | Run the PowerShell command below. Version 1.13.2 has been tested. |
| Arm GNU Toolchain | Download and extract [Arm GNU Toolchain 14.3.Rel1 for Windows (`arm-none-eabi`)](https://developer.arm.com/-/media/Files/downloads/gnu/14.3.rel1/binrel/arm-gnu-toolchain-14.3.rel1-mingw-w64-i686-arm-none-eabi.zip). |
| QEMU | Follow the Windows instructions on [QEMU's official download page](https://www.qemu.org/download/#windows). Version 10.2.0 has been tested. |

Install Ninja in PowerShell:

```powershell
winget install --id Ninja-build.Ninja --exact --source winget
```

Set `ARM_SDK_INSTALL_DIR` permanently to the extracted Arm toolchain directory
containing `bin/arm-none-eabi-gcc.exe`. In PowerShell, replace the example path
with your installation and run:

```powershell
[Environment]::SetEnvironmentVariable('ARM_SDK_INSTALL_DIR', 'C:/Toolchains/arm-gnu-14.3', 'User')
```

Close **all VS Code windows** and reopen VS Code after installing the tools and
setting the environment variable.

### Linux: Ubuntu 24.04 LTS

Install the tools using Ubuntu's packages:

```sh
sudo apt update
sudo apt install cmake ninja-build gcc-arm-none-eabi libnewlib-arm-none-eabi qemu-system-arm gdb-multiarch
```

Add `export ARM_SDK_INSTALL_DIR=/usr` to your login environment, then log out and
back in before opening VS Code. Alternatively, launch VS Code from a terminal
where you have run that export. Configure Ubuntu's GDB in step 3.

## 2. Get and open the project

Clone the complete repository so that the shared libraries and examples are
included:

```sh
git clone https://github.com/percepio/demos.git
```

Open [Demo-FreeRTOS-QEMU.code-workspace](Demo-FreeRTOS-QEMU.code-workspace) from
the `Demo-FreeRTOS-QEMU` directory in VS Code. Accept the prompt to install the
recommended extensions: **Cortex-Debug**, **CMake Tools** and **C/C++**.

## 3. Review the paths in settings.json

Open [Demo-FreeRTOS-QEMU/.vscode/settings.json](.vscode/settings.json).
**Review every tool path and change it to match your own installation.**
QEMU is relative to your home directory; OpenOCD paths are absolute and may belong to another computer.

| Setting | What to check |
| --- | --- |
| `demo.qemuPath` | Home-relative QEMU executable, e.g. `AppData/Local/Programs/QEMU/10.2.0/qemu-system-arm.exe` on Windows. From `/home/you` on Linux, `../../usr/bin/qemu-system-arm` selects the packaged QEMU. |
| `demo.openOcdPath` | Path to OpenOCD. Only needed for the optional STM32 board. |
| `demo.openOcdScripts` | OpenOCD script directory containing `interface/` and `target/`. Only needed for STM32. |
| `cortex-debug.gdbPath.linux` | For the Ubuntu packages above, set this to `/usr/bin/gdb-multiarch` in the `.code-workspace` settings block (workspace scope). |

Use forward slashes in Windows JSON paths, for example:

```json
{
  "demo.qemuPath": "AppData/Local/Programs/QEMU/10.2.0/qemu-system-arm.exe"
}
```

Windows task/launch overrides prepend `${env:USERPROFILE}` to `demo.qemuPath`;
Linux uses `${userHome}`. No username is embedded in the project configuration. Keep this value relative; do not put
`${userHome}`, `${env:...}`, `%USERPROFILE%` or `~` inside it. Paths may contain
`..` for installations outside your home directory. OpenOCD settings stay absolute.

`freertos.armToolchainPrefix` selects the same prefix for builds and debugging.
It defaults to `arm-none-eabi`. This project setting works at folder level in a
multi-root workspace, unlike Cortex-Debug's own window-scoped prefix setting.

The Arm compiler and its bundled GDB are located through the
**`ARM_SDK_INSTALL_DIR` environment variable** set in step 1. CMake and Ninja
must be available on `PATH`. These locations are separate from the paths in
`settings.json`.

In a new VS Code terminal, check that both commands succeed:

```text
cmake --version
ninja --version
```

## 4. Build and run

1. Open **Run and Debug** and select **QEMU: Cortex-M3**.
2. Press **F5** to build and start debugging. Execution stops at `main`.
3. Press **F5** again to run the examples. Output appears in the **gdb-server**
   terminal and is saved to `qemu_last_session.log` in the project directory.
4. Press **Shift+F5** to stop.

**Ctrl+Shift+B** lets you select **QEMU: clean build** or **STM32U585: clean
build** for a full rebuild. F5 uses an incremental build.

To run without debugging, use **Tasks: Run Task > QEMU: run**. Exit that session
with **Ctrl+A, then X**. Run one QEMU session at a time; each session replaces
the log file.

## 5. View alerts in Percepio Detect

Install Percepio Detect using the `Percepio Detect Demo Guide.pdf` supplied with
the Detect package. See the [Detect setup guide](../README.md#percepio-detect-demos)
for download and client setup instructions.

1. Run the examples until alerts have been printed, then stop QEMU.
2. Copy `build/qemu-debug/Demo-FreeRTOS-QEMU.elf` to
   `demo-data/freertos-demo-v1.0.elf` in your Detect installation. Use the ELF
   from the same build that produced the log.
3. Set the receiver's input to the absolute path of `qemu_last_session.log`.
4. Start the Detect server and client, then run `receiver-demo.bat` on Windows
   or `receiver-demo.sh` on Linux from the Detect package. Open
   <http://localhost:8080> to view the alerts.

## Troubleshooting and other options

- **A tool cannot be found:** review `.vscode/settings.json`, `PATH` and
  `ARM_SDK_INSTALL_DIR`, then restart VS Code. Check the first CMake error;
  later Ninja or compiler errors may be consequences of an invalid toolchain path.
- **A previous toolchain path is still used:** run
  `cmake --fresh --preset qemu-debug` in the project directory, then build again.
- **`nic lan9118.0 has no peer`:** this warning is expected and can be ignored.

For physical hardware, follow the [STM32U585 guide](docs/stm32u585.md).
For command-line builds and further troubleshooting, see the
[setup reference](docs/setup-reference.md). Implementation details and validation
records are in the [development guide](docs/development-setup.md).
