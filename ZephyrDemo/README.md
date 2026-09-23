# Percepio Detect Zephyr demo

This project demonstrates Percepio Detect on Zephyr's `qemu_cortex_m3` target.
It is intended to support both Windows and Linux hosts. The current development
version has not yet been tested on Linux hosts.

## DFM test suite

Start with [`testing-docs/README.md`](testing-docs/README.md). It contains the
copy-and-paste commands for QEMU and physical hardware, prerequisites, output
locations, result interpretation, and links to the detailed specifications.
The executable entry point is `dfm_tests/run_suite.py`.

The Percepio module versions currently needed by the demo are provided under
`modules-staging`; see `WORK_IN_PROGRESS.txt` and `modules-staging/readme.txt`
before building.

## DFM retained-memory overlay

The normal board overlays do not reserve RAM for DFM retained memory. When
`CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY=y` is enabled, add the matching
retained-memory overlay explicitly to the build:

```text
west build -b <board> . -- -DEXTRA_DTC_OVERLAY_FILE=boards/<board>_retained.overlay
```

For example, use `boards/qemu_cortex_m3_retained.overlay` or
`boards/b_u585i_iot02a_retained.overlay`. These overlays reserve the top of
SRAM, reduce the ordinary `sram0` region accordingly, and provide the
`dfm_retained_memory`, `retainedmem0`, and `retention0` devicetree nodes used
by the DFM Zephyr port. Select only one retained-memory overlay and adjust its
addresses and sizes when porting it to another board.

The complete matching Kconfig settings are shown in
`dfm_tests/conf/retained.conf`. The test runner adds the regular overlay
automatically for `m3_retained`. The `_retained_8k.overlay` files are used only
by the intentionally undersized `m3_retained_8k` boundary tests and are not a
recommended production layout.

## Expected directory layout

The checked-in VS Code tasks use paths relative to `%USERPROFILE%` for the
Zephyr workspace, Python virtual environment, and SDK:

```text
%USERPROFILE%\zephyrproject\zephyr
%USERPROFILE%\zephyrproject\.venv\Scripts\python.exe
%USERPROFILE%\zephyr-sdk-1.0.1
```

If your Zephyr installation uses another layout or SDK version, update the
corresponding paths in `.vscode/tasks.json` and `.vscode/launch.json`.

The application also expects the shared usage examples as a sibling directory:

```text
<parent>\ZephyrDemo
<parent>\UsageExamples
```

## VS Code settings

- On Windows, the QEMU build in the currently used Zephyr SDK 1.0.1 depends on
  the MinGW-w64 runtime DLLs `libgcc_s_seh-1.dll` and `libwinpthread-1.dll`,
  which are not bundled with the SDK. QEMU loads the former through its bundled
  `libjpeg-8.dll` and `libpixman-1-0.dll`, and the former in turn loads the
  latter. Without both DLLs in the DLL search path, `qemu-system-arm.exe` exits
  in the Windows loader before QEMU can report an error.
- Set `zephyr.qemuWindowsRuntimePath` in `.vscode/settings.json` to a
  `mingw64\bin` directory containing compatible copies of these DLLs. Git for
  Windows is one possible source and normally provides them under
  `C:\Program Files\Git\mingw64\bin`. The current development workspace points
  there, but this is not a required or standard project configuration. Change
  the setting to wherever a compatible MinGW-w64 runtime is installed. Git
  itself is not a QEMU dependency.
- `zephyr.qemuWindowsRuntimePath` is not used on Linux hosts and may become
  unnecessary with a future SDK that bundles all required Windows runtime
  DLLs.
- `percepioTraceExporter.tracealyzerPath` is intentionally empty. Configure the
  Tracealyzer installation through the Trace Exporter extension.

## QEMU console log

The `Zephyr: QEMU GDB server` task uses QEMU's character-device hub to display
the guest console in the terminal and write it to `qemu_last_session.log` in
this project directory. This requires QEMU 10 or newer. QEMU truncates the file
at the start of each session.
After QEMU exits, the launcher normalizes Windows `CRCRLF` sequences to `CRLF`
without decoding or re-encoding the log contents. The generated log is ignored
by Git.

