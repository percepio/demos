#include <stdlib.h>
#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "dfm.h"

/******************************************************************************
 * 14_dfm_taskmonitor_alert.c
 *
 * Demonstrates the use of the DFM TaskMonitor feature for monitoring the
 * processor time usage of software threads. This can be used not only to
 * analyze workload variations, but also for capturing multithreading issues
 * that otherwise might be very hard to debug. For example, if the system
 * becomes unresponsive because of threads being blocked or deadlocked.
 *
 * DFM alerts are machine-readable error reports, containing metadata about the
 * issue and debug data captured at the error, including a small core dump
 * with the call-stack trace, as well as a TraceRecorder trace providing the
 * most recent events. Viewer tools are integrated in the Detect client and
 * launched when clicking on the "payload" links in the Detect dashboard.
 * 
 * The expected range of CPU usage per thread is specified by calling
 * xDfmTaskMonitorRegister, for example:
 *
 *    xDfmTaskMonitorRegister(hndTask2, 2, 98); // Expected range: 2 - 98%.
 *
 * The monitoring is done by calling xTraceTaskMonitorPoll() periodically. 
 * It calculates the relative processor time usage since the previous poll
 * and compares it as a percentage of the total elapsed time between polls.
 *
 * The monitoring periods should be short enough to fit in the trace buffer,
 * for example 100 ms. It is recommended to align the monitor polling with as
 * many periodic tasks as possible to reduce variations due to timing effects.
 * For example, if you have two periodic tasks running at 5 ms and 12 ms period,
 * a polling rate of 60 ms (or a multiple of 60) should give good alignment.
 * 
 * Learn more in main.c and at https://percepio.com/detect.
 *****************************************************************************/

volatile int task_spike = 0;
volatile int task_blocked = 0;
        
void vTask1(void *pvParameters)
{
    (void) pvParameters;
    
    TickType_t xLastWakeTime;
    
    xLastWakeTime = xTaskGetTickCount();
    
    for (;;)
    {
      
        if (task_blocked == 1)
        {
            vTaskDelayUntil( &xLastWakeTime, pdMS_TO_TICKS(200) );
            task_blocked = 0;
        }
        else
        {
            vTaskDelayUntil( &xLastWakeTime, pdMS_TO_TICKS(10) );
        }
        
        int n =  9000 + rand() % 1000;
        for (volatile int i=0; i<n; i++);
    }
}


void vTask2(void *pvParameters)
{
    (void) pvParameters;

    TickType_t xLastWakeTime;
    const TickType_t xFrequency = pdMS_TO_TICKS(5);
    
    xLastWakeTime = xTaskGetTickCount();
    
    for (;;)
    {

        vTaskDelayUntil( &xLastWakeTime, xFrequency );

        if (task_spike == 1)
        {
            int n =  150000 + rand() % 50000;
            for (volatile int i=0; i<n; i++);
            task_spike = 0;
        }
        else
        {
            int n =  7000 + rand() % 2000;
            for (volatile int i=0; i<n; i++);
        }
        
    }
}

volatile int demo_done = 0;

void vTaskMonitor(void *pvParameters)
{
    (void) pvParameters;
         
    int demo_counter = 0;
    
    demo_done = 0;
    
    xTraceTaskMonitorPollReset();
    
    for (;;)
    {
        switch (demo_counter)
        {
          case 0:   printf("TaskMonitor example 1 - Nominal execution (no alerts)" LNBR);                 
                    break;
          
          case 25:  printf("xDfmTaskMonitorPrint() shows high/low watermarks." LNBR);
                    printf(LNBR);
                    xDfmTaskMonitorPrint();
                    printf(LNBR);
                    break;
                    
          case 60:  printf("TaskMonitor example 2: Task 1 runs more than expected (sends alert)" LNBR);
                    task_spike = 1;  
                    break;
          
          case 95:  printf("TaskMonitor example 3: Task 2 runs less than expected (sends alert)" LNBR);
                    task_blocked = 1;  
                    break;
                    
          case 130: demo_done = 1;
                    vTaskSuspend(NULL); // Suspend this task, will be killed by the demo driver.
          
          default:  break;            
        }
      
        // Delay for 100 ms - the monitoring period. 
        // Important to use an absolute delay here, to ensure the time between
        // poll calls is sufficiently long. Otherwise, if using relative delays
        // that depend on the loop execution time, the monitoring period might
        // become too short or even zero in some cases, causing false alerts.
      
        vTaskDelay(pdMS_TO_TICKS(100));
        
        xTraceTaskMonitorPoll();
        
        int new_alerts = xDfmSessionGetNewAlerts();
        if (new_alerts > 0)
        {
           // Allow time to normalize (data output etc.)
           vTaskDelay(pdMS_TO_TICKS(500));
          
           printf(LNBR "DFM reports %d new alerts have been sent.\r\nCalling xDfmTaskMonitorPrint:" LNBR LNBR, new_alerts);
           xDfmTaskMonitorPrint();
           printf(LNBR);
           
           // Resets the task data.
           xTraceTaskMonitorPollReset();
        }
        
        demo_counter++;
        
    }
}

void demo_taskmonitor_alert(void)
{

  TaskHandle_t hndTask1 = NULL;
  TaskHandle_t hndTask2 = NULL;
  TaskHandle_t hndMon = NULL;
    
  /* Note: The DFM library is initialized in main.c. */
  
  printf(LNBR "demo_taskmonitor_alert - demonstrates the DFM TaskMonitor feature" LNBR
          "for monitoring processor time usage of software threads." LNBR
          "Generates a DFM alert for Percepio Detect on unexpected workload variations," LNBR
          "like if a task gets stuck in a loop or is deadlocked." LNBR
          "See details in 14_dfm_taskmonitor_alert.c." LNBR LNBR);
      
  vTaskDelay(2500);
  
  /* Resets and start the TraceRecorder tracing. */
  xTraceEnable(TRC_START);
  
  /* Clears the "new alerts" counter */
  (void)xDfmSessionGetNewAlerts();
  
  
  xTaskCreate(
      vTaskMonitor,
      "vTaskMonitor",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 1, 
      &hndMon
  );
  
  xTaskCreate(
      vTask1,
      "vTask1",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 2,
      &hndTask2
  );
  
  xTaskCreate(
      vTask2,
      "vTask2",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 3, // Higher priority than the demo driver.
      &hndTask1
  );
  
  
  // 0 - 30% CPU load is expected, otherwise make an alert.
  xDfmTaskMonitorRegister(hndTask1, 0, 30);
    
  // 3 - 15% CPU load is allowed, otherwise make an alert.
  xDfmTaskMonitorRegister(hndTask2, 3, 15);
    
  while (! demo_done)
  {
     vTaskDelay(1000);
  }
  
  xDfmTaskMonitorUnregister(hndTask1);  
  xDfmTaskMonitorUnregister(hndTask2);  
  
  vTaskDelete(hndTask1);
  vTaskDelete(hndTask2);      
  vTaskDelete(hndMon);
  
  xTraceDisable();
}
  
