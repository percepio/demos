#include <stdio.h>
#include <stdlib.h>
#include "main.h"
#include "dfm.h"
#include "osal.h"

/******************************************************************************
 * 13_dfm_stopwatch_alert.c
 *
 * Demonstrates the use of the DFM Stopwatch feature for monitoring software
 * latencies. Alerts are provided to Percepio Detect if the latency is higher
 * than expected, together with a trace for debugging purposes. This can be used
 * not only to analyze execution time variations, but also for multithreading
 * issues that otherwise might be very hard to debug.
 *
 * DFM alerts are machine-readable error reports, containing metadata about the
 * issue and debug data captured at the error, including a small core dump
 * with the call-stack trace, as well as a TraceRecorder trace providing the
 * most recent events. Viewer tools are integrated in the Detect client and
 * launched when clicking on the "payload" links in the Detect dashboard.
 * 
 * Learn more in main.c and at https://percepio.com/detect.
 *****************************************************************************/

dfmStopwatch_t* stopwatch;

#define COMPUTE_TIME_MIN_US        2000U
#define COMPUTE_TIME_JITTER_US      700U
#define EVENT_TIME_MIN_US           650U
#define EVENT_TIME_JITTER_US        150U
#define COMPUTE_TIME_WARNING_US    2900U

void vComputeTask(void *pvParameters);
void vSporadicTask(void *pvParameters); 

void computeSomething(void);
void handleEvent(int eventCode);
int waitForEvent(void);


/* Thread storage (stack size in bytes) */
OS_THREAD_STORAGE(computeTask, 2048);
OS_THREAD_STORAGE(sporadicTask, 512);


volatile int thread_done = 0;

void vComputeTask(void *pvParameters) 
{
    while (1)
    {      
        OS_delay_ms(24);
        
        if (stopwatch->times_above == 0)
        {
			// Start monitoring the latency
			vDfmStopwatchBegin(stopwatch);

			// Perform time-consuming processing
			computeSomething();

			// Check the elapsed time since begin.
			// Generates a DFM alert to Percepio Detect if over the expected maximum (set in xDfmStopwatchCreate).
			vDfmStopwatchEnd(stopwatch);
        }
        else
        {
        	thread_done = 1;
        }
    }
}

// May preempt and delay the ComputeTask since higher priority
void vSporadicTask(void *pvParameters) 
{    
    while (1)
    {
        int event = waitForEvent();
        
        // Simulated event processing.
        handleEvent(event);        
    }
}

void demo_stopwatch_alert(void)
{
  /* Note: The DFM library is initialized in main.c. */
    
  DEMO_PRINTF(LNBR "demo_stopwatch_alert - demonstrates the use of the DFM Stopwatch feature" LNBR
          "for detecting software latency anomalies, e.g. due to multthreading issues." LNBR
          "DFM alerts for Percepio Detect are emitted if the monitored latency is above" LNBR
          "the warning level and exceeding the previous high watermark." LNBR
          "See details in 13_dfm_stopwatch_alert.c." LNBR);
  
  OS_delay_ms(2500);
  
  /* Resets and start the TraceRecorder tracing. */
  xTraceEnable(TRC_START);
  
  // Generates a DFM alert to Percepio Detect if over the expected maximum.
  stopwatch = xDfmStopwatchCreate("ComputeTime", COMPUTE_TIME_WARNING_US);
    
  OS_thread_create(computeTask, vComputeTask, NULL, OS_PRIO_LOW);  
  OS_thread_create(sporadicTask, vSporadicTask, NULL, OS_PRIO_HIGH);  

  OS_delay_ms(5000);

  while(! thread_done)
  {
	  OS_delay_ms(500);
  }

  DEMO_PRINTF(LNBR "Calling vDfmStopwatchPrintAll():"); // Big trace buffer, takes long time, alert print still busy...
  vDfmStopwatchPrintAll();

  vDfmStopwatchClearAll();  
  
  OS_thread_delete(computeTask_handle);
  OS_thread_delete(sporadicTask_handle);
  
  xTraceDisable();  
}
  

void computeSomething(void)
{
    uint32_t execTimeUs = COMPUTE_TIME_MIN_US +
        (uint32_t)(rand() % COMPUTE_TIME_JITTER_US);

    // Simulate some processing time
    OS_busy_wait(execTimeUs);
}

void handleEvent(int eventCode)
{
    (void)eventCode; // not used
    
    uint32_t execTimeUs = EVENT_TIME_MIN_US +
        (uint32_t)(rand() % EVENT_TIME_JITTER_US);

    // Simulate some execution time
    OS_busy_wait(execTimeUs);
}

int waitForEvent(void)
{
    uint32_t delayMs = (uint32_t)(rand() % 10);

    OS_delay_ms(delayMs);
    return 1;
}
