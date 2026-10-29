# Zephyr setup reference

## Terminal environment

Use the same Python, checkout and SDK as VS Code. Example Windows paths:

```powershell
& "$env:USERPROFILE/zephyrproject/.venv/Scripts/Activate.ps1"
$env:ZEPHYR_BASE = "$env:USERPROFILE/zephyrproject/zephyr"
$env:ZEPHYR_SDK_INSTALL_DIR = "$env:USERPROFILE/zephyr-sdk-1.0.1"
$env:ZEPHYR_TOOLCHAIN_VARIANT = "zephyr"
```

Linux, after completing Zephyr's host and SDK installation:

```sh
source ~/zephyrproject/.venv/bin/activate
export ZEPHYR_BASE="$HOME/zephyrproject/zephyr"
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-1.0.1"
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
```

Adapt these paths to your installations. The editor tasks set these variables
directly; a terminal export does not modify an already-running editor's environment.

In the editor's `settings.json`, QEMU and Zephyr paths are relative to your home
directory. For example `zephyr.sdkInstallDir` is `zephyr-sdk-1.0.1`; tasks and
launch entries use `${env:USERPROFILE}/${config:zephyr.sdkInstallDir}` on Windows
and `${userHome}/${config:zephyr.sdkInstallDir}` on Linux. VS Code expands
both variables directly, without relying on nested expansion in a setting value.
Paths may contain `..` when a tool is outside your home directory. For example,
from `/home/you`, `demo.qemuPath=../../usr/bin/qemu-system-arm` resolves to the
system QEMU. OpenOCD settings are still absolute. Terminal commands and CMake
cache variables still accept ordinary absolute paths or commands on `PATH`.

## QEMU from a terminal

From `ZephyrDemo/`, with CMake and Ninja on `PATH`:

```text
python -m west build -b qemu_cortex_m3 -p always -d build/qemu_cortex_m3/local-debug . -- -DDEMO_PERCEPIO_SOURCE=local
python -m west build -d build/qemu_cortex_m3/local-debug -t run_logged
```

`run_logged` captures console output in `qemu_last_session.log`. Exit with Ctrl+A, X;
the completed text log is then normalized to remove repeated CRs before LF.
Use `-DQEMU=/absolute/path/to/qemu-system-arm` on the first command to select
another QEMU executable, as the VS Code tasks do. Without this override, Zephyr
discovers QEMU using its normal SDK/`QEMU_BIN_PATH` rules.
Zephyr's original `run` target is also available, without this demo's log capture.

For a terminal GDB session, use `-t debugserver_logged` and connect the SDK's
Arm GDB to `127.0.0.1:1234` with the matching ELF. This target binds loopback and
waits for GDB. F5 uses Cortex-Debug's allocated port instead. Use `monitor quit`
from GDB to end the terminal debug server, or Ctrl+A, X in its terminal.

## Other boards

**Zephyr: build** and **Zephyr: clean build** accept a free-text complete board
target, with the same meaning as `west build -b`. **Zephyr: list boards** lists
boards from the selected checkout. Consult the board's documentation for
revisions/qualifiers; examples include `mps2/an385` and `board@revision/soc/variant`.
No preset or task edit is needed just to compile another board.

Output goes to `build/<complete-board-target>/<percepioSource>-<buildProfile>/`.
Slashes in qualifiers become subdirectories and `@revision` remains part of the
path, so different complete board targets have separate caches. For example,
`mps2/an385` with the defaults uses `build/mps2/an385/local-debug/`.
Keep profile names to simple directory names, without slashes.

Use the selected board's native `west flash`, `west debug` or `west build -t run`
where supported. These retain Zephyr's architecture/compiler/emulator/runner
selection. Generic tasks do not force an Arm compiler or QEMU executable.
The supplied F5 entries are specifically for QEMU Cortex-M3 and STM32U585;
other targets need a matching debugger configuration/extension or a Zephyr runner.

The demo defaults and Percepio integration currently target **Arm Cortex-M**.
An unrestricted board input does not guarantee the demo works on every Zephyr
architecture. Other boards may need console or retained-memory overlays,
Kconfig fragments, or feature/port adaptations. For example, `CONFIG_CORTEX_M_DWT`
and exception information in `prj.conf` are Cortex-M-specific. Distinguish these
application limitations from a board-selection or SDK error. Install the selected
architecture's compiler in the SDK before building it.

## Build profiles and source selection

All build tasks pass these settings explicitly, including pristine builds:

| Setting | CMake input |
| --- | --- |
| `zephyr.percepioSource` | `DEMO_PERCEPIO_SOURCE` (`local` or `upstream`) |
| `zephyr.extraConfFile` | `EXTRA_CONF_FILE`, empty or semicolon-separated Kconfig fragments |
| `zephyr.extraDtcOverlayFile` | `EXTRA_DTC_OVERLAY_FILE`, empty or semicolon-separated overlays |

Paths are relative to the application unless absolute. Zephyr still automatically
discovers matching board `.conf` and `.overlay` files. Additional overlays augment
that discovery; the tasks do not force the QEMU overlay on another board.

**Change `zephyr.buildProfile` when changing fragments, overlays, SDK or checkout**
to keep distinct configurations in distinct output directories. Then choose a
clean build. F5 and the ELF path automatically use the same profile/source
settings. A pristine build is `west build -p always`; F5 uses `-p auto` and normal
incremental rebuilding. No saved target file or shared cross-board cache is used.
Ctrl+Shift+B selects its task independently of the Run and Debug dropdown.

`local` uses `../PercepioLibs` through `modules/percepio`, including its Kconfig.
`upstream` uses the module in the west workspace. **Use `local` for this release**:
the required library changes are not yet available upstream. No library copying
into the Zephyr workspace is needed. Terminal builds must pass the same selection:

```text
python -m west build -b qemu_cortex_m3 -p always -d build/qemu_cortex_m3/upstream-debug . -- -DDEMO_PERCEPIO_SOURCE=upstream
```

## Firmware and debug bundles

[prj.conf](../prj.conf) defaults to a 4 KiB trace RingBuffer, serial DFM alerts,
and immediate core dump transmission through Zephyr's core dump backend.
See [boards/](../boards/) for console and retained-memory examples. For retained
memory, use one matching `*_retained.overlay` with suitable DFM Kconfig settings;
it reserves the top of SRAM and reduces the ordinary `sram0` region. Adjust its
addresses for other boards. Give that configuration a distinct build profile.

The existing `-fdebug-prefix-map=<repo-root>=src` keeps repository source paths
portable for Detect. F5 maps `src` back to the repository from its fixed project
working directory. Zephyr kernel sources mapped to `.` are mapped back to
the resolved home directory plus `zephyr.base/kernel`. C/C++ uses the selected board's compile database;
`zephyr.intelliSenseBoard` controls navigation independently of F5.
The optional `.clangd` configuration points at the default QEMU compile database;
clangd users should change that path when selecting another board/profile.

Copy the ELF from the same board/source/profile/build as the captured log into
Detect's `demo-data/zephyr-demo-v1.0.elf`. Give firmware revisions unique names
when collecting alerts from several builds. Configure Tracealyzer's installation
path separately if using the Percepio Trace Exporter extension.

## References

- [Zephyr host setup](https://docs.zephyrproject.org/latest/develop/getting_started/index.html)
- [Zephyr SDK and compatibility](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html)
- [west build, pristine builds and runners](https://docs.zephyrproject.org/latest/develop/west/build-flash-debug.html)
- [Board targets and qualifiers](https://docs.zephyrproject.org/latest/hardware/porting/board_porting.html#board-terminology)
