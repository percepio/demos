#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "trcRecorder.h"

/******************************************************************************
 * 02_tracerecorder_data_logging.c
 *
 * Demonstrates the use of TraceRecorder "user events" for debug logging and 
 * logging of variable values in RTOS or BareMetal applicaions. This can be used
 * in any TraceRecorder configuration, also streaming. The default setup is
 * using the RingBuffer module intended for snapshots (memory dumps).
 *
 * For information on viewing TraceRecorder traces, please refer to
 * https://percepio.com/tracealyzer/gettingstarted or the host tool User Manual.
 *
 * The demo application logs accelerometer data and example debug events using
 * the TraceRecorder API. See TraceRecorder/include/trcPrint.h for details. 
 *
 * See also https://percepio.com/understanding-your-application-with-user-events.
 *
 * This can be used both with Tracealyzer as a stand-alone tool, and together
 * with Percepio Detect for systematic observability on errors and anomalies.
 * 
 * Learn more in main.c and at https://percepio.com/tracealyzer.
 *****************************************************************************/

void vTaskAccelerometer(void *pvParameters)
{
    (void) pvParameters;
    TraceStringHandle_t AccZ_chn, log_chn, counter_chn, format_string;
    int counter = 1;
    
    int16_t pDataXYZ[3] = {0};
    
    BSP_ACCELERO_Init();
    
    /* All "user events" (application log messages) are connected to a User
       Event Channel. This is specified in first argument of the xTracePrint...
       logging calls. Here we register the channel names and get the handles
       in return, used in the later logging calls. */
    xTraceStringRegister("AccZ channel", &AccZ_chn);
    xTraceStringRegister("Log channel", &log_chn);
    xTraceStringRegister("Counter channel", &counter_chn);
    
    /* Registers the format string for xTracePrintF1 (see below). */ 
    xTraceStringRegister("%d", &format_string);
    
    for (;;)
    {
        /* Reads accelerometer data */
        BSP_ACCELERO_AccGetXYZ(pDataXYZ);        
        
        /* xTracePrintF allows for storing multiple data arguments with
        a printf-like interface, supporting integers and strings.
        This is a lot faster than printf calls, since not doing string
        formatting in runtime and not limited by slow UART baud rates. */
        xTracePrintF(AccZ_chn, "%d", pDataXYZ[2]);
        
        if (counter % 3 == 0)
        {
            /* xTracePrintF1 is an even faster logging function suitable for data logging,
               using pre-registration of the format string and a known number of data arguments.
               There are five variants, xTracePrintF0 - xTracePrintF4, for 0-4 data arguments. */           
            xTracePrintF1(counter_chn, format_string, counter);
        }
        
        if (counter % 7 == 0)
        {
            /* xTracePrint is suitable when you only need to log a string,
               without any data arguments and registering the string first.
               This is suitable for debug events and for strings created in
               runtime, for example incoming data from a network connection. 
               For very frequent events, consider using the faster option
               xTracePrintF0 instead. */
            xTracePrint(log_chn, "Some event happened");
        }
        
        counter++;
                
        vTaskDelay(pdMS_TO_TICKS(20));
    }
}

void demo_data_logging(void)
{

  TaskHandle_t hnd = NULL;
    
  printf("\n\rdemo_data_logging - logs accelerometer data to TraceRecorder.\n\r"
             "Physically move the board and then halt quickly. When halted, take a snapshot\n\r"
             "of the trace buffer and open in Percepio Tracealyzer. The sensor data is can be\n\r"
             "seen as yellow \"User Events\" and is also plotted in the User Event Signal Plot.\n\r"
             "See details in 02_tracerecorder_data_logging.c.\n\r\n\r" );
  
  /* Resets and start the TraceRecorder tracing. */
  xTraceEnable(TRC_START);    
  
  xTaskCreate(
      vTaskAccelerometer,
      "vTaskAccelerometer",
      configMINIMAL_STACK_SIZE*4,
      NULL,
      tskIDLE_PRIORITY + 1,
      &hnd
  );
  
  vTaskDelay(5000);
  
  vTaskDelete(hnd);
  
  xTraceDisable();
}
  
