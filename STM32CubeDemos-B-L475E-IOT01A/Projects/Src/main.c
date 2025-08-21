
/******************************************************************************
 * main.c - Demo of Percepio Tracealyzer and Detect on STM32L4 (B-L475-IOT01)
 * with IAR Embedded Workbench v9.6 or later.
 *
 * This demo is structured into small examples of features and use-cases, with
 * one .c file for each example.
 * 
 * Percepio Tracealyzer (https://percepio.com/tracealyzer)
 * 
 * Tracealyzer is an advanced trace viewer that displays event traces from the
 * TraceRecorder library. This captures RTOS kernel events like
 * thread scheduling, API calls and also supports user-defined
 * logging with "user events". In this demo, it is configured to store FreeRTOS
 * events to a circular RAM buffer that can be dumped by the debugger. This is
 * achived by using the RingBuffer streamport module. Other streamport modules
 * allows for continuous trace streaming with IAR and other development tools. 
 * 
 * With IAR Embedded Workbench, you can save such RingBuffer snapshots using the
 * macro file "save_trace_buffer.mac". This is already included in this demo. 
 * 
 * To add this in other IAR projects, follow these steps:
 *
 *  1. Open Project -> Options -> Debugger -> Setup -> Setup macros. 
 *     Enable the "Setup macro(s) option and select save_trace_buffer.mac.
 *
 *  2. In the debug session, select View -> Macros -> Debugger Macros. Find 
 *    "save_trace_buffer", right-click and select “Add to Quicklaunch window”. 
 *
 *  3. In the Quicklaunch window, double-click on the “refresh” icon to save the trace.
 *
 *  4. Locate the resulting file trace.hex and open this in Tracealyzer.
 *     
 *     Note that the file will be overwritten each time you run the macro, 
 *     unless you manually save a copy. Tracealyzer detects when the file is 
 *     updated and will ask if to reload the trace file.
 *
 *
 * Percepio Detect (https://percepio.com/detect)
 *
 * Detect is a team solution for collaborative debugging of crashes and anomalies
 * during continuous integration testing and in the field. Detect provides automated 
 * monitoring, detection and reporting of issues, with integrated post-mortem
 * debugging support by Tracealyzer (using TraceRecorder) and GDB.
 * 
 * This demo project includes the target-side library of Percepio Detect, DFM.
 * DFM provides an API for sending "alerts" to the Detect server on errors and
 * other anomalies. This does not require direct connectivity from the device to
 * the Detect server as the DFM data can be logged to a file and processed on a
 * host computer.
 *
 * The "alerts" provided by DFM are machine-readable error reports, containing
 * metadata about the issue and debug data captured at the error. This includes
 * a small core dump with the function call stack, as well as a TraceRecorder
 * trace providing the most recent events. 
 * 
 * Viewer tools such as Tracealyzer and a core dump viewer are integrated in the
 * Detect client and launched when clicking on links in the Detect dashboard.
 * 
 * The output interface of DFM is defined by dfmCloudPort.c. In this case it is
 * using ITM over SWO , which is logged to a file by IAR Embedded Workbench.
 * 
 * How to run the Detect Demo with IAR Embedded Workbench:
 * 
 * 1. Start a debug session and open SWO Configuration.
 * 
 * 2. Under ITM Stimulus Ports:
 *     - Enabled Ports: Make sure Port 2 is enabled (third from the right)
 *     - To Log File: Select port 2 (only) and set the output file (ITM.bin).
 *
 * 3. Under Clock Setup, review the SWO speed setting. If using an STLINK v2
 *    onboard debugger, it is recommended to limit the SWO clock to 500 KHz to
 *    avoid risk of data errors in the SWO transmission. If using an IAR i-jet
 *    it should be safe to use a much higher SWO clock.
 *
 * 4. Run the application from the IAR debugger and view the Terminal I/O window
 *    until you see notices of alerts. You should now have DFM data in your ITM
 *    log file.
 *
 * 5. Process the ITM log file using the script bin2alerts.py. This is 
 *    found under "percepio-receiver" in the Percepio Detect folder.
 *
 *      Example:
 *      python bin2alerts.py path/to/ITM.bin -d MyDeviceName -f path/to/alert-files
 *
 *    This will create alert files (often several per alert) for the Percepio
 *    Detect server. Note that the final argument (-f) should match the server's
 *    alert folder, configured in the server start script.
 *  
 *    To see all details in the DFM data, add the -v (verbose) flag. This can
 *    be useful for troubleshooting but is normally not needed.
 *
 *****************************************************************************/


