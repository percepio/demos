# Percepio Demo Library (work in progress)
A collection of demos for Percepio Tracealyzer and Percepio Detect

## 01_tracerecorder_kernel_tracing.c
Demonstrates TraceRecorder tracing with FreeRTOS. The demo runs a small FreeRTOS application for a few seconds. Halt the debugger at any time to save a snapshot trace.

### Capturing trace snapshots with GDB
If using gcc/gdb tools, open the debug console in your IDE, where you can type in GDB commands, and run the following gdb command:
```
dump binary value trace.bin *RecorderDataPtr
```
If using VS Code, you need to add ‘-exec’ before the gdb command.
```
-exec dump binary value trace.bin *RecorderDataPtr
```
The resulting trace.bin file is typically found in the root of the build folder, unless a different path has been specified. Open trace.bin in your Tracealyzer application by selecting ‘File –> Open –> Open File’.

For more frequent use, you can configure your Tracealyzer application to automate the GDB trace capture, using the “Take Snapshot” option. For setup instructions, see “Using the Tracealyzer GDB integration” at https://percepio.com/tracealyzer/gettingstarted/snapshots-eclipse-gdb/.

### Capturing trace snapshots with IAR Embedded Workbench
See the "snapshot" instructions at https://percepio.com/tracealyzer/gettingstarted/iar/.
