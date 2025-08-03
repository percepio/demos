#include "main.h"
#include "dfm.h"
#include "dfmCrashCatcher.h"
#include "FreeRTOS.h"
#include "task.h"

/******************************************************************************
 * 10_dfm_crash_alert.c
 *
 * Demonstrates crash debugging with Percepio Detect. In this example, there is
 * a bug causing a division by zero. This trigger a UsageFault exception on the
 * processor which is captured and reported by Percepio Detect. All processor
 * fault exceptions are captured in the same way.
 *
 * The Percepio Detect target library, DFM, integrates an improved verson of the
 * CrashCatcher library. This includes a hard fault handler for Arm Cortex-M
 * devices. Originally CrashCatcher is only for gcc, but the Percepio version
 * also supports IAR.
 *
 * The fault is reported as a DFM alert, i.e. a machine-readable error report
 * that contain metadata about the issue and debug data captured at the error,
 * including a small core dump with the call-stack trace, as well as a
 * TraceRecorder trace providing the most recent events. 
 *
 * Viewer tools are integrated in the Detect client and launched when clicking
 * on the "payload" links in the Detect dashboard.
 * 
 * Learn more in main.c and at https://percepio.com/detect.
 *****************************************************************************/

typedef struct 
{
    int scale_factor;
    int offset;
    volatile uint32_t * reg;
} sensor_config;

sensor_config configs[2] = {
    { .scale_factor = 10, .offset = 5, .reg = (volatile uint32_t *) 0xE0001004},
    { .scale_factor = 1,  .offset = 0, .reg = (volatile uint32_t *) 0xE0001004}
};

#define SENSOR1 0
#define SENSOR2 1

int adjust_divisor(int scale_factor)
{
    return scale_factor / 2;
}

// Has a bug causing a divide-by-zero exception if scale_factor is 1.
int transform_sensor_value(int raw_value, int scale_factor, int offset)
{
    if(scale_factor == 0)
      return 0;
    
    int adjusted_divisor = adjust_divisor(scale_factor);
  
    return (raw_value + offset) / adjusted_divisor;
}

// Simulates some kind of sensor reading using the DWT clock cycle counter.
static int read_sensor(int index)
{   
   return (*configs[index].reg % 256);
}

// Enable divide-by-zero exceptions.
static void enable_divide_by_zero_exception(void) 
{
    SCB->CCR |= SCB_CCR_DIV_0_TRP_Msk;         // Trap on divide-by-zero
    SCB->SHCSR |= SCB_SHCSR_USGFAULTENA_Msk;   // Enable UsageFault exception
}

static TraceStringHandle_t demo_log_chn;


void demo_crash_alert(void)
{ 
    int result;
    
    /* Note: The DFM library is initialized in main.c. */
    
    enable_divide_by_zero_exception();
    
    printf(LNBR "demo_crash_alert - Crash due to UsageFault exception (div by zero)." LNBR
           "The error will be reported to Percepio Detect using the DFM library." LNBR
           "When DFM data has been ingested by the Detect receiver, an alert will appear" LNBR
           "in the dashboard, with a Tracealyzer trace and a core dump providing" LNBR       
           "the function call stack, arguments and local variables." LNBR
           "See details in 10_dfm_crash_alert.c." LNBR LNBR);
    
    vTaskDelay(3500);
    
    /* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);
    
    xTraceStringRegister("Demo Log", &demo_log_chn);
    
    vTaskDelay(1);
    
    xTracePrint(demo_log_chn, "Reading and transforming SENSOR1 value");
    result = transform_sensor_value(read_sensor(SENSOR1), configs[SENSOR1].scale_factor, configs[SENSOR1].offset);
    xTracePrintF(demo_log_chn, "Returned: %d", result);
    
    xTracePrint(demo_log_chn, "Reading and transforming SENSOR2 value");
    result = transform_sensor_value(read_sensor(SENSOR2), configs[SENSOR2].scale_factor, configs[SENSOR2].offset); 
    xTracePrintF(demo_log_chn, "Returned: %d", result); // Won't be reached due to exception causing a restart
    
    xTraceDisable(); 
}

