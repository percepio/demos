#include "main.h"
#include "dfm.h"
//#include "dfmCrashCatcher.h"
//#include "FreeRTOS.h"
//#include "task.h"

/******************************************************************************
 * 11_dfm_custom_alert.c
 *
 * Demonstrates custom alerts for Percepio Detect. In this example, an ASSERT
 * macro fails because of a bad argument. This calls DFM_TRAP to output an alert
 * via the Percepio Detect API (the DFM library).
 *
 * DFM alerts are machine-readable error reports, containing metadata about the
 * issue and debug data captured at the error, including a small core dump
 * with the call-stack trace, as well as a TraceRecorder trace providing the
 * most recent events. Viewer tools are integrated in the Detect client and
 * launched when clicking on the "payload" links in the Detect dashboard.
 * 
 * Learn more in main.c and at https://percepio.com/detect.
 *****************************************************************************/

// Used for TraceRecorder application logging
static TraceStringHandle_t demo_log_chn;

// Can be used in asserts like this:
// #define ASSERT(x, msg, ret) if(!(x)) { DFM_TRAP(DFM_TYPE_ASSERT_FAILED, msg, 0); return ret;}

int functionY(int arg1)
{
   if(arg1 < 0)  // Or use an ASSERT macro like above, but this is clearer.
   {
     /*************************************************************************
      * Output an "alert" from DFM to Percepio Detect (core dump and trace).
      * Third argument is if to restart (=1) or not (=0). 
      ************************************************************************/
//     DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Assert failed, arg1 negative", 0);
     
     return -1;
   }
   
   xTracePrintF(demo_log_chn, "In functionY(%d)\n", arg1);
   
   return arg1;
}

int functionX(int a, int b)
{
   if (a > b)
   {
     return functionY(a);
   }
   else
   {
     return functionY(b);
   }  
}
  
void demo_custom_alert(void)
{  
   int ret;
   
   /* Note: The DFM library is initialized in main.c. */
   
   DEMO_PRINTF(LNBR "demo_custom_alert.c - Programmatic reporting of runtime error" LNBR
           "(bad function argument) emitting a DFM alert using DFM_TRAP()." LNBR     
           "When the DFM data has been ingested by the Detect receiver, an alert will appear" LNBR
           "in the dashboard, with a Tracealyzer trace and a core dump providing" LNBR
           "the function call stack, arguments and local variables." LNBR
           "See details in 11_dfm_custom_alert.c." LNBR LNBR);
   
   OS_delay_ms(3500);
   
   /* Resets and start the TraceRecorder tracing. */
   xTraceEnable(TRC_START);
   
   OS_delay_ms(1);

   xTraceStringRegister("Demo Log", &demo_log_chn);
      
   xTracePrint(demo_log_chn, "Case 1");   
   ret = functionX(3, 4); // Valid function arguments
   xTracePrintF(demo_log_chn, "Return value: %d", ret);
      
   xTracePrint(demo_log_chn, "Case 2");
   ret = functionX(-1, -3); // Invalid arguments, triggering an ASSERT -> DFM alert.
   xTracePrintF(demo_log_chn, "Return value: %d", ret);
   
   xTraceDisable();
    
}
  