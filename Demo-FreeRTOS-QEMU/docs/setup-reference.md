# Setup reference

For the recommended VS Code setup, start with the [README](../README.md).
This reference covers alternative installation methods, command-line use and
additional troubleshooting.

## Alternative installations

### Ninja on Windows without WinGet

Download the Windows archive for your architecture from
[Ninja's releases](https://github.com/ninja-build/ninja/releases), extract it to
a permanent directory, and add that directory to your user `PATH`. Close all
VS Code windows and reopen the project, then check `ninja --version`.

### QEMU package verification

Follow the Windows instructions on [QEMU's official download page](https://www.qemu.org/download/#windows),
which links to Stefan Weil's Windows packages. Verify your chosen installer
against the matching SHA-512 file supplied by its publisher.
Keep the complete installation together, including its DLLs and resources.
Install QEMU and the compiler outside the project's `build/` directory.

### Other Arm toolchains

The project uses an `arm-none-eabi` GNU toolchain with Newlib, Binutils and GDB.
A complete standalone toolchain for Linux is available from
[Arm](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain).
Set `ARM_SDK_INSTALL_DIR` to the directory containing `bin/`. When using its
bundled GDB, remove the Ubuntu-specific `cortex-debug.gdbPath.linux` override.
A Picolibc-only toolchain is not a drop-in replacement.

## Check individual tools

Run `cmake --version`, `ninja --version` and the QEMU executable configured in
`.vscode/settings.json` with `--version`. Run that QEMU executable with
`-machine help` and check that the list includes `mps2-an385`.

Check the selected compiler on Windows:

```powershell
& "$env:ARM_SDK_INSTALL_DIR/bin/arm-none-eabi-gcc.exe" --version
```

On Linux:

```sh
"$ARM_SDK_INSTALL_DIR/bin/arm-none-eabi-gcc" --version
```

If CMake reports missing compilers and Ninja together, read the first error.
An invalid `ARM_SDK_INSTALL_DIR` can stop configuration before Ninja is selected.
Setting an environment variable inside an integrated terminal does not change
the environment of the running VS Code debugger.

## Command-line builds

From the `Demo-FreeRTOS-QEMU` directory:

```text
cmake --preset qemu-debug
cmake --build --preset qemu-debug
cmake --build --preset qemu-debug --target run
```

Exit QEMU with **Ctrl+A, then X**. If QEMU is not on `PATH`, pass its location
when configuring, for example:

```text
cmake --preset qemu-debug -DQEMU_EXECUTABLE="C:/Program Files/qemu/qemu-system-arm.exe"
```

VS Code's Windows task override passes `${env:USERPROFILE}/${config:demo.qemuPath}`
to CMake; Linux uses `${userHome}/${config:demo.qemuPath}`. The setting is home-relative. `freertos.armToolchainPrefix` supplies the build/debug prefix.
Command-line configuration does not read VS Code settings.

For a clean rebuild, use `cmake --build --preset qemu-debug --clean-first`.
After changing the toolchain location or prefix, reconfigure with
`cmake --fresh --preset qemu-debug`. For STM32, use `stm32u585-debug` instead.

## Manual debugging and local configuration

- `cmake --build --preset qemu-debug --target debugserver` starts QEMU paused,
  listening on `127.0.0.1:1234`. VS Code's F5 configuration selects its own port.
- CMake Tools' configure preset controls its build buttons and IntelliSense.
  Select the matching preset when switching boards. F5 uses the explicit target
  chosen in Run and Debug.
- Machine-specific CMake overrides can go in an untracked
  `CMakeUserPresets.json`. Task command-line arguments take precedence over
  cached values.
- Use separate checkouts or build trees for native Windows and Linux/WSL.
  CMake caches host-specific absolute paths.
- If Windows displays a firewall prompt, local debugging does not require
  inbound access from other computers.