The optional `Detect: Load alerts` task runs the project-local
`load-zephyr-alerts.bat`. With no arguments it detects the most recent suite
type from `dfm_test_artifacts`: it loads every `Build-*\qemu.log` after a QEMU
run or every `Build-*\serial.log` after a physical-board run. Because
`run_suite.py` recreates the artifact root for every invocation, the two log
types are not normally mixed. A mixed tree is rejected as ambiguous.

Manual F5 debugging is also supported. If `qemu_last_session.log` is newer
than every file below `dfm_test_artifacts`, the loader treats it as the latest
run and loads only that log. It uses the matching live debug image at
`build\zephyr\zephyr.elf`; it does not create, replace, or mix files in the
suite artifact tree. The F5 build adds `.vscode/f5-debug.conf`, so the manual
firmware reports Revision `Manual-QEMU` without changing the default
application configuration or the suite's `Build-*` revisions.

The loader sends all selected records through the Detect Receiver, resetting
and restarting the Detect server and client only once. Each per-image log is
listed before Detect state is changed.

After a successful complete test-suite run, `run_suite.py` now performs this
full load automatically with `DETECT_CLIENT_TEXT_OUTPUT=1` and
`--suite-artifacts`. Focused, failed, or interrupted runs ask first. The Client
stores `alert-metadata-*.txt` from each Receiver-created alert header, and
exports every payload synchronously as an `eventlog-*.txt` or `coredump-*.txt`
in the matching build artifact directory. The suite then asks whether to
start a read-only Agentic payload review. After the synchronous text export,
the loader also starts a fresh Client in normal interactive mode with the same
alert directory and ELF mapping, so payloads remain available for manual
review from the dashboard. The Agentic review starts one independent
Codex process with a fresh context window per test, one at a time in manifest
order. A final Codex process summarizes the completed diagnostic report; exact
PASS/FAIL statistics are printed and appended to `dfm_test_run.log`. Pass
`--skip-payload-processing` to suppress post-suite Detect work. The
full workflow is documented in
[`testing-docs/automated_payload_review.md`](testing-docs/automated_payload_review.md).

For Receiver troubleshooting without inspecting, stopping, cleaning, or
starting the Detect server or client, use:

```bat
load-zephyr-alerts.bat --receiver-only
```

This mode still clears and recreates the project-local `alert-files` directory.

`run_suite.py` has already copied every built image to
`dfm_test_artifacts\<Revision>\zephyr.elf`. The Client resolves the correct ELF
for each alert through the alert's `Revision` metadata, using
`../../demos/ZephyrDemo/dfm_test_artifacts/${revision}/zephyr.elf`. This also
allows all selected per-image logs to be loaded together while every alert
still resolves the exact matching firmware image. For a newer manual F5 log,
the loader instead gives the Client the static path
`../../demos/ZephyrDemo/build/zephyr/zephyr.elf`; Revision substitution is not
needed when one current manual image produced the whole log.

Automatic detection is normally sufficient. To load only one physical-board
capture instead, pass it explicitly:

```bat
load-zephyr-alerts.bat ^
  --serial-log dfm_test_artifacts\Build-M3-Os\serial.log ^
  --device-name b_u585i_iot02a
```

The script expects Detect at `C:\src\DetectRepo`. Use
`load-zephyr-alerts.bat --dry-run` to validate all configured paths without
changing files, processes, containers, or Docker data. A custom
`--device-name` applies to every selected log. Options can be combined, for
example `load-zephyr-alerts.bat --receiver-only --dry-run`.

## Physical boards

The DFM suite can also build, flash, and capture a physical Zephyr board's COM
port directly from Python; VS Code Serial Monitor and session-specific log
filenames are not needed. See
[`testing-docs/running_on_real_board.md`](testing-docs/running_on_real_board.md).
