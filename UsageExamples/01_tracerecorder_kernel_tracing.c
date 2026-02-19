#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#include "osal.h"
#include "dfm.h"

/******************************************************************************
 * 01_tracerceorder_kernel_tracing.c
 *
 * Demonstrates RTOS tracing with Percepio TraceRecorder, including queue and
 * mutex usage with custom object names. This example can be used with any
 * TraceRecorder configuration, also continuous streaming, but the default
 * configuration is for snapshots using the RingBuffer streamport module.
 *
 * For information on recording and viewing TraceRecorder traces, please refer
 * to https://percepio.com/tracealyzer/gettingstarted.
 *
 * Learn more in main.c and at https://percepio.com/tracealyzer.
 *****************************************************************************/

#define QUEUE_LENGTH 10
#define QUEUE_ITEM_SIZE sizeof(int)

OS_QUEUE_STORAGE(myQueue, QUEUE_ITEM_SIZE, QUEUE_LENGTH);
OS_MUTEX_STORAGE(myMutex);

static void vTask1(void *pvParameters);
static void vTask2(void *pvParameters);
static void vTask3(void *pvParameters);

static void dummy_exectime(int min, int max);

/* Thread storage (stack size in bytes) */
OS_THREAD_STORAGE(taskA, 384);
OS_THREAD_STORAGE(taskB, 384);
OS_THREAD_STORAGE(taskC, 384);


void vTask1(void *pvParameters)
{
    (void) pvParameters;
    
    int msg;
    
    for (;;)
    {
        // Receive dummy message from queue
        if (OS_queue_recv_ms(myQueue_handle, &msg, OS_WAIT_FOREVER_MS) == 1)
        {

            dummy_exectime(500, 700);
            
            OS_mutex_take_ms(myMutex_handle, OS_WAIT_FOREVER_MS);
            dummy_exectime(9000, 12000);
            OS_mutex_give(myMutex_handle);    
            
            dummy_exectime(1000, 2000);
        }
    }
}

void vTask2(void *pvParameters)
{
    (void) pvParameters;

    OS_tick_t xLastWakeTime;
    const uint32_t frequency_ms = 9;
    
    xLastWakeTime = OS_get_tick_count();
    
    for (;;)
    {
        OS_delay_until_ms(&xLastWakeTime, frequency_ms);

        dummy_exectime(4000, 5000);
    
        // Send dummy message to queue
        int msg = rand();
        OS_queue_send_ms(myQueue_handle, &msg, 0);
    
    }
}

void vTask3(void *pvParameters)
{
    (void) pvParameters;
    
    for (;;)
    {        
        dummy_exectime(1500, 2000);   
      
        OS_mutex_take_ms(myMutex_handle, OS_WAIT_FOREVER_MS);
        dummy_exectime(490, 510);
        OS_mutex_give(myMutex_handle);
        
        dummy_exectime(900, 1100);   
                 
        OS_delay_ms(5);
    
    }
}


void demo_kernel_tracing(void)
{/* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);    
  
    // Create queue and mutex (static storage)
    OS_queue_create(myQueue);
    OS_mutex_create(myMutex);

    // Set object names
    #ifndef __ZEPHYR__
    vTraceSetQueueName(myQueue_handle, "My Queue");
    vTraceSetMutexName(myMutex_handle, "My Mutex");
    #endif
    
    
    DEMO_PRINTF(LNBR "demo_kernel_tracing - Demonstrates RTOS tracing with TraceRecorder." LNBR
             "Halt the execution after some second, then take a snapshot" LNBR
             "of the trace buffer and view it in Tracealyzer." LNBR
             "See details in 01_tracerecorder_kernel_tracing.c." LNBR);   
    
    OS_thread_create(taskA, vTask1, NULL, 2);
    OS_thread_create(taskB, vTask2, NULL, 3);
    OS_thread_create(taskC, vTask3, NULL, 4);

    OS_delay_ms(5000);
    
    OS_thread_delete(taskB_handle);
    OS_thread_delete(taskA_handle);      
    OS_thread_delete(taskC_handle);
    
    // Delete queue and mutex
    OS_queue_delete(myQueue_handle);
    OS_mutex_delete(myMutex_handle);
    
    xTraceDisable();
}

static void dummy_exectime(int min, int max)
{
     // Some execution time variations...
     int n = min + rand() % (max-min);
     for (volatile int i = 0; i < n; i++);
}

