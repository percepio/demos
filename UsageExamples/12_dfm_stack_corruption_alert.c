/******************************************************************************
 * 12_dfm_stack_corruption_alert.c
 *
 * Demonstrates how stack corruption can be reported using Percepio Detect. The
 * demo code has a buffer overrun bug where data is written past the end of the
 * memory buffer. This is detected using compiler features for stack checking
 * and DFM automatically report such violations as alerts to Percepio Detect.
 *
 * DFM alerts are machine-readable error reports, containing metadata about the
 * issue and debug data captured at the error, including a small core dump
 * with the call-stack trace, as well as a TraceRecorder trace providing the
 * most recent events. Viewer tools are integrated in the Detect client and
 * launched when clicking on the "payload" links in the Detect dashboard.
 *
 * If using Zephyr, enable the stack checks by adding this to prj.conf:
 *  CONFIG_ENTROPY_GENERATOR=y 
 *  CONFIG_STACK_CANARIES_STRONG=y
 * 
 * Otherwise, if using gcc or clang, apply the compiler option
 * -fstack-protector-strong.
 * See https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
 *
 * If using IAR, enable "Stack protection" in project options (found under
 * C/C++ Compiler -> Code). See also the IAR C/C++ Development Guide.
 *
 * Learn more in main.c and at https://percepio.com/detect
 *****************************************************************************/

#include "main.h"

/* Percepio includes */
#include "trcRecorder.h"
#include "dfm.h"
#include "osal.h"

static TraceStringHandle_t demo_log_chn;

int readTooMuchData(char* data, int max_size);

int readTooMuchData(char* data, int max_size)
{
    int i, len;
    char* incomingdata = "Incoming data...";
    
    xTracePrintF(demo_log_chn, "readTooMuchData(0x%08X, %d)", data, max_size);
    
    len = strlen(incomingdata);    
    if (len > max_size)
      return -1;
    
    i = 0;
    
    while (i <= max_size+1) // Bug here, causing buffer overrun...
    {
      data[i] = incomingdata[i];
      i++;
    }
        
    return i;
}

void test_stack_corruption(void)
{
  char buffer[16];
  int bytesWritten; 
  
  bytesWritten = readTooMuchData(buffer, sizeof(buffer));
  
  xTracePrintF(demo_log_chn, "Bytes written: %d", bytesWritten);  
}
 
void demo_stack_corruption_alert(void)
{  
    
    
    /* Note: The DFM library is initialized in main.c. */
    
    DEMO_PRINTF(LNBR "demo_stack_corruption_alert - Shows how stack corruption can be reported" LNBR
           "using Percepio Detect. This relies on commonly available compiler features for" LNBR
           "stack checking, supported by e.g. gcc, clang and IAR." LNBR
           "When the DFM data has been ingested by the Detect receiver, an alert will appear" LNBR
           "in the dashboard, with a Tracealyzer trace and a core dump providing" LNBR
           "the function call stack, arguments and local variables." LNBR
           "See details in 12_dfm_stack_corruption_alert.c." LNBR);
  
    OS_delay_ms(2500);    
    
    /* Resets and start the TraceRecorder tracing. */
    xTraceEnable(TRC_START);
    
    xTraceStringRegister("Demo Log", &demo_log_chn);
        
    test_stack_corruption();
    
    xTraceDisable();
}
