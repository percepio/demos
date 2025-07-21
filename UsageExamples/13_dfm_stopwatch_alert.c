#include <stdio.h>
#include <stdlib.h>
#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "dfm.h"

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

void vComputeTask(void *pvParameters);
void vSporadicTask(void *pvParameters); 

void computeSomething(void);
void handleEvent(int eventCode);
int waitForEvent(void);


void vComputeTask(void *pvParameters) 
{
    while (1)
    {      
        vTaskDelay( pdMS_TO_TICKS(24) );
        
        // Start monitoring the latency
        vDfmStopwatchBegin(stopwatch);
        
        // Perform time-consuming processing
        computeSomething();
        
        // Check the elapsed time since begin. 
        // Generates a DFM alert to Percepio Detect if over the expected maximum (set in xDfmStopwatchCreate).
        vDfmStopwatchEnd(stopwatch);
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

  TaskHandle_t hndTask1 = NULL;
  TaskHandle_t hndTask2 = NULL;

  /* Note: The DFM library is initialized in main.c. */
    
  printf("\n\rdemo_stopwatch_alert - demonstrates the use of the DFM Stopwatch feature"
          "for detecting software latency anomalies, e.g. due to multthreading issues.\n\r"
          "DFM alerts for Percepio Detect are emitted if the monitored latency is above\n\r"
          "the warning level and exceeding the previous high watermark.\n\r"
          "See details in 13_dfm_taskmonitor_alert.c.\n\r\n\r");             
  
  vTaskDelay(2500);
  
  /* Resets and start the TraceRecorder tracing. */
  xTraceEnable(TRC_START);
  
  // Generates a DFM alert to Percepio Detect if over the expected maximum (specified in clock cycles).
  stopwatch = xDfmStopwatchCreate("ComputeTime", 300000);
    
  xTaskCreate(
      vComputeTask,     
      "PeriodicCompute",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 1, // Low priority
      &hndTask1
  );
  
  xTaskCreate(
      vSporadicTask,
      "SporadicEvent",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 3, // High priority
      &hndTask2
  );
    
  vTaskDelay(5000);
  printf("\n\rSummary:\n\r");
  vDfmStopwatchPrintAll();

  vDfmStopwatchClearAll();  
  
  vTaskDelete(hndTask1);
  vTaskDelete(hndTask2);
  
  xTraceDisable();  
}
  

void computeSomething(void)
{
    int execTime = 15000 + rand() % 5000;

    // Simulate some processing time
    for (volatile int i=0; i < execTime; i++);
}

void handleEvent(int eventCode)
{
    (void)eventCode; // not used
    
    int execTime = 5000 + rand() % 1000;

    // Simulate some execution time
    for (volatile int i=0; i < execTime; i++);
}

int waitForEvent(void)
{
    vTaskDelay(rand() % 10);
    return 1;
}