/* Includes ------------------------------------------------------------------*/
#include "main.h"

#include "dfm.h"
#include "dfmCrashCatcher.h"

#include "FreeRTOS.h"
#include "task.h"

#include "trcRecorder.h"

/** @addtogroup STM32L4xx_HAL_Examples
  * @{
  */

/** @addtogroup BSP
  * @{
  */

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
extern UART_HandleTypeDef hDiscoUart;
#ifdef __GNUC__
/* With GCC/RAISONANCE, small msg_info (option LD Linker->Libraries->Small msg_info
   set to 'Yes') calls __io_putchar() */
#define PUTCHAR_PROTOTYPE int __io_putchar(int ch)
#define GETCHAR_PROTOTYPE int __io_getchar(void)
#else
//#define PUTCHAR_PROTOTYPE int fputc(int ch, FILE *f)
#define GETCHAR_PROTOTYPE int fgetc(FILE *f)
#endif /* __GNUC__ */

/* Private function prototypes -----------------------------------------------*/
static void SystemClock_Config(void);
static void InitUART(void);
static unsigned int selectNextDemo(void);
void test_core_dump(int a, int b, int c, int d, int e);

void vTaskDemoDriver(void *pvParameters);

extern void demo_kernel_tracing(void);
extern void demo_data_logging(void);
extern void demo_state_logging(void);
extern void demo_custom_alert(void);
extern void demo_crash_alert(void);
extern void demo_taskmonitor_alert(void);
extern void demo_stopwatch_alert(void);
extern void demo_stack_corruption_alert(void);

#define NUMBER_OF_DEMOS 8

/* Remembers the next demo to run, even if there is a warm restart */
volatile __attribute__((section (".noinit"))) unsigned int demo_test_case_next;
   
int main(void)
{

  HAL_Init();
  SystemClock_Config();
  BSP_LED_Init(LED2); 
  BSP_PB_Init(BUTTON_USER, BUTTON_MODE_GPIO);
  InitUART();
  BSP_COM_Init(COM1, &hDiscoUart);
  
  printf("Initializing TraceRecorder library.\n\r");
  if (xTraceInitialize() == TRC_FAIL)
  {
      printf("\n\r  ERROR: TraceRecorder failed to initialize\n\r");
  }
   
  printf("Initializing DFM library for Percepio Detect.\n\r");
  if (xDfmInitializeForLocalUse() == DFM_FAIL)
  {
      printf("\n\r  ERROR: DFM failed to initialize\n\r");
  }
  
#if (0)
  // Test
  DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from main()", 0);
#endif
  
  xTaskCreate(
      vTaskDemoDriver,             
      "DemoDriver",            
      configMINIMAL_STACK_SIZE*4,
      NULL,               // Parameter
      tskIDLE_PRIORITY,
      NULL                // Task handle
  );
    
  printf("Starting FreeRTOS\n");  
  vTaskStartScheduler();
  
  while (1)
  {   
    /* Should not get here*/
  }
}

// #define UNIT_TEST 100

void vTaskDemoDriver(void *pvParameters)
{
    (void) pvParameters;
    
    DFM_STACK_MARKER();
    
    printf("\n\rPercepio demo starting up\n\r");
    
    for (;;)
    {     
        unsigned int demoToRun = selectNextDemo();
        printf("\n\r----------------------------------------\n\r");
        printf("\n\rRunning demo example %d\n\r", demoToRun);
        
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

        /*** For testing only ***/
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
              
                printf("Float value: %lf\n", f3);              
                DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from Task", 0);                
              }
              break;
              
        }
        
        vTaskDelay(pdMS_TO_TICKS(1000));  // delay 1 second before the next example.
    }
}

void test_core_dump(int a, int b, int c, int d, int e)
{
    volatile int sum;    
    sum = a+b+c+d+e;
    DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from Task", 0);
}

void vApplicationTickHook( void )
{
#if (0)
  // Test
  if (xTaskGetTickCount() == 500)
  {
      DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Test from SysTick exception", 0);
  }
#endif  
}

