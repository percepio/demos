/******************************************************************************
 * demo_app.c
 * Common demo application (shared between projects). 
 * 
 * Copyright (c) Percepio AB, 2025
 *****************************************************************************/ 

#include "demo_app.h"
#include "osal.h"
#include "main.h"
#include "dfm.h"
#include "trcRecorder.h"

OS_THREAD_STORAGE(DemoDriver, 4096);

extern unsigned int selectNextDemo(void); 

/* Shared CPU-work implementation for the header-based demo OS abstraction. */
static uint32_t cpu_work_iterations_per_us_q16;

/* Calibration and normal execution must use the same compiled loop, even
 * with optimization enabled. Volatile keeps the work from being removed. */
#if defined(__ICCARM__)
#pragma inline=never
#elif defined(__GNUC__)
__attribute__((noinline, noclone))
#endif
static void cpu_work_iterations(uint32_t iterations)
{
    for (volatile uint32_t i = 0; i < iterations; i++) {
    }
}

static uint32_t cpu_work_measure(uint32_t iterations)
{
#ifdef __ZEPHYR__
    unsigned int key = irq_lock();
#else
    taskENTER_CRITICAL();
#endif

    const uint32_t start = (uint32_t)TRC_HWTC_COUNT;
    cpu_work_iterations(iterations);
    const uint32_t elapsed = (uint32_t)((uint32_t)TRC_HWTC_COUNT - start);

#ifdef __ZEPHYR__
    irq_unlock(key);
#else
    taskEXIT_CRITICAL();
#endif
    return elapsed;
}

int OS_cpu_work_calibrate(void)
{
    const uint32_t iterations = 256U;
    const uint32_t frequency_hz = (uint32_t)TRC_HWTC_FREQ_HZ;

    cpu_work_iterations_per_us_q16 = 0U;
    if (frequency_hz == 0U) {
        return 0;
    }

    /* A short, fixed startup cost is sufficient for demo workloads. Warm up
     * first, then subtract timer/call overhead from one bounded work sample. */
    (void)cpu_work_measure(16U);
    const uint32_t overhead = cpu_work_measure(0U);
    const uint32_t measured = cpu_work_measure(iterations);
    if (measured <= overhead) {
        return 0; /* Stopped or insufficiently resolved timer. */
    }

    const uint64_t rate =
        (((uint64_t)iterations * frequency_hz) << 16) /
        ((uint64_t)(measured - overhead) * 1000000ULL);
    if (rate == 0U || rate > UINT32_MAX) {
        return 0;
    }
    cpu_work_iterations_per_us_q16 = (uint32_t)rate;
    return 1;
}

void OS_cpu_work_us(uint32_t duration_us)
{
    if (duration_us == 0U) {
        return;
    }
#ifdef __ZEPHYR__
    __ASSERT_NO_MSG(cpu_work_iterations_per_us_q16 != 0U);
#else
    configASSERT(cpu_work_iterations_per_us_q16 != 0U);
#endif

    /* Round up fractional iterations; use 64 bits to support long requests. */
    uint64_t remaining =
        ((uint64_t)duration_us * cpu_work_iterations_per_us_q16 + 65535ULL) >> 16;
    while (remaining != 0U) {
        const uint32_t iterations = remaining > UINT32_MAX ? UINT32_MAX : (uint32_t)remaining;
        cpu_work_iterations(iterations);
        remaining -= iterations;
    }
}

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

    /* Recalibrate on every boot/QEMU session, after the scheduler and timer
     * have started. The factor is ordinary RAM, never retained or persisted. */
    if (!OS_cpu_work_calibrate()) {
        DEMO_PRINTF("ERROR: CPU-work calibration failed; demo stopped.");
        OS_thread_delete_self();
        return;
    }
    
    DEMO_PRINTF(LNBR "Percepio demo starting up");
    
    for (;;)
    {   
        unsigned int demoToRun = selectNextDemo();
        DEMO_PRINTF(LNBR "----------------------------------------");
        DEMO_PRINTF(LNBR "Running demo example %d", demoToRun);        
        
        /* Clearing and restarting the tracing for clean traces. */
        xTraceDisable();
        xTraceEnable(TRC_START);
        
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
  OS_thread_create(DemoDriver, vTaskDemoDriver, NULL, OS_PRIO_LOWEST);
  
  OS_start_scheduler();

}
