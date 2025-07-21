#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"
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

static QueueHandle_t xQueue = NULL;
static SemaphoreHandle_t xMutex = NULL;

static void vTask1(void *pvParameters);
static void vTask2(void *pvParameters);
static void vTask3(void *pvParameters);

static void dummy_exectime(int min, int max);
        
void vTask1(void *pvParameters)
{
    (void) pvParameters;
    
    int msg;
    
    for (;;)
    {
        // Receive dummy message from queue
        if (xQueueReceive(xQueue, &msg, portMAX_DELAY) == pdPASS)
        {

            dummy_exectime(500, 700);
            
            xSemaphoreTake(xMutex, portMAX_DELAY);
            dummy_exectime(9000, 12000);
            xSemaphoreGive(xMutex);    
            
            dummy_exectime(1000, 2000);
        }
    }
}

void vTask2(void *pvParameters)
{
    (void) pvParameters;

    TickType_t xLastWakeTime;
    const TickType_t xFrequency = pdMS_TO_TICKS(9);
    
    xLastWakeTime = xTaskGetTickCount();
    
    for (;;)
    {
        vTaskDelayUntil(&xLastWakeTime, xFrequency);

        dummy_exectime(4000, 5000);
    
        // Send dummy message to queue
        int msg = rand();
        xQueueSend(xQueue, &msg, 0);
    
    }
}

void vTask3(void *pvParameters)
{
    (void) pvParameters;
    
    for (;;)
    {        
        dummy_exectime(1500, 2000);   
      
        xSemaphoreTake(xMutex, portMAX_DELAY);
        dummy_exectime(490, 510);
        xSemaphoreGive(xMutex);
        
        dummy_exectime(900, 1100);   
                 
        vTaskDelay(pdMS_TO_TICKS(5));
    
    }
}


void demo_kernel_tracing(void)
{
    TaskHandle_t hndTask1 = NULL;
    TaskHandle_t hndTask2 = NULL;
    TaskHandle_t hndTask3 = NULL;

    /* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);    
  
    // Create queue
    xQueue = xQueueCreate(QUEUE_LENGTH, QUEUE_ITEM_SIZE);
    
    // Create mutex
    xMutex = xSemaphoreCreateMutex();

    if (xQueue == NULL || xMutex == NULL)
    {
        printf("Failed to create queue or mutex\n");
        return;
    }

    // Set object names
    vTraceSetQueueName(xQueue, "My Queue");
    vTraceSetMutexName(xMutex, "My Mutex");
    
    
    printf("\n\rdemo_kernel_tracing - Demonstrates RTOS tracing with TraceRecorder.\n\r"
             "Halt the execution after some second, then take a snapshot\n\r"
             "of the trace buffer and view it in Tracealyzer.\n\r"
             "See details in 01_tracerecorder_kernel_tracing.c.\n\r\n\r" );   
    
  
    xTaskCreate(
        vTask1,
        "vTask1",
        configMINIMAL_STACK_SIZE * 4,
        NULL,
        tskIDLE_PRIORITY + 2,
        &hndTask2
    );
    
     xTaskCreate(
        vTask2,
        "vTask2",
        configMINIMAL_STACK_SIZE * 4,
        NULL,
        tskIDLE_PRIORITY + 3,
        &hndTask1
    );
    
    
    xTaskCreate(
        vTask3,
        "vTask3",
        configMINIMAL_STACK_SIZE * 4,
        NULL,
        tskIDLE_PRIORITY + 4, 
        &hndTask3
    );
   
    vTaskDelay(pdMS_TO_TICKS(5000));
    
    vTaskDelete(hndTask1);
    vTaskDelete(hndTask2);      
    vTaskDelete(hndTask3);
    
    // Delete queue and mutex
    vQueueDelete(xQueue);
    vSemaphoreDelete(xMutex);
    
    xTraceDisable();
}

static void dummy_exectime(int min, int max)
{
     // Some execution time variations...
     int n = min + rand() % (max-min);
     for (volatile int i = 0; i < n; i++);
}
