
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
#include "demo_app.h"
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

void test_core_dump(int a, int b, int c, int d, int e);

/* Remembers the next demo to run, even if there is a warm restart */
volatile __attribute__((section (".noinit"))) unsigned int demo_test_case_next;

#define DEMO_MODE 0
#define TEST_MODE 1

#define APP_MODE DEMO_MODE

int main(void)
{
    HAL_Init();
    SystemClock_Config();
    BSP_LED_Init(LED2); 
    BSP_PB_Init(BUTTON_USER, BUTTON_MODE_GPIO);
    InitUART();
    BSP_COM_Init(COM1, &hDiscoUart);
  
#if (APP_MODE == DEMO_MODE)
    demo_app();
#elif (APP_MODE == TEST_MODE)
    extern void test_app(void);
    test_app();
#else
    #error Bad APP_MODE
#endif
  
}


unsigned int selectNextDemo(void)
{    
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

