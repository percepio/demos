/******************************************************************************
 * demo_app.c
 * Common demo application (shared between projects). 
 * 
 * Copyright (c) Percepio AB, 2025
 *****************************************************************************/ 

#include "demo_app.h"
#include "main.h"
#include "dfm.h"
#include "trcRecorder.h"

OS_THREAD_STORAGE(DemoDriver, 384);

extern unsigned int selectNextDemo(void); 

void vTaskDemoDriver(void *pvParameters)
{
    (void) pvParameters;
    
    /* (Optional) For Percepio Detect, you can put DFM_STACK_MARKER first in
       each entry function to avoid including unrelated memory in core dumps, 
       on fault exceptions or DFM_TRAP calls. Adds 12 bytes to the stack.
       This minimizes the core dump size and avoids warnings from the call
       stack unwinding due to extra data. 
       
       Note: DFM_STACK_MARKER is only supported with the CrashCatcher integration
       (dfmCrashCatcher.h) which is intended for e.g. FreeRTOS and bare metal systems.
       It is not supported for Zephyr, since using Zephyr's own Core Dump library in
       that case, which isn't aware of DFM_STACK_MARKER. */
 
#ifndef __ZEPHYR__
    DFM_STACK_MARKER(); 
#endif
    
    DEMO_PRINTF(LNBR "Percepio demo starting up" LNBR); // Snapshot here
    
    for (;;)
    {     
        unsigned int demoToRun = selectNextDemo();
        DEMO_PRINTF(LNBR "----------------------------------------" LNBR);
        DEMO_PRINTF(LNBR "Running demo example %d" LNBR, demoToRun);
        
        switch(demoToRun)
        {
          
            case 0: 
               /****************************************************************
                * demo_kernel_tracing
                *
                * Demonstrates tracing of a FreeRTOS application with queue and
                * mutex calls, including how to set custom object names.
                * 
                * See also:               
                * - https://percepio.com/tracealyzer-zephyr-examples-ac6/
                * - https://percepio.com/hands-on-using-view-fields/
                * - https://percepio.com/naming-your-kernel-objects/
                *
                * Relevant for: All Percepio tools.
                *
                * See details in 01_tracerecorder_kernel_tracing.c.
                ***************************************************************/
                demo_kernel_tracing(); 
                break;
              
            case 1: 
               /**************************************************************** 
                * demo_data_logging
                *
                * Shows how to log integer variables to the TraceRecorder
                * trace as "user events" (xTracePrintF).
                *
                * See also https://percepio.com/understanding-your-application-with-user-events/
                *
                * Relevant for: All Percepio tools.
                *
                * See details in 02_tracerecorder_data_logging.c.
                ***************************************************************/
                demo_data_logging(); 
                break;

            case 2:
               /**************************************************************** 
                * demo_state_logging
                *
                * Demonstrates the TraceRecorder trcStateMachine functions for
                * efficient logging of state changes (state machine events).               
                * 
                * See also https://percepio.com/visualizing-state-machines/
                *
                * Relevant for:
                *    - Percepio Tracealyzer
                *    - Percepio Detect (via Tracealyzer). 
                *
                * See details in 03_tracerecorder_state_logging.c.
                **************************************************************/
                demo_state_logging();
                break;              
            
            case 3:       
               /*****************************************************************
               * demo_crash_alert
               *
               * Shows how a crash (fault exception) is stored as an "alert" for
               * Percepio Detect using the DFM library, including a core dump
               * and TraceRecorder event trace for post-mortem crash debugging.               
               *
               * Relevant for:
               *    - Percepio Detect (see https://percepio.com/detect)
               *
               * See details in 10_dfm_crash_alert.c.
               *
               * This integrates an improved version of the popular CrashCatcher
               * library targeting Arm Cortex-M MCUs. The Percepio improvements
               * allow for small selective core dumps relative to the current
               * stack pointer. Default settings generate less than 600 bytes.
               ****************************************************************/
               demo_crash_alert();
               break;                
                
            case 4:
              /*****************************************************************
               * demo_custom_alert
               *
               * Shows how to DFM_TRAP to store a runtime error from the code
               * as DFM alerts for Percepio Detect. Just like on crashes you get
               * both a core dump for detailed insight and a TraceRecorder trace
               * with a timeline of events providing more context on the issue.
               *
               * Relevant for:
               *    - Percepio Detect (see https://percepio.com/detect)
               *
               * See details in 11_dfm_custom_alert.c.
               ****************************************************************/
               demo_custom_alert();
               break;
               
            case 5:       
               /*****************************************************************
               * demo_stack_corruption_alert
               *
               * Shows how a buffer overrun error causing stack corruption is 
               * captured using DFM in combination with compiler-provided checks.
               * Just like on other DFM alerts, you get both a core dump for
               * detailed insight and a TraceRecorder trace with a timeline of
               * events providing more context on the issue.             
               *
               * Relevant for:
               *    - Percepio Detect (see https://percepio.com/detect)
               *
               * See details in 13_dfm_stack_corruption_alert.c.
               ****************************************************************/
               demo_stack_corruption_alert();
               break;
              
            case 6:
              /*****************************************************************
               * demo_stopwatch_alert
               *
               * Shows how to detect response time (latency) anomalies using the
               * Stopwatch feature in Percepio Detect (DFM library). When the
               * latency exceeds the specified warning level, you get a DFM alert
               * with a TraceRecorder trace that shows what happened. Also keeps
               * track of the high watermark for the specific latency. Repeated
               * alerts are only reported if exceeding the high watermark.
               *
               * Relevant for:
               *    - Percepio Detect (see https://percepio.com/detect)
               *
               * See details in 13_dfm_stopwatch_alert.c.
               *****************************************************************/
               demo_stopwatch_alert();
               break;
            
            case 7:     
              /*****************************************************************
               * demo_taskmonitor_alert
               *
               * Shows how to detect workload anomalies (CPU time usage) using the
               * TaskMonitor feature in Percepio Detect (DFM library). 
               * This allows for capturing TraceRecorder traces on intermittent
               * multithreading issues and other cases where a system becomes
               * unresponsive or have "glitches" in the real-time behavior. 
               * If a thread executes more (or less) than the specified CPU usage
               * range, a DFM alert is emitted to Percepio Detect - including a
               * TraceRecorder trace that shows what happened.
               * This also keeps track of the low and high watermark for each
               * thread. Repeated alerts are only reported if above the high
               * watermark or below the low watermark.
               *
               * Relevant for:
               *    - Percepio Detect (see https://percepio.com/detect)
               *
               * See details in 14_dfm_taskmonitor_alert.c.
               *****************************************************************/               
               demo_taskmonitor_alert();
               break;    
        }

        OS_delay_ms(1000);  // delay 1 second before the next example.
    }
}

