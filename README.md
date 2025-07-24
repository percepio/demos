# Percepio Demo Library
This repository provides a set of demos for [Percepio Tracealyzer](https://percepio.com/tracealyzer) and [Percepio Detect](https://percepio.com/detect).

Percepio TraceRecorder is an event tracing library designed for embedded software, targeting 32-bit microcontrollers and up to 64-bit multicore SoCs. The traces are intended for [Percepio Tracealyzer](https://percepio.com/tracealyzer) and related tools. TraceRecorder supports continouous live streaming, as well as in-memory tracing (snapshots) using the RingBuffer module.

![TraceRecorder illustration](Screenshots/TraceRecorder.png)

[Percepio Detect](https://percepio.com/detect) offers systematic observability for test suites, e.g. in CI pipelines. This is a multi-user solution that allows for anomaly monitoring across multiple devices under test, or even in the field. The solution runs in your own network using Docker, meaning you don't need to upload sensitive .elf files to external cloud services and have full control over the device data.

![Detect illustration](Screenshots/Detect.png)

A web-browser dashboard provides a summary of the reported issues across all devices and tests. This includes debugging information such as TraceRecorder traces (snapshots) and core dumps, easily accessible via the "payload" links on the dashboard.

![Detect illustration](Screenshots/detect-dashboard.png)

**Note:** This demo repository is still under development. Currently there is only a single project available, for IAR Embedded Workbench and the STM32 B-L475-IoT01 board. Moreover, the instructions in this readme file is not yet complete for the Percepio Detect demos. However, the main point of this repository is the code examples and associated documentation. 

## TraceRecorder demos
The following demos demonstrate TraceRecorder tracing with FreeRTOS, using the RingBuffer setup. They run in sequence and progress is displayed in the console. To view the demo log:

* If using STM32CubeIDE, connect with a serial terminal application to the STLink Virtual COM port (115200 baud).

* If using IAR Embedded Workbench, the printf log is displayed in the Terminal I/O window, found in the View menu when in Debug mode. In case you don't see any output, you probably need to enable printf redirection to SWO. This is found under Options -> General Options -> Library Configuration. In the "Library low-level interface implementation" panel, select "Semihosted" and "Via SWO".

### 01_tracerecorder_kernel_tracing.c
Source code: [UsageExamples/01_tracerecorder_kernel_tracing.c](UsageExamples/01_tracerecorder_kernel_tracing.c).

This demo shows RTOS kernel tracing with Percepio TraceRecorder. Three threads are created, that are using a queue and a mutex. The thread-level execution is traced automatically. No logging calls are needed in the application code. 

Here is how it works. The kernel contains various trace hooks at important events. TraceRecorder defines these hooks to call its event tracing functions on key events such as task-switches and kernel API calls. The overhead of this is very small and typically not noticable.

To set up TraceRecorder in your own project, make sure to follow the [integration guide](https://percepio.com/getstarted/latest/html/) matching your RTOS.

![Screenshot from demo 01](Screenshots/01.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

In the trace view you can now see the execution of the three tasks, including kernel API calls on the Mutex and Semaphore objects as floating event labels. The red labels show blocking events, for example when the high priority task is forced to wait for the Mutex to become available. The blocked time is displayed by a crosshatched pattern. Learn more about the trace visualization in the User Manual (Help menu -> Views -> Trace View).

Note that the queue and mutex objects have been given custom object names as [described here](https://percepio.com/naming-your-kernel-objects/). 

### 02_tracerecorder_data_logging.c
Source code: [UsageExamples/02_tracerecorder_data_logging.c](UsageExamples/02_tracerecorder_data_logging.c).

This example demonstrates the use of TraceRecorder "user events" for debug logging and logging of variable values using the [trcPrint.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcPrint.h), accessed by including trcRecorder.h. TraceRecorder user events can be a superior alternative to printf calls in many cases, as printf calls can be very slow (milliseconds per call). When used for "printf debugging", this level of logging overhead may affect the debugged system in unpredictable ways and might give misleading results. TraceRecorder user events can be hundreds of times faster than a printf over a UART and thus eliminate over 99% of the logging overhead. See [this blog post](https://percepio.com/tracealyzer/ultra-fast-logging/)) for a performance comparison.

![Screenshot from demo 02](Screenshots/02.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

The logged "user events" are displayed as yellow labels in the trace view, and also appear in the event log. With Percepio Tracealyzer you can also see a plot of user event data arguments in the User Event Signal Plot. If this is not displayed automatically it is found in the Views menu.

### 03_tracerecorder_state_logging.c
Source code: [UsageExamples/03_tracerecorder_state_logging.c](UsageExamples/03_tracerecorder_state_logging.c).

Demonstrates loggning of state changes with Percepio TraceRecorder using the [trcStateMachine.h API](https://github.com/percepio/TraceRecorderSource/blob/main/include/trcStateMachine.h) functions. This requires Percepio Tracealyzer for analysis, that allows for viewing the state events both on the timeline (like a logic analyzer), as an aggregated state diagram, and as an interval plot showing the durations of the states.

![Screenshot from demo 03](Screenshots/03.png)

Once this demo has started, halt the execution after a few seconds, before the next demo starts. Alternatively, you can put a breakpoint at xTraceDisable call at the end of the file.

To view the resulting trace, save a snapshot as [described below](#viewing-snapshot-traces-from-tracerecorder), and open the resulting file in your Tracealyzer application (File -> Open -> Open File). 

With Percepio Tracealyzer, the logged states are displayed as a new view field in the Trace View, one per state machine object. You may expand and collapse such fields using the small (-) or (+) buttons shown in the top of the view field. You can see a state diagram for the logged states by selecting Views -> State Machine Graph. Moreover, double-clicking on a state interval opens a new window with additional information, such as timing statistics.


## Percepio Detect demos
Percepio Detect focuses on reporting anomalies, such a crashes, faults and other signs of abnormal runtime behavior. The data is provided by C library that is integrated on the device, DFM, which stands for Device Firmware Monitor. The reported data is ingested by the Detect Server, where it is stored in a database and presented in a web browser dashboard. This is designed to run locally, on prem, but can also be deployed in your own cloud assuming some customizations. The reports, a.k.a. "alerts", may include TraceRecorder traces (RingBuffer snapshots) and core dumps for easy post-mortem debugging using the integrated debugging tools.

The DFM library provides an API for custom programmatic alerts from the code, and also captures crashes (hard faults) automatically on Arm Cortex-M devices. DFM also provides advanced monitoring features for detecting abnormal behavior from side-effects on response times (stopwatches) and CPU time usage per thread (TaskMonitor).

The DFM data output can be handled in different ways. Two examples are included, Serial and ITM. You may also define your own "cloudport" module to implement a customized data transfer. 
For example, if your device has cloud connectivity, DFM can send the alerts directly to your cloud, e.g. using MQTT. However, it is often preferable to output the data to a local host computer. 

The Detect demos assumes that you have downloaded the Detect package and have a license for the solution. [Contact Percepio](https://percepio.com/contact-us/) to get the download link and an evaluation license.

### DFM output via UART ("Serial")
The "Serial" cloudport writes the DFM alert data as as hexadecimal strings to the debug console. This can be mixed with other textual logging. Use the logging feature in your serial terminal to export the combined log to a host file. The resulting log file needs to be processed by the Percepio Receiver tool, that convert the data to alert files and stores them in the Server's alert directory. The Detect Server ingests the new alert files automatically and they appear on the dashboard within a few seconds.

Learn more about the Receiver tool in the readme file in the tool directory (percepio-receiver/readme-receiver.txt).

### DFM output via ITM (with IAR)
For Arm Cortex-M devices featuring the ITM unit, the DFM data can be written to an ITM port and then saved to a host file. The data is then transferred over the SWO pin on the debug port. This works really well for IAR Embedded Workbench, especially with I-Jet debug probes. The I-Jet probes offer high SWO performance (support Manchester mode) and appear to be very reliable.  

In IAR Embedded Workbench, start a debug session and open "SWO Configuration". Enable ITM port 2 both under "Enabled ports" and under "To Log File" (the third checkboxs from the right). 

![SWO configuration in IAR](Screenshots/iar-swo-config.png)

You may also want to adjust the SWO prescaler, that decides the SWO clock frequency. The "auto" option seems to result in too high SWO clock frequency.
According to our experience, the I-Jet seems capable of handling 20 MHz SWO very reliably, but 40 MHz resulted in occational data errors which is not acceptable in this context.

Also make sure the I-Jet is configured for Manchester mode, if available. This is necessary to achieve high SWO speeds (over 5-10 MHz), i.e., to minimize the time it takes to emit an alert. 
Open the Options page and the I-Jet page. On the Trace page, you find the "SWO protocol" setting. Make sure this is set to "Manchester" (or "Auto").

![SWO protocol selection in IAR](Screenshots/iar-ijet-swo.png)

Also make sure nothing else in your system writes to ITM port 2. In necessary, you can change the ITM port setting in dfmCloudPortConfig.h. Note that ITM port 0 is typically used for printf logging (stdout/stderr).

Finally, use the Percepio Receiver script "bin2alerts.py" to process the ITM log file. A usage example is given below:

```
python.exe .\bin2alerts.py path\to\ITM.log -f ..\test-data\alert-files\ -d DemoDevice42 --eof wait
```
The arguments have the following meaning:
* -f path: is the destination directory for the alert files, that should match the Alert directory of the Detect Server.
* -d name: allows for overriding the device name reported by DFM. This can be used for other purposes if desired, for example to give the name of the test suite or configuration.
* --eof wait argument means that the script should await more data in the file. This allows for running the script in real time. In this mode, the script needs to be terminated using Ctrl-C. Omitting this option (or using --eof exit) will terminate the script when it reaches the end of the file.


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
