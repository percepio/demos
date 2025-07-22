# Percepio Demo Library (work in progress)
A collection of demos for Percepio Tracealyzer and Percepio Detect

## TraceRecorder demos
Percepio TraceRecorder is an event tracing library designed for embedded software, targeting 32-bit microcontrollers and up to 64-bit multicore SoCs. The traces are intended for Percepio Tracealyzer and related tools. It is also used by Percepio Detect.

The following demos demonstrate TraceRecorder tracing with FreeRTOS, using the RingBuffer setup. They run in sequence. To view the resulting traces, you may halt the demo at any point using the debugger and save a snapshot, as [described below](#viewing-snapshot-traces-from-tracerecorder).

### 01_tracerecorder_kernel_tracing
Demonstrates RTOS tracing with Percepio TraceRecorder, including queue and mutex usage with custom object names. 
![Screenshot from demo 01](Screenshots/01.png)


## Percepio Detect demos

## Viewing snapshot traces from TraceRecorder
TraceRecorder supports multiple ways of outputting the data, both live streaming and by snapshots. You configure this by including the desired [streamport module](https://github.com/percepio/TraceRecorderSource/tree/main/streamports) module in your project. This project is already configured for the RingBuffer streamport, that stores the trace in target RAM. The trace data can be saved as snapshots using the debugger connection, as described below. Then open the resulting file in your Tracealyzer application.

### Using STM32CubeIDE and other GCC-based tools
* Start a debug session in your IDE and open the debug console, or launch a gdb session from the command line.
* Halt the execution sometime after the xTraceEnable call (e.g. at a breakpoint).
  - If using an Eclipse-based IDE, or using gdb from the command line, run the following command:
  ```
  dump binary value trace.bin *RecorderDataPtr
  ```
  - If using VS Code, you need to add ‘-exec’ before the gdb command, like this:
  ```
  -exec dump binary value trace.bin *RecorderDataPtr
  ```
* The resulting "trace.bin" is typically found in the project folder. Open trace.bin in your Tracealyzer application by selecting ‘File –> Open –> Open File’ or, if using Windows, you can drag and drop the file to your Tracealyzer application.

* For more frequent use, you can configure your Tracealyzer application to automate the GDB trace capture, using the “Take Snapshot” option. For setup instructions, see “Using the Tracealyzer GDB integration” at https://percepio.com/tracealyzer/gettingstarted/snapshots-eclipse-gdb/.

### Using IAR Embedded Workbench
Locate `save_trace_buffer.mac` in the EWARM project folder. This IAR macro file will save the contents of the trace buffer to a host file.

* Add the macro file under Options -> Debugger -> Use Macro File(s).
* When in a debug session, open View -> Macros -> Debugger Macros and look for “save_trace_buffer”.
  - In the “Debugger Macros” view, right-click on your macro and select “Add to Quicklaunch window”. 
  - Double-click on the “refresh” icon in the Quicklaunch window to save the trace.

See also https://percepio.com/tracealyzer/gettingstarted/iar/.