void demo_app(void)
{  
  /****************************************************************************
   * xTraceInitialize() - Needed for Percepio Tracealyzer and Percepio Detect
   * Must be done before any TraceRecorder or RTOS calls.
   * To start the recording, call xTraceEnable(TRC_START);
   ***************************************************************************/
  DEMO_PRINTF("Initializing TraceRecorder library." LNBR);
  if (xTraceInitialize() == TRC_FAIL)
  {
      DEMO_PRINTF(LNBR "  ERROR: TraceRecorder failed to initialize." LNBR);
  }
   
  /****************************************************************************
   * xDfmInitializeForLocalUse() - Needed for Percepio Detect 
   * Initializes the DFM library, without specifying Device ID and Session ID. 
   * These are instead set by the receiver script during the host-side 
   * processing of the DFM data.
   * This is suitable for use in internal testing/CI on a small number
   * of devices. In this mode, the device is assumed to have its' own receiver
   * instance on the host. This applies the Device ID specified as a parameter
   * and also applies an automatically generated Session ID.
   *
   * For use in deployed devices, it is better to use xDfmInitialize(). 
   * This lets you specify Device ID and Session ID values on the device side,
   * so the host side doesn't need configuration for each device.
   * Learn more in the Device Integration Guide.
   ***************************************************************************/
  DEMO_PRINTF("Initializing DFM library for Percepio Detect." LNBR);
  if (xDfmInitializeForLocalUse() == DFM_FAIL)
  {
      DEMO_PRINTF(LNBR "  ERROR: DFM failed to initialize." LNBR);
  }

  /* Uses a single task to run the demos and tests. */
  OS_thread_create(DemoDriver, vTaskDemoDriver, NULL, OS_PRIO_HIGHEST);
  
  OS_start_scheduler();
}
