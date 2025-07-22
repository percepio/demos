# Percepio Demo Library
A collection of demos for [Percepio Tracealyzer](https://percepio.com/tracealyzer) and [Percepio Detect](https://percepio.com/detect).

Percepio TraceRecorder is an event tracing library designed for embedded software, targeting 32-bit microcontrollers and up to 64-bit multicore SoCs. The traces are intended for [Percepio Tracealyzer](https://percepio.com/tracealyzer) and related tools.

[Percepio Detect](https://percepio.com/detect) offers systematic observability for test suites, e.g. in CI pipelines, including TraceRecorder traces and core dumps when abnormal behavior is detected. The target-side library DFM allows for custom alerts from the code, and captures crashes (hard faults) automatically on Arm Cortex-M devices. DFM also provides advanced monitoring features for detecting abnormal behavior from side-effects on response times (stopwatches) and CPU time usage per thread (TaskMonitor).

## TraceRecorder demos
The following demos demonstrate TraceRecorder tracing with FreeRTOS, using the RingBuffer setup. They run in sequence and progress is displayed in the console. To view the demo log:

* If using STM32CubeIDE, connect with a serial terminal application to the STLink Virtual COM port (115200 baud).

* If using IAR Embedded Workbench, the printf log is displayed in the Terminal I/O window, found in the View menu when in Debug mode. In case you don't see any output, you probably need to enable printf redirection to SWO. This is found under Options -> General Options -> Library Configuration. In the "Library low-level interface implementation" panel, select "Semihosted" and "Via SWO".

### 01_tracerecorder_kernel_tracing.c
Source code: [UsageExamples/01_tracerecorder_kernel_tracing.c](UsageExamples/01_tracerecorder_kernel_tracing.c).

Demonstrates RTOS tracing with Percepio TraceRecorder. The demo creates three threads that are using a queue and a mutex. No instrumentation is needed in the application code. With TraceRecorder properly integrated, hooks in the RTOS kernel are configured to call the right tracing functions in TraceRecorder on key events such as task-switches and kernel API calls. This assuming the [integration guide](https://percepio.com/getstarted/latest/html/) has been followed.

![Screenshot from demo 01](Screenshots/01.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

Note that the queue and mutex objects have been given custom object names as [described here](https://percepio.com/naming-your-kernel-objects/). 

### 02_tracerecorder_data_logging.c
Source code: [UsageExamples/02_tracerecorder_data_logging.c](UsageExamples/02_tracerecorder_data_logging.c).

Demonstrates the use of TraceRecorder "user events" for debug logging and logging of variable values using the [trcPrint.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcPrint.h), accessed by including trcRecorder.h. TraceRecorder user events can be a superior alternative to printf calls in many cases, as printf calls can be very slow (milliseconds per call). When used for "printf debugging", this level of logging overhead may affect the debugged system in unpredictable ways and might give misleading results. TraceRecorder user events can be hundreds of times faster than a printf over a UART and thus eliminate over 99% of the logging overhead. See [this blog post](https://percepio.com/tracealyzer/ultra-fast-logging/)) for a performance comparison.

![Screenshot from demo 02](Screenshots/02.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

### 03_tracerecorder_state_logging.c
Source code: [UsageExamples/03_tracerecorder_state_logging.c](UsageExamples/03_tracerecorder_state_logging.c).

Demonstrates loggning of state changes with Percepio TraceRecorder using the [trcStateMachine.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcStateMachine.h) functions. This requires Percepio Tracealyzer for analysis, that allows for viewing the state events both on the timeline (like a logic analyzer), as an aggregated state diagram, and as an interval plot showing the durations of the states.

![Screenshot from demo 03](Screenshots/03.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

## Percepio Detect demos

### 10_dfm_crash_alert.c
Source code: [UsageExamples/10_dfm_crash_alert.c](UsageExamples/10_dfm_crash_alert.c).

Instructions coming...

### 11_dfm_custom_alert.c
Source code: [UsageExamples/11_dfm_custom_alert.c](UsageExamples/11_dfm_custom_alert.c).

Instructions coming...

### 12_dfm_stack_corruption_alert.c
Source code: [UsageExamples/12_dfm_stack_corruption_alert.c](UsageExamples/12_dfm_stack_corruption_alert.c).

Instructions coming...

### 13_dfm_stopwatch_alert.c
Source code: [UsageExamples/13_dfm_stopwatch_alert.c](UsageExamples/13_dfm_stopwatch_alert.c).

Instructions coming...

### 14_dfm_taskmonitor_alert.c
Source code: [UsageExamples/14_dfm_taskmonitor_alert.c](UsageExamples/14_dfm_taskmonitor_alert.c).

Instructions coming...

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
