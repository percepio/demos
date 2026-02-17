#include <stdlib.h>
#include "main.h"
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

TraceStringHandle_t log_chn;

/* Thread storage (stack size in bytes) */
OS_THREAD_STORAGE(taskMonitor, /*3*1024*/ 768 );
OS_THREAD_STORAGE(task1, /*2*1024*/ 384 );
OS_THREAD_STORAGE(task2, /*2*1024*/ 384 );

void vTask1(void *pvParameters)
{
    (void) pvParameters;
    
    OS_tick_t xLastWakeTime;
    
    // 5 - 25% CPU load is allowed, otherwise make an alert.
    xDfmTaskMonitorRegister(NULL, 5, 25);

    //xLastWakeTime = OS_get_tick_count();
    
    for (;;)
    {
      
        if (task_blocked == 1)
        {
            xTracePrint(log_chn, "Demo issue: not running for 200 ms");
            OS_delay_ms(200);
            task_blocked = 0;
        }
        else
        {
            OS_delay_ms(10);
        }
        
        int n =  10000; // + rand() % 1000;
        for (volatile int i=0; i<n; i++);
    }
}


void vTask2(void *pvParameters)
{
    (void) pvParameters;

    //OS_tick_t xLastWakeTime;
    //const uint32_t frequency_ms = 15;

    // 0 - 30% CPU load is expected, otherwise make an alert.
    xDfmTaskMonitorRegister(NULL, 0, 30);
    
    //xLastWakeTime = OS_get_tick_count();
    
    for (;;)
    {

        OS_delay_ms(5);

        if (task_spike == 1)
        {            
            int n =  150000; // + rand() % 5000;
            xTracePrint(log_chn, "Demo issue: runs longer than normal");
            for (volatile int i=0; i<n; i++);
            task_spike = 0;            
        }
        else
        {
            int n =  5000;// + rand() % 2000;
            //xTracePrintF(NULL, "Normal (%d)", n);
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
          case 0:   DEMO_PRINTF("TaskMonitor example 1 - Nominal execution (no alerts)" LNBR); 
                    break;
          
          case 25:  DEMO_PRINTF("xDfmTaskMonitorPrint() shows high/low watermarks." LNBR);
                    DEMO_PRINTF(LNBR);
                    xDfmTaskMonitorPrint();
                    DEMO_PRINTF(LNBR);
                    break;
                    
          case 50:  DEMO_PRINTF("TaskMonitor example 2: task2 runs more than expected (alert follows)" LNBR);
                    break;
          case 65:  task_spike = 1;
                    break;         
                    
          case 66:  task_spike = 0; /* 100 ms later */
                    break;        

          case 67:  DEMO_PRINTF(LNBR "After spike" LNBR);
                    xDfmTaskMonitorPrint();
                    DEMO_PRINTF(LNBR);
                    break;

          case 90:  DEMO_PRINTF("TaskMonitor example 3: task1 runs less than expected (alert follows)" LNBR);
                    break;
          case 105: task_blocked = 1;
                    break;
          case 106: task_blocked = 0; /* 100 ms later */   
                    break;        
          case 107: 
                    DEMO_PRINTF(LNBR "After blocking" LNBR);
                    xDfmTaskMonitorPrint();
                    DEMO_PRINTF(LNBR);
                    
                    xTracePrint(log_chn, "Demo done");
                    demo_done = 1;
                    return;
          
          default:  break;            
        }
      
        // Delay for 100 ms - the monitoring period. 
        // Important to use an absolute delay here, to ensure the time between
        // poll calls is sufficiently long. Otherwise, if using relative delays
        // that depend on the loop execution time, the monitoring period might
        // become too short or even zero in some cases, causing false alerts.
      
        OS_delay_ms(100);
        
        xTraceTaskMonitorPoll(); /* Check for alerts every 100 ms. */
        
        int new_alerts = xDfmSessionGetNewAlerts();
        if (new_alerts > 0)
        {           
           DEMO_PRINTF(LNBR "DFM reports %d new alerts have been sent." LNBR, new_alerts);       
        }
        
        demo_counter++;
        
    }
}

void demo_taskmonitor_alert(void)
{
  /* Note: The DFM library is initialized in main.c. */
  
  xTraceStringRegister("Log channel", &log_chn);

  DEMO_PRINTF(LNBR "demo_taskmonitor_alert - demonstrates the DFM TaskMonitor feature" LNBR
          "for monitoring processor time usage of software threads." LNBR
          "Generates a DFM alert for Percepio Detect on unexpected workload variations," LNBR
          "like if a task gets stuck in a loop or is deadlocked." LNBR
          "See details in 14_dfm_taskmonitor_alert.c." LNBR LNBR);
      
  OS_delay_ms(2500);
  
  extern uint32_t SystemCoreClock;

  DEMO_PRINTF("SystemCoreClock = %u Hz" LNBR , SystemCoreClock);

  /* Resets and start the TraceRecorder tracing. */
  xTraceEnable(TRC_START);
  
  /* Clears the "new alerts" counter */
  (void)xDfmSessionGetNewAlerts();
  
  OS_thread_create(task2, vTask2, NULL, OS_PRIO_MID);
  OS_thread_create(task1, vTask1, NULL, OS_PRIO_LOW); 
  OS_thread_create(taskMonitor, vTaskMonitor, NULL, OS_PRIO_HIGH);
    
  while (! demo_done)
  {
     OS_delay_ms(100);
  }
  
  xDfmTaskMonitorUnregister(task2_handle);  
  xDfmTaskMonitorUnregister(task1_handle);  
  
  OS_thread_delete(task2_handle);
  OS_thread_delete(task1_handle);      
  xTraceDisable();

}
  
