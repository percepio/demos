# Percepio FreeRTOS Demo for QEMU MPS2

This is a standalone bare-metal FreeRTOS demo for the QEMU
`mps2-an385`/Cortex-M3 machine. It exercises the shared Percepio examples,
TraceRecorder, DFM, and CrashCatcher without using the Zephyr build system,
west, Kconfig, or devicetree.

## Source layout and requirements

The default source layout is:

- `../UsageExamples` — shared demo runner and examples.
- `../PercepioLibs/TraceRecorder` — TraceRecorder 4.11.0.
- `../PercepioLibs/CrashCatcher` — CrashCatcher.
- `C:/src/DemosRepo/ZephyrDemo/modules-staging/modules/debug/percepio/DFM` —
  the staging DFM 2.1.0 sources, including `dfmUtility.c`.
- `third_party/FreeRTOS-Kernel` — the required FreeRTOS-Kernel `V11.3.1`
  sources, public headers, GCC ARM_CM3 port, and `heap_4.c`.

The project has been tested on Windows with CMake, Ninja, QEMU 10.0.2, and the
Zephyr SDK 1.0.1 ARM GCC/GDB toolchain. All required FreeRTOS files are checked
in, so configuring and building do not download source code.

To use a different ARM toolchain location:

```powershell
$env:ARM_ZEPHYR_EABI_TOOLCHAIN_ROOT = 'D:\sdk\gnu\arm-zephyr-eabi'
```

The external source locations are independent CMake cache paths:

- `USAGE_EXAMPLES_DIR`
- `TRACERECORDER_DIR`
- `DFM_DIR`
- `CRASHCATCHER_DIR`

Override any of them with `-D<NAME>=<PATH>` if the repositories are checked out
under a different root.

## Build and run

```powershell
# Required once for a fresh build directory:
cmake --preset debug

# Normal build and run:
cmake --build --preset debug
cmake --build --preset debug --target run
```

CMake must generate Ninja's local build files once for a fresh checkout. The
regular VS Code build and debug flows do not run a separate configure task.
CMake may still regenerate those local files automatically after a
`CMakeLists.txt` change; this is local and performs no download.

The output files are:

- `build/debug/Demo-FreeRTOS-QEMU.elf`
- `build/debug/Demo-FreeRTOS-QEMU.map`

The `run` target starts QEMU in the terminal. DFM uses its serial cloud port,
so alert demos can produce a large amount of machine-readable alert, trace,
and core-dump data. Stop QEMU with Ctrl+C.

The QEMU path can be overridden with the `-Qemu` parameter to
`cmake/Invoke-Qemu.ps1`. The supplied scripts also add
`C:\Program Files\Git\mingw64\bin` to `PATH` when that directory exists.

## Build and debug from VS Code

Open this directory as the VS Code workspace and install the recommended
Cortex-Debug extension.

- `Ctrl+Alt+B` runs **CMake: clean build (debug)**.
- **CMake: build (debug)** provides a normal incremental build through
  **Tasks: Run Task**.
- `F5` runs **FreeRTOS in QEMU (GDB)**. It stops the previous project QEMU,
  performs an incremental build, starts a fresh GDB server on port 1234, and
  connects Cortex-Debug using the Zephyr SDK GDB.

The debug launcher gives QEMU a separate
`build/debug/Demo-FreeRTOS-QEMU.qemu.elf`. This prevents a running QEMU process
from locking the build output on Windows. QEMU is tracked by a project PID file,
and the stop script validates both PID and executable path before terminating
it.

During debugging, UART/`printf` output is shown in the terminal named
**QEMU: watch serial output** and is also saved to `qemu-gdb.log`. QEMU errors
are written to `qemu-gdb.error.log`. The serial port uses a file chardev rather
than `-serial stdio`, keeping the VS Code terminal input independent of the GDB
stub.

Both normal runs and debug sessions use:

```text
-icount shift=6,align=on,sleep=on -rtc clock=vm
```

This synchronizes QEMU virtual time with wall-clock time, so FreeRTOS ticks and
`vTaskDelay()` follow real time instead of running as fast as the host permits.

## Load captured alerts into Detect

The VS Code task **Detect: Load alerts** runs `load-freertos-alerts.bat`. Run it
after QEMU has produced the alerts that you want to inspect; it does not start
or stop QEMU.

Inputs:

- `qemu-gdb.log` — QEMU UART output containing the `[[ DevAlert Data ... ]]`
  blocks.
- `build/debug/Demo-FreeRTOS-QEMU.elf` — symbols and executable image for the
  captured firmware.
- The Detect installation below `C:\src\DetectRepo`.

Outputs:

- Extracted alert data in this project's `freertos-test` directory.
- A copy of the current ELF at `freertos-test/image.elf`, replacing any older
  copy.
- A restarted Detect server and a newly launched Detect client configured to
  use those files.

The script validates all paths before changing anything. It then stops the
Detect server, invokes the server cleanup command, stops any running Detect
Python client, converts the QEMU text log with `percepio-receiver`, copies the
ELF, starts the server, and finally starts the Windows client. To validate all
paths and preview these actions without changing external state, run:

```powershell
.\load-freertos-alerts.bat --dry-run
```

### Optional Alt+D shortcut

VS Code stores keyboard shortcuts in the user profile, while the task and
loader script are project-local. To bind this task to `Alt+D`:

1. Run **Preferences: Open Keyboard Shortcuts (JSON)** from the Command Palette.
2. Add the following entry to the JSON array:

```json
{
    "key": "alt+d",
    "command": "workbench.action.tasks.runTask",
    "args": "Detect: Load alerts"
}
```

The same global binding can be used by other workspaces that provide a local
task with the exact label **Detect: Load alerts**.

## Implementation notes

- MPS2 RAM spans `0x20000000`–`0x203fffff` (4 MiB). The `.noinit` section is
  preserved across the QEMU resets used to advance between demos.
- MPS2 TIMER0 supplies the free-running 32-bit timestamp required by DFM;
  FreeRTOS keeps SysTick exclusively for its scheduler tick.
- TraceRecorder uses a 10 KiB overwrite-mode RingBuffer stream port. DFM uses
  the serial cloud port and dummy storage port.
- FreeRTOS-Kernel is built directly from the minimal source subset under
  `third_party/FreeRTOS-Kernel`; CMake does not use `FetchContent`.
- TraceRecorder critical sections use the Cortex-M `PRIMASK` primitive because
  trace hooks can execute from PendSV.
- The debug build uses `-O0`, `-g3`, frame pointers, and strong stack protection
  to provide useful call stacks and exercise the stack-corruption demo.
- The staging DFM currently builds with compiler warnings in
  `dfmTaskMonitor.c` and `dfmUtility.c`. Those external staging sources are not
  modified or their warnings hidden by this project.

The demo covers the integrated example flow and serialized DFM output. The
complete DFM test suite and the Detect backend itself are outside this project.
