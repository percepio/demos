/******************************************************************************
 * demo_app.c
 * Common demo application (shared between projects). 
 * 
 * Copyright (c) Percepio AB, 2025
 *****************************************************************************/ 

#include "demo_app.h"
#include "main.h"
#include "dfm.h"
#include "dfmCrashCatcher.h"
#include "FreeRTOS.h"
#include "task.h"
#include "trcRecorder.h"


/* Test cases:
 0-7: Same as Demo App examples
 100: Core dump from DFM_TRAP in function with 5 args (5th on stack)
 101: Core dump with floating point variables on stack (float, double)
 102: DFM_TRAP called from main context (MSP stack but no exception)
 103: DFM_TRAP called from exception context (OS tick hook, in Systick handler)
*/

#define TEST_CASE 0

void test_core_dump(int a, int b, int c, int d, int e);

static void vTaskDemoDriver(void *pvParameters)
{
    (void) pvParameters;
    
    /* (Optional) For Percepio Detect, you can put DFM_STACK_MARKER first in
       each entry function to avoid including unrelated memory in core dumps, 
       on fault exceptions or DFM_TRAP calls. Adds 12 bytes to the stack.
       This minimizes the core dump size and avoids warnings from the call
       stack unwinding due to extra data. */
    DFM_STACK_MARKER();
    
    printf(LNBR "Test application starting up" LNBR);
    
    for (;;)
    {     
        unsigned int testToRun = TEST_CASE;
        printf(LNBR "----------------------------------------" LNBR);
        printf(LNBR "Running test case %d" LNBR, testToRun);
        
        switch(testToRun)
        {
          
            case 0: 
                demo_kernel_tracing(); 
                break;
              
            case 1: 
                demo_data_logging(); 
                break;

            case 2:
                demo_state_logging();
                break;              
            
            case 3:       
               demo_crash_alert();
               break;                
                
            case 4:
               demo_custom_alert();
               break;
               
            case 5:       
               demo_stack_corruption_alert();
               break;
              
            case 6:
               demo_stopwatch_alert();
               break;
            
            case 7:     
               demo_taskmonitor_alert();
               break;

        
           case 100:
               // DFM_TRAP called inside.
               test_core_dump(1,2,3,4,5);
               break;
               
           case 101:
           {
               // Test with floating point values on the stack.
               volatile float f1=3;
               volatile double f2=2;              
               volatile double f3 = (double)f1/f2;
              
               printf("Float value: %lf" LNBR, f3);              
               DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from task context", 0);                
           }
           break;
           
           case 102: // DFM_TRAP was already called from main.
           case 103: // DFM_TRAP will be called from tick hook (i.e. in exception context)
             
                while(1); // No action needed in the task, just spin here.                
        }
        
        vTaskDelay(pdMS_TO_TICKS(1000));  // delay 1 second before the next test.
    }
}
                                                                              
void test_core_dump(int a, int b, int c, int d, int e)
{
    volatile int sum;    
    sum = a+b+c+d+e;
    DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "test_core_dump", 0);
}

void test_app(void)
{  
  printf("Enabling TraceRecorder library." LNBR);
  if (xTraceEnable(TRC_START) == TRC_FAIL)
  {
      printf(LNBR "  ERROR: TraceRecorder failed to enable." LNBR);
  }
   
  printf("Initializing DFM library for Percepio Detect." LNBR);
  if (xDfmInitializeForLocalUse() == DFM_FAIL)
  {
      printf(LNBR "  ERROR: DFM failed to initialize." LNBR);
  }
  
#if (TEST_CASE == 102)
  DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from main context", 0);
#endif
  
  /* Uses a single task to run the demos and tests. */
  xTaskCreate(
      vTaskDemoDriver,             
      "DemoDriver",            
      configMINIMAL_STACK_SIZE*4, /* Larger than necessary. */
      NULL,
      tskIDLE_PRIORITY+1,
      NULL
  );
    
  printf("Starting FreeRTOS" LNBR);  
  vTaskStartScheduler();
  
  while (1)
  {   
    /* Should not get here*/
  }
}

// Assumes configUSE_TICK_HOOK is enabled in FreeRTOSConfig.h
void vApplicationTickHook( void )
{
  #if (TEST_CASE == 103)  
  int tick = xTaskGetTickCount();
  if (tick > 0 && xTaskGetTickCount() % 1500 == 0)
  {
      DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from Exc context", 0); 
  }
  #endif  
}
