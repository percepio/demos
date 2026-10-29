# Percepio Detect for Zephyr

Run Percepio Detect and Tracealyzer examples in QEMU without a physical board,
or on a supported Arm Cortex-M board. The demo cycles through tracing, data
and state logging, crash and custom alerts, stack corruption detection, latency
monitoring and CPU usage monitoring. **Deliberate faults and resets are part of
the demo.** See the [repository guide](../README.md) for features and screenshots.

The VS Code workflow matches the FreeRTOS demo: open the workspace, review
settings, press F5, and view the captured output in Detect. Zephyr continues to
use its own Python environment, west, SDK, Kconfig and devicetree.

## 1. Install the dependencies

Install [VS Code](https://code.visualstudio.com/) and complete the
[Zephyr getting started guide](https://docs.zephyrproject.org/latest/develop/getting_started/index.html)
for **Windows or Linux**, including host dependencies, a west workspace, its
Python virtual environment, and a compatible **Zephyr SDK** with the Arm GNU
toolchain. Keep all tools outside this project's disposable `build/` directory.
CMake and Ninja must be on `PATH` when opening VS Code.

For the supplied QEMU configuration, install `qemu-system-arm` using the
[QEMU download instructions](https://www.qemu.org/download/), or use a working
Zephyr SDK QEMU installation. Set its executable path in step 3. The Windows
setup uses a separate QEMU 10.2.0 installation; a QEMU hub is no longer required.
Other Zephyr boards may require the SDK's matching emulator and host tools.

Earlier validation used Zephyr 4.5.0-rc1 (`ca10f7fc7a5b`) and SDK 1.0.1;
the demo has also been verified with Zephyr 4.4. See the
[validation record](docs/development-setup.md) for the checks performed on this
workflow. Physical-board probe tools are optional; see the
[STM32U585 guide](docs/stm32u585.md).

After installing tools or changing environment variables, close **all VS Code
windows** and reopen them so tasks and debugging inherit the same environment.

## 2. Get and open the project

Clone the complete repository, including `UsageExamples` and `PercepioLibs`:

```sh
git clone https://github.com/percepio/demos.git
```

Open [ZephyrDemo.code-workspace](ZephyrDemo.code-workspace) in VS Code and install
the recommended **Cortex-Debug** and **C/C++** extensions. The workspace includes
the application and shared libraries. Tasks and F5 work with a library file active.

## 3. Review the paths in settings.json

Open [.vscode/settings.json](.vscode/settings.json).
**Review every local path and change it to match your installation.** The checked-in
installation subdirectories may differ on another machine. `demo.qemuPath` and
the three Zephyr paths below are **relative to your home directory**, with forward
slashes. Windows task/launch overrides prepend `${env:USERPROFILE}`; Linux uses
`${userHome}`. Do not put
`${userHome}`, `${env:...}`, `%USERPROFILE%` or `~` inside these setting values.
OpenOCD paths remain absolute.

| Setting | What to check |
| --- | --- |
| `demo.qemuPath` | Home-relative QEMU executable, e.g. `AppData/Local/Programs/QEMU/10.2.0/qemu-system-arm.exe`. On Linux with home under `/home`, `../../usr/bin/qemu-system-arm` selects the packaged QEMU. Used for both QEMU builds/runs and F5. |
| `demo.openOcdPath`, `demo.openOcdScripts` | Optional ST OpenOCD executable and directory containing `interface/` and `target/`. |
| `zephyr.pythonPath` | Home-relative west Python: `zephyrproject/.venv/Scripts/python.exe` on Windows or `zephyrproject/.venv/bin/python` on Linux. |
| `zephyr.base` | Home-relative Zephyr checkout, normally `zephyrproject/zephyr`. |
| `zephyr.sdkInstallDir` | Home-relative SDK root, e.g. `zephyr-sdk-1.0.1`. Tasks set the resolved `ZEPHYR_SDK_INSTALL_DIR` and `ZEPHYR_TOOLCHAIN_VARIANT=zephyr`. |
| `zephyr.armToolchainSubdir` | Arm debugger tools relative to that SDK: `gnu/arm-zephyr-eabi/bin` for SDK 1.0.1; typically `arm-zephyr-eabi/bin` for SDK 0.17.x. |
| `zephyr.armToolchainPrefix` | `arm-zephyr-eabi` for the SDK's Arm GDB, objdump and nm. The launch entries explicitly select these tools, independently of global Cortex-Debug tool settings. |

Keep `zephyr.percepioSource` set to **`local`** for this release. No virtualenv
activation is needed for VS Code tasks: they invoke the configured Python directly.
In a new VS Code terminal, check `cmake --version` and `ninja --version`.

## 4. Build and run

1. In **Run and Debug**, select **QEMU: Cortex-M3**.
2. Press **F5** to build incrementally and start debugging at `main`.
3. Press **F5** again to run. Output appears in the **gdb-server** terminal and
   is saved to `qemu_last_session.log` in this project directory.
4. Press **Shift+F5** to stop and release QEMU. Use the debugger's Restart action
   to reset and run to `main` again.

**Ctrl+Shift+B** offers **QEMU: clean build**, **STM32U585: clean build** and
**Zephyr: clean build**. The last asks for any complete Zephyr board target,
including revisions and qualifiers. Use **Tasks: Run Task > Zephyr: list boards**
to discover boards from your checkout. Feature adaptations may be needed outside
Cortex-M; see [building other boards](docs/setup-reference.md#other-boards).

To run without debugging, select **Tasks: Run Task > QEMU: run**. Exit with
**Ctrl+A, then X**. Both run and debug replace the same log; use one QEMU session
at a time. After QEMU exits, a small Python step collapses repeated CRs in the
text log. Stop the session before passing the completed log to Detect.
With the default settings, the QEMU ELF is
`build/qemu_cortex_m3/local-debug/zephyr/zephyr.elf`.

## 5. View alerts in Percepio Detect

Install Detect using the `Percepio Detect Demo Guide.pdf` supplied with the
package. See the [Detect setup guide](../README.md#percepio-detect-demos).

1. Run the examples until alerts have been printed, then stop QEMU.
2. Copy `build/qemu_cortex_m3/local-debug/zephyr/zephyr.elf` to
   `demo-data/zephyr-demo-v1.0.elf` in your Detect installation. Use the ELF from
   the exact build that produced the log. Different source/profile settings
   change the build directory; the receiver filename follows
   `CONFIG_PERCEPIO_DFM_CFG_FIRMWARE_VERSION` in [prj.conf](prj.conf).
3. Set the receiver's input to the absolute path of `qemu_last_session.log`.
4. Start the Detect server and client, then run `receiver-demo.bat` on Windows
   or `receiver-demo.sh` on Linux. Open <http://localhost:8080> to view alerts.

## Troubleshooting and other options

- **A tool cannot be found:** review `.vscode/settings.json` and `PATH`. Read the
  first configuration error; later compiler/Ninja errors may be consequences.
- **An old SDK or checkout is used:** choose a new `zephyr.buildProfile`, then
  clean build. The previous single `build/zephyr/zephyr.elf` layout is no longer used.
- **GDB is incorrectly named `arm-none-eabi-gdb`:** use the updated launch entries
  and `zephyr.armToolchainPrefix=arm-zephyr-eabi`. Cortex-Debug 1.12.1's own
  `cortex-debug.armToolchainPrefix` has window scope: in a multi-root workspace,
  putting it in a folder's `.vscode/settings.json` does not override the workspace
  or user value. The supplied entries use project settings and explicit tool paths.
- **QEMU reports missing Windows DLLs:** select a working QEMU distribution in
  `demo.qemuPath`. The older SDK 1.0.1 QEMU required MinGW runtime DLLs on some
  machines; the current setup uses a separate installation with its own DLLs.
- **Navigation uses another board:** set `zephyr.intelliSenseBoard` to the complete
  board target you built. C/C++ reads that directory's `compile_commands.json`.
- **`nic ... has no peer`:** this QEMU warning about the emulated NIC is expected.

See the [STM32U585 guide](docs/stm32u585.md) for hardware, the
[setup reference](docs/setup-reference.md) for command-line builds and configuration,
and the [development guide](docs/development-setup.md) for design and validation.
