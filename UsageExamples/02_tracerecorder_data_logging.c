#include "main.h"
#include "FreeRTOS.h"
#include "task.h"
#include "trcRecorder.h"

int ReadSensor(void);

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
    TraceStringHandle_t sensor_chn, log_chn, counter_chn, format_string;
    int counter = 1;
    
    /* All "user events" (application log messages) are connected to a User
       Event Channel. This is specified in first argument of the xTracePrint...
       logging calls. Here we register the channel names and get the handles
       in return, used in the later logging calls. */
    xTraceStringRegister("Sensor channel", &sensor_chn);
    xTraceStringRegister("Log channel", &log_chn);
    xTraceStringRegister("Counter channel", &counter_chn);
    
    /* Registers the format string for xTracePrintF1 (see below). */ 
    xTraceStringRegister("%d", &format_string);
    
    for (;;)
    {
        
        /* xTracePrintF allows for storing multiple data arguments with
        a printf-like interface, supporting integers and strings.
        This is a lot faster than printf calls, since not doing string
        formatting in runtime and not limited by slow UART baud rates. */
        xTracePrintF(sensor_chn, "%d", ReadSensor());
        
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
    
  printf(LNBR "demo_data_logging - logs simulated sensor data using TraceRecorder." LNBR
             "When halted, take a snapshot of the trace buffer and open in" LNBR
             "Percepio Tracealyzer. The sensor data is can be seen as yellow" LNBR
             "\"User Events\" in the trace view. Open the User Event Signal Plot" LNBR
             "to see a plot of the data. Double-click the data points to see highligth" LNBR
             "the corresponding user event in the trace view." LNBR
             "See details in 02_tracerecorder_data_logging.c." LNBR LNBR );
  
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
  
#include <math.h>

int ReadSensor(void)
{
    static double r = 0;

    r = r + 3.1415/16;
    
    return (int)(100 + 100*sin(r));
}
