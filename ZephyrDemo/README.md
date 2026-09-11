# Percepio Detect Zephyr demo

This project demonstrates Percepio Detect on Zephyr's `qemu_cortex_m3` target.
It is intended to support both Windows and Linux hosts. The current development
version has not yet been tested on Linux hosts.

The Percepio module versions currently needed by the demo are provided under
`modules-staging`; see `WORK_IN_PROGRESS.txt` and `modules-staging/readme.txt`
before building.

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

The optional `Detect: Reload Zephyr test from QEMU log` task still expects the
private helper `reload-zephyr-test.bat` in a sibling `DetectRepo` two levels
above this project. It is a local testing convenience and is not required to
build or run the standalone demo.
