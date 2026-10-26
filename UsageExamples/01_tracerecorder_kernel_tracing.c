#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#include "osal.h"

#ifndef LNBR
#define LNBR "\n"
#endif

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

static void dummy_exectime_us(uint32_t min_us, uint32_t max_us);

/* Thread storage (stack size in bytes) */
OS_THREAD_STORAGE(Task1, 1024);
OS_THREAD_STORAGE(Task2, 1024);
OS_THREAD_STORAGE(Task3, 1024);


void vTask1(void *pvParameters)
{
    (void) pvParameters;
    
    int msg;
    
    for (;;)
    {
        // Receive dummy message from queue
        if (OS_queue_recv_ms(myQueue_handle, &msg, OS_WAIT_FOREVER_MS) == 1)
        {

            dummy_exectime_us(675U, 765U);
            
            OS_mutex_take_ms(myMutex_handle, OS_WAIT_FOREVER_MS);
            dummy_exectime_us(135U, 225U);
            OS_mutex_give(myMutex_handle);    
            
            dummy_exectime_us(135U, 180U);
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

        dummy_exectime_us(450U, 675U);
    
        // Send dummy message to queue
        int msg = rand();
        OS_queue_send_ms(myQueue_handle, &msg, 0);

        dummy_exectime_us(225U, 315U);
    
    }
}

void vTask3(void *pvParameters)
{
    (void) pvParameters;
    
    for (;;)
    { 
        
        for (int i=0; i<8; i++)
        {
            dummy_exectime_us(270U, 360U);
        
            OS_mutex_take_ms(myMutex_handle, OS_WAIT_FOREVER_MS);
            dummy_exectime_us(220U, 230U);
            OS_mutex_give(myMutex_handle);        
        }   

        dummy_exectime_us(1305U, 1395U);

        OS_delay_ms(17);
    
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
    
    OS_thread_create(Task1, vTask1, NULL, 2);
    OS_thread_create(Task2, vTask2, NULL, 3);
    OS_thread_create(Task3, vTask3, NULL, 4);

    OS_delay_ms(5000);
    
    OS_thread_delete(Task1_handle);      
    OS_thread_delete(Task2_handle);
    OS_thread_delete(Task3_handle);
    
    // Delete queue and mutex
    OS_queue_delete(myQueue_handle);
    OS_mutex_delete(myMutex_handle);
    
    xTraceDisable();
}

static void dummy_exectime_us(uint32_t min_us, uint32_t max_us)
{
    /* Simulate execution time in microseconds; max_us is exclusive. */
    const uint32_t duration_us = min_us + (uint32_t)rand() % (max_us - min_us);
    OS_cpu_work_us(duration_us);
}