static unsigned int selectNextDemo(void)
{    
#ifdef UNIT_TEST
    return UNIT_TEST;
#else
    unsigned int ret;
    if (demo_test_case_next > NUMBER_OF_DEMOS) // Uninitialized after cold start, possibly junk value.
    {
        ret = 0;
        demo_test_case_next = 1; 
    }
    else
    {
        ret = demo_test_case_next;
        demo_test_case_next = (demo_test_case_next + 1) % NUMBER_OF_DEMOS;
    }
    return ret;
#endif
    
}    


static void InitUART(void)
{
  hDiscoUart.Instance = DISCOVERY_COM1; 
  hDiscoUart.Init.BaudRate = 115200;
  hDiscoUart.Init.WordLength = UART_WORDLENGTH_8B;
  hDiscoUart.Init.StopBits = UART_STOPBITS_1;
  hDiscoUart.Init.Parity = UART_PARITY_NONE;
  hDiscoUart.Init.Mode = UART_MODE_TX_RX;
  hDiscoUart.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  hDiscoUart.Init.OverSampling = UART_OVERSAMPLING_16;
  hDiscoUart.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  hDiscoUart.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
}

static void SystemClock_Config(void)
{
  RCC_ClkInitTypeDef RCC_ClkInitStruct;
  RCC_OscInitTypeDef RCC_OscInitStruct;

  /* MSI is enabled after System reset, activate PLL with MSI as source */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_6;
  RCC_OscInitStruct.MSICalibrationValue = RCC_MSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_MSI;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 40;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLP = 7;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if(HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    /* Initialization Error */
    while(1);
  }
  
  /* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2 
     clocks dividers */
  RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;  
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;  
  if(HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    /* Initialization Error */
    while(1);
  }
}

/**
  * @brief  Gets numeric values from the Hyperterminal.
  * @param  Maximum value allowed (value)
  * @retval The character received
  */
uint32_t Serial_Scanf(uint32_t value)
{
  uint16_t tmp = 0;
  
  tmp = getchar();
  
  if (tmp > value)
  {
    printf("\n\r  !!! Please enter valid number between 0 and %lu \n", value);
    return 0xFF;
  }
  return tmp;
}

#if (0)

/**
  * @brief Retargets the C library msg_info function to the USART.
  * @param None
  * @retval None
  */

PUTCHAR_PROTOTYPE
{
  /* Place your implementation of fputc here */
  /* e.g. write a character to the serial port and Loop until the end of transmission */
  while (HAL_OK != HAL_UART_Transmit(&hDiscoUart, (uint8_t *) &ch, 1, 30000))
  {
    ;
  }
  return ch;
}

#endif

/**
  * @brief Retargets the C library scanf function to the USART.
  * @param None
  * @retval None
  */
GETCHAR_PROTOTYPE
{
  /* Place your implementation of fgetc here */
  /* e.g. readwrite a character to the USART2 and Loop until the end of transmission */
  uint8_t ch = 0;
  while (HAL_OK != HAL_UART_Receive(&hDiscoUart, (uint8_t *)&ch, 1, 30000))
  {
    ;
  }
  return ch;
}

#include <yfuns.h>     // Required for __write declaration
#include "stm32l4xx_hal.h"

#if (0)
size_t __write(int handle, const unsigned char *buf, size_t size)
{
    // Only support stdout (handle 1) and stderr (handle 2)
    if (handle != _LLIO_STDOUT && handle != _LLIO_STDERR)
        return _LLIO_ERROR;

    HAL_UART_Transmit(&hDiscoUart, (uint8_t *)buf, size, HAL_MAX_DELAY);
    return size;
}

#endif

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    printf("Stack overflow in task: %s\n", pcTaskName);

    taskDISABLE_INTERRUPTS();
    for (;;);
}

void vApplicationMallocFailedHook(void)
{    
    printf("Malloc failed!\n");

    taskDISABLE_INTERRUPTS();
    for (;;);
}


/**
  * @brief  This function is executed in case of error occurrence.
  * @param  None
  * @retval None
  */
void Error_Handler(void)
{  
  /* User can add his own implementation to report the HAL error return state */
  printf("!!! ERROR !!!\n");
  while(1) 
  {
  }
}

#ifdef  USE_FULL_ASSERT

/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line)
{ 
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */

  /* Infinite loop */
  while (1)
  {
  }
}
#endif

/**
  * @}
  */ 

/**
  * @}
  */ 

