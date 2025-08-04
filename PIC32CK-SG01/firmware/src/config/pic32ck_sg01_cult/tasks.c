/*******************************************************************************
 System Tasks File

  File Name:
    tasks.c

  Summary:
    This file contains source code necessary to maintain system's polled tasks.

  Description:
    This file contains source code necessary to maintain system's polled tasks.
    It implements the "SYS_Tasks" function that calls the individual "Tasks"
    functions for all polled MPLAB Harmony modules in the system.

  Remarks:
    This file requires access to the systemObjects global data structure that
    contains the object handles to all MPLAB Harmony module objects executing
    polled in the system.  These handles are passed into the individual module
    "Tasks" functions to identify the instance of the module to maintain.
 *******************************************************************************/

// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
 *******************************************************************************/
// DOM-IGNORE-END

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include "configuration.h"
#include "definitions.h"
#include "sys_tasks.h"
#include "trcRecorder.h"
#include "dfm.h"

// *****************************************************************************
// *****************************************************************************
// Section: System "Tasks" Routine
// *****************************************************************************
// *****************************************************************************


void vTaskDemoDriver(void *pvParameters);

extern void demo_kernel_tracing(void);
extern void demo_data_logging(void);
extern void demo_state_logging(void);
extern void demo_custom_alert(void);
extern void demo_crash_alert(void);
extern void demo_taskmonitor_alert(void);
extern void demo_stopwatch_alert(void);
extern void demo_stack_corruption_alert(void);

static unsigned int selectNextDemo(void);

#define NUMBER_OF_DEMOS 8

/* Remembers the next demo to run, even if there is a warm restart */
volatile __attribute__((section (".pbss"))) unsigned int demo_test_case_next;

void vTaskDemoDriver(void *pvParameters)
{
    (void) pvParameters;
    
    printf(LNBR "Percepio demo starting up" LNBR);
    
    for (;;)
    {     
        unsigned int demoToRun = selectNextDemo();
        printf("----------------------------------------" LNBR LNBR);
        printf("Running demo example %d" LNBR, demoToRun);
        
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
        
        vTaskDelay(pdMS_TO_TICKS(1000));  // delay 1 second before the next example.
        
        printf("Done." LNBR);
    }
}

static unsigned int selectNextDemo(void)
{
    unsigned int ret;
    
    if (demo_test_case_next > NUMBER_OF_DEMOS) // Uninitialized after cold start, possibly junk value.
    {
        ret = 0;
        demo_test_case_next = 1; 
    }
    else
    {
        ret = demo_test_case_next;
        demo_test_case_next = (demo_test_case_next + 1) % NUMBER_OF_DEMOS;
    }
    return ret;
}    


/*******************************************************************************
  Function:
    void SYS_Tasks ( void )

  Remarks:
    See prototype in system/common/sys_module.h.
*/
void SYS_Tasks ( void )
{
      printf(LNBR LNBR "Initializing TraceRecorder library." LNBR);
      if (xTraceInitialize() == TRC_FAIL)
      {
          printf(LNBR "  ERROR: TraceRecorder failed to initialize" LNBR);
          for (;;);
      }

      printf("Initializing DFM library for Percepio Detect." LNBR);
      if (xDfmInitializeForLocalUse() == DFM_FAIL)
      {
          printf(LNBR "  ERROR: DFM failed to initialize" LNBR);
          for (;;);
      }

      xTaskCreate(
          vTaskDemoDriver,             
          "DemoDriver",            
          2048,
          NULL,               // Parameter
          tskIDLE_PRIORITY,
          NULL                // Task handle
      );

    /* Start RTOS Scheduler. */
    
     /**********************************************************************
     * Create all Threads for APP Tasks before starting FreeRTOS Scheduler *
     ***********************************************************************/
    vTaskStartScheduler(); /* This function never returns. */

}

/*******************************************************************************
 End of File
 */

