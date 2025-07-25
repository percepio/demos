# Percepio Demos
This repository provides a set of demos for [Percepio Tracealyzer](https://percepio.com/tracealyzer) and [Percepio Detect](https://percepio.com/detect).

Percepio TraceRecorder is an event tracing library designed for embedded software, targeting 32-bit microcontrollers and up to 64-bit multicore SoCs, providing data to Percepio Tracealyzer and related tools. 

TraceRecorder supports continouous live streaming, as well as in-memory tracing (snapshots) using the RingBuffer module. These demos are by default configured for RingBuffer snapshots.

<img src="Screenshots/TraceRecorder.png" width="500">

Demos are also included for the related solution [Percepio Detect](https://percepio.com/detect). This offers systematic observability on crashes and abnormal behavior during testing and can be integrated in CI testing or other test suites. By using Percepio Detect during testing, you get detailed debug information at faults and anomalies, even if no debug probe is connected. This way, you can avoid many hours of painful issue reproduction. Detect supports monitoring of multiple devices, in the test lab or in the field. Percepio Detect runs in your own private network using Docker.

<img src="Screenshots/Detect.png" width="800">

**Note:** This demo repository is still under active development. This document is not yet complete, and currently there is only a single demo project available for running the demos on a real board, for IAR Embedded Workbench and the STM32 B-L475-IoT01 board. More will be added, but the main point of this repository is the code examples and associated documentation. 

## TraceRecorder demos
The following demos demonstrate TraceRecorder tracing with FreeRTOS, using the RingBuffer setup. They run in sequence and progress is displayed in the console. 

To view the demo console log:

* If using STM32CubeIDE or other tools, connect with a serial terminal application to the STLink Virtual COM port (115200 baud).

* If using IAR Embedded Workbench, the printf log is displayed in the Terminal I/O window, found in the View menu when in Debug mode. Make sure to enable printf redirection to SWO, found under Options -> General Options -> Library Configuration. In the "Library low-level interface implementation" panel, select "Semihosted" and "Via SWO".

### 01_tracerecorder_kernel_tracing.c
Source code: [UsageExamples/01_tracerecorder_kernel_tracing.c](UsageExamples/01_tracerecorder_kernel_tracing.c).

This demo shows RTOS kernel tracing with Percepio TraceRecorder. Three threads are created, that are using a queue and a mutex. The thread-level execution is traced automatically. No logging calls are needed in the application code. 

![Screenshot from demo 01](Screenshots/01.png)

If you are curious how it works, the RTOS kernel contains various trace hooks at important events. TraceRecorder defines these hooks to call its event tracing functions on key events such as task-switches and kernel API calls. The overhead of this is very small and typically not noticable.

To set up TraceRecorder in your own project, make sure to follow the [integration guide](https://percepio.com/getstarted/latest/html/) matching your RTOS.

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). If you want to use trace streaming instead, you need to change trcStreamPort.c and trcStreamPort.h to use a different streamport module (see TraceRecorder/streamports) as described in the [integration guide](https://percepio.com/getstarted/latest/html/).

In the trace view you can now see the execution of the three tasks, including kernel API calls on the Mutex and Semaphore objects as floating event labels. The red labels show blocking events, for example when the high priority task is forced to wait for the Mutex to become available. The blocked time is displayed by a crosshatched pattern. Learn more about the trace visualization in the User Manual (Help menu -> Views -> Trace View).

Note that the queue and mutex objects have been given custom object names as [described here](https://percepio.com/naming-your-kernel-objects/). 

### 02_tracerecorder_data_logging.c
Source code: [UsageExamples/02_tracerecorder_data_logging.c](UsageExamples/02_tracerecorder_data_logging.c).

This example demonstrates the use of TraceRecorder "user events" for debug logging and logging of variable values using the [trcPrint.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcPrint.h). This API is accessed by including trcRecorder.h. 

![Screenshot from demo 02](Screenshots/02.png)

TraceRecorder user events can be a superior alternative to printf calls in many cases, as printf calls can be very slow (milliseconds per call). When used for "printf debugging", this level of logging overhead may affect the debugged system in unpredictable ways and might give misleading results. TraceRecorder user events can be hundreds of times faster than a printf over a UART and thus eliminate over 99% of the logging overhead. See [this blog post](https://percepio.com/tracealyzer/ultra-fast-logging/)) for a performance comparison.

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). If you want to use trace streaming instead, you need to change trcStreamPort.c and trcStreamPort.h to use a different streamport module (see TraceRecorder/streamports) as described in the [integration guide](https://percepio.com/getstarted/latest/html/).

The logged "user events" are displayed as yellow labels in the trace view, and also appear in the event log. With Percepio Tracealyzer you can also see a plot of user event data arguments in the User Event Signal Plot. If this is not displayed automatically it is found in the Views menu.

### 03_tracerecorder_state_logging.c
Source code: [UsageExamples/03_tracerecorder_state_logging.c](UsageExamples/03_tracerecorder_state_logging.c).

Demonstrates loggning of state changes with Percepio TraceRecorder using the [trcStateMachine.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcStateMachine.h) functions. Note that Percepio Tracealyzer is needed to visualize these events.

![Screenshot from demo 03](Screenshots/03.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). If you want to use trace streaming instead, you need to change trcStreamPort.c and trcStreamPort.h to use a different streamport module (see TraceRecorder/streamports) as described in the [integration guide](https://percepio.com/getstarted/latest/html/).

With Percepio Tracealyzer, the logged states are displayed in the Trace View, with one View Field per state machine object. You may expand and collapse such View Field using the small (-) or (+) icons in the top (next to the "gear" icon). You can see a state diagram for the logged states by selecting Views -> State Machine Graph. Moreover, double-clicking on a state interval opens a new window with additional information, such as timing statistics.

## Percepio Detect
Percepio Detect focuses on reporting anomalies, such a crashes, faults and other signs of abnormal runtime behavior. The data is provided by C library that is integrated on the device, DFM, which stands for Device Firmware Monitor. 

<img src="Screenshots/Detect.png" width="800">

The reported data is ingested by the Detect Server, where it is stored in a database and presented in a web browser dashboard. This is designed to run locally, on prem, but can also be deployed in your own cloud assuming some customizations.

A web-browser dashboard provides a summary of the reported issues across all devices and tests. This includes debugging information such as TraceRecorder traces (snapshots) and core dumps, easily accessible via the "payload" links on the dashboard.

![Detect illustration](Screenshots/detect-dashboard.png)

**Note:** The Detect demos assumes that you have downloaded the Detect package and have a license for the solution. [Contact Percepio](https://percepio.com/contact-us/) to get the download link and an evaluation license.

### Demonstrated Features

DFM alerts are machine-readable error reports, containing metadata about the issue and debug data captured at the error, including a small core dump
with the call-stack trace, as well as a TraceRecorder trace providing the  most recent events. DFM provides several methods to detect system anomalies and generate alerts, both automated methods and an API for custom alerts.

* **Fault Exceptions** (hard faults etc.) are captured and reported automatically using an integrated fault exception handler. This is designed for Arm Cortex-M devices. Support for other processor architectures is planned in the upcoming Zephyr support.

* The **Stopwatch** feature lets you monitor the response time (latency) of a code section and get alerts if a set warning level is exceeded. This also keeps a high watermark that avoids repeated alerts, that are below the previous high watermark. The high watermark can also be useful for profiling over long time periods, and for setting appropriate warning levels. This also allows for capturing elusive bugs as anomalies in response time/latency, for example thread starvations, deadlocks or priority inversions.
  
* The **TaskMonitor** allows for monitoring the CPU time usage per thread. An alert is produced if a monitored thread is outside the specified range, for example if stuck in a loop or if the thread runs less than expected. This also allows for capturing elusive bugs by their side-effect on CPU time usage, for example thread starvation, deadlocks and priority inversions. The TaskMonitor provides high and low watermarks for each thread. To avoid repeated redudant alerts, alerts are only emitted if the thread CPU usage is outside the watermark range. The watermarks are also useful for tuning the expected range/warning levels. The checks are done in xTraceTaskMonitorPoll() function, that should be called periodically. 

* **Stack corruption** is also reported, assuming stack integrity checking is enabled in the compiler settings. This allows for capturing stack smashing attacks and buffer overrun bugs. This works with (at least) gcc, clang and IAR.
  
* **Custom alerts** can be generated from your code, e.g. in error handlers and Assert statements, using the DFM API. The easiest way is to use the DFM_TRAP() macro but you may also compose your own custom alert using the dfmAlert functions.

### DFM Data Output
The DFM data output can be handled in different ways. Two examples are included, Serial and ITM. You may also define your own "cloudport" module to implement a customized data transfer. For example, if your device has cloud connectivity, DFM can send the alerts directly to your cloud, e.g. using MQTT. However, it is often preferable to output the data to a local host computer. 

#### DFM output via UART ("Serial")
The "Serial" cloudport writes the DFM alert data as as hexadecimal strings to the debug console. This can be mixed with other textual logging. Serial terminal application typically allow for logging the output to a file. The resulting log file needs to be processed by the Percepio Receiver tool, that extracts the DFM data and stores it as alert files in the shared alert directory, where they are noticed and ingested by the Detect Server.

Learn more about the Receiver tool in the readme file in the tool directory (percepio-receiver/readme-receiver.txt).

#### DFM output via ITM using IAR Embedded Workbench
For Arm Cortex-M devices featuring the ITM unit, the DFM data can be written to an ITM port and then saved to a host file. The data is then transferred over the SWO pin on the debug port.

To configure this in IAR Embedded Workbench, first make sure the I-Jet is configured for Manchester mode, if available. This is necessary to achieve high SWO speeds. Open the Options page and the I-Jet page. On the Trace page, you find the "SWO protocol" setting. Make sure this is set to "Manchester" (or "Auto").

<img src="Screenshots/iar-ijet-swo.png" width="500">

Next, start a debug session and open "SWO Configuration". Enable ITM port 2 both under "Enabled ports" and under "To Log File" (the third checkboxs from the right). 

<img src="Screenshots/iar-swo-config.png" width="650">

While the transfer speed is not critical for Percepio Detect, fast data transfer is still preferrable and the data transfer must be 100% reliable.
It is therefore adviced to adjust the SWO prescaler, that decides the SWO clock frequency. In our experience, the "auto" option may result in too high SWO clock frequency, resulting in occational transfer errors. Up to 20 MHz SWO seems to work well with I-Jet probes, but 40 MHz caused corrupted output.

By default, DFM uses ITM port 2. You may change the ITM port setting in dfmCloudPortConfig.h to avoid conflicts with other iTM logging in your system.

To process the ITM log, use the python script "bin2alerts.py" found in the Percepio Receiver directory.
A usage example is given below:
```
python.exe .\bin2alerts.py path\to\ITM.log -f ..\test-data\alert-files\ -d DemoDevice42 --eof wait
```
The arguments have the following meaning:
* -f path: The destination directory for the alert files, that should match the Alert directory of the Detect Server.
* -d name: Allows for overriding the device name reported by DFM, if the device name is not defined in the DFM integration.
* --eof wait: Makes the script await more data when reaching the end of the file. Use this mode to run the script in real time during the testing. To quit the script, use Ctrl-C in the terminal. If omitted, the script will exit when reaching the end of the file.

Once the resulting alert files have been written to the Alert directory, they should appear in the Detect dashboard within a few seconds.

## Percepio Detect Demos

Before you can view the debugging data from these examples, the Percepio Detect Client must be running in the background and have some paths configured to match your project. The Detect Client is an integrated package of debugging tools for Percepio Detect alerts, including Percepio Tracealyzer and a core dump viewer. The Client runs on your local computer and is accessed throught the web browser, using the payload links in the Detect dashboard. 

<img src="Screenshots/client.png" width="900">

Follow these steps to verify and update the Client configuration:

* If using the Windows: Open percepio-client-windows/project-settings.bat and update the ELF_PATH setting to point to your ELF file. For the provided IAR project, this is called "Project.out" and found in the EWARM\B-L475E-IOT01\Exe folder. Also update the SRC_PATH folder to point to the root folder of the Demo repository. Use absolute paths here.

* If using Linux: open the Client start script in a text editor (percepio-client.sh). Set ELF_DIR to the directory of the ELF file, and ELF_REL_PATH to the ELF filename. Also update the SRC_PATH folder to point to the root folder of the Demo repository. 

Now start the Percepio Client. 
* If using Windows, run percepio-client.bat.
* If using Linux, run percepio-client.sh.

In the Detect dashboard, you can now click the payload links to display the debugging data provided with the alerts.

### 10_dfm_crash_alert.c
Source code: [UsageExamples/10_dfm_crash_alert.c](UsageExamples/10_dfm_crash_alert.c).

This example demonstrates crash debugging with Percepio Detect. The code example causes a UsageFault Exception due to a division by zero, which is reported as an alert, including a core dump that provides the function call stack, arguments and local variables at the point of the fault.

First, make sure you have [configured and started the Client](#client-setup).

Then locate the "Hard Fault" row in the Detect dashboard and click the "cc_coredump.dmp" payload link. This will open the provided core dump in the integrated core dump viewer.

<img src="Screenshots/hard_fault.png" width="900">

The alert also includes a TraceRecorder trace, that is accessed by clicking the "dfm_trace.psfs" payload link. This opens the trace file in the included Tracealyzer tool, bundled in the Detect Client. The trace provide more context about the task execution and previous events, leading up to the alert. This may also include user event and state logging from your application, as demonstrated in previous examples. 

<img src="Screenshots/hard_fault_trace.png" width="900">

Note that Tracealyzer requires a separate license that needs to be [installed](https://percepio.com/tracealyzer/activating-license-key/) the first time you open a trace file.

### 11_dfm_custom_alert.c
Source code: [UsageExamples/11_dfm_custom_alert.c](UsageExamples/11_dfm_custom_alert.c).

This example demonstrates programmatic error reporting using the DFM_TRAP() macro. A function is called with an invalid argument, which is detected by an initial check (could also be an Assert statement). This calls DFM_TRAP to report the error as an alert, including a core dump that provides the function call stack, arguments and local variables at the point of the fault.

Make sure you have [configured and started the Client](#client-setup).

Locate the "Assert Failed" row in the Detect dashboard and click the "cc_coredump.dmp" payload link. This will open the provided core dump in the integrated core dump viewer.

<img src="Screenshots/custom_alert.png" width="900">

The alert also includes a TraceRecorder trace, where you can see test annotations as user events.

<img src="Screenshots/custom_alert_trace.png" width="900">

### 12_dfm_stack_corruption_alert.c
Source code: [UsageExamples/12_dfm_stack_corruption_alert.c](UsageExamples/12_dfm_stack_corruption_alert.c).

This example shows how DFM can be used to detect stack corruption faults at an early stage, before they lead to other less obvious errors that can be a nightmare to debug. This relies on compiler features for stack integrity checking, where the compiler inserts control values on the stack (stack canaries) at certain function calls and checks them before returning from the function. If the control value has changed (i.e. due to a corrupted stack), the compiler-injected check will call an error handler in DFM that emits a "Stack Corruption" alert including a core dump and TraceRecorder trace. 

<img src="Screenshots/stack_chk_fail.png" width="900">

In the core dump, you will see the error handler (__stack_chk_fail) at the top of the call stack. The stack corruption was detected just before the return of the previous function (test_stack_corruption). In this case, because 17 bytes were written to a 16 byte buffer. 

A trace is also included, with user event logging showing some details from the test.

<img src="Screenshots/stack_chk_fail_trace.png" width="900">

To enable this in your own project:
* If using gcc or clang, use one the [-fstack-protector](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html) compiler options. 
* If using IAR, enable "Stack protection" in project options, under C/C++ Compiler -> Code.

### 13_dfm_stopwatch_alert.c
Source code: [UsageExamples/13_dfm_stopwatch_alert.c](UsageExamples/13_dfm_stopwatch_alert.c).

This example demonstrates how to use the DFM Stopwatch feature for detecting software latency (response time) anomalies. Alerts are provided to Percepio Detect if the latency is higher than expected, together with a trace for debugging purposes. This can be used not only to analyze execution time variations, but also for multithreading issues that otherwise might be very hard to debug.

Stopwatch alerts includes a TraceRecorder trace that shows the most recent thread execution leading up to the alert. No core dump is included, since the relevant events are in the past. In this example, the stopwatch monitoring is inside the "PeriodicCompute" task, i.e. the yellow task in the trace. In the end of the trace, just before the alert, we can see that the "SporadicEvent" thread is preempting and running for quite a long time, causing the stopwatch to exceed the warning level.

<img src="Screenshots/stopwatch.png" width="900">

While many RTOS services offer timeouts, such timeout events are typically used for faults (the call is aborted) and timeouts often have large margins as the true response times often are unknown. Stopwatches can be given tighter tolerances to capture abnormal cases that are below the timeout value.

To define a specific stopwatch, call `xDfmStopwatchCreate(name, expected_max)`. This returns a `dfmStopwatch_t` pointer for use in later calls. Then use `vDfmStopwatchBegin(stopwatch_ptr)` and `vDfmStopwatchEnd(stopwatch_ptr)` to measure the time between two points in the code, including preemptions from interrupts and higher priority tasks. The highest observed value since startup is tracked as the "high watermark", that can be accessed as `stopwatch_ptr->high_watermark` or by calling `vDfmStopwatchPrintAll()`. An alert is emitted during `vDfmStopwatchEnd()` if the time since the last `vDfmStopwatchStart` exceeds `expected_max`, and also exceeds the high watermark.

Unlike TraceRecorder-based profiling, this can run indefinitely without needing to stream out, accumulate and analyze large amounts of trace data. Moreover, the Begin and End functions are normally very fast, often less than 1 µs combined, since not logging each measurement. However, the execution time of `vDfmStopwatchEnd` will be considarably longer on alerts, so it is recommended to finish any time-sensitive processing before calling `vDfmStopwatchEnd`.

You can have multiple stopwatches active in parallell. The default upper limit is 4, but this can be adjusted in dfmConfig.h (DFM_CFG_MAX_STOPWATCHES).

The time source used for Stopwatch measurements is the same as for TraceRecorder. However, DFM requires TraceRecorder to use a 32-bit free-running incrementing counter. An build error is produced if the TraceRecorder configuration is not compatible. This is the default for Arm Cortex-M devices (M3 and higher) featuring the DWT unit.

### 14_dfm_taskmonitor_alert.c
Source code: [UsageExamples/14_dfm_taskmonitor_alert.c](UsageExamples/14_dfm_taskmonitor_alert.c).

Demonstrates the use of the DFM TaskMonitor feature for monitoring the processor time usage of software threads (RTOS threads). This is useful not only for profiling and to analyze workload variations, but also capturing multithreading issues that otherwise might be very hard to debug. For example, if the system
becomes unresponsive because of threads being blocked or deadlocked, it can be detected as the CPU usage of those threads will be outside the expected range.

The expected range of CPU usage per thread is specified by calling `xDfmTaskMonitorRegister(task, low, high)`, where the first argument is the handle (pointer) to the task, followed by the low and high bounds in percent. An example is provided below:
```
xDfmTaskMonitorRegister(hndTask2, 2, 98); // Expected range: 2 - 98%.
``` 
The monitoring is done by periodic calls to xTraceTaskMonitorPoll(). 
This calculates the relative processor time usage since the previous poll
and compares it as a percentage of the total elapsed time between polls.

The polling periods should be short enough to fit in the trace buffer,
typically 50-500 ms, depending on the trace buffer size and
the event rate of the tracing.

It is recommended to align the monitor polling with your periodic tasks to reduce variations due to timing effects.
For example, if you have two periodic tasks running at 5 ms and 12 ms period, a polling rate of 60 ms (or a multiple of 60) should give good alignment.
 
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
