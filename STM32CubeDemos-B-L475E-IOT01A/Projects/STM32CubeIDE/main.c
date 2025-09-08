
#include "dfmStoragePort.h"
#include "main.h"
#include "stdint.h"
#include "stdarg.h"

#include "FreeRTOS.h"
#include "task.h"

#include "iot_uart.h"
#include "demo_app.h"

static void SystemClock_Config( void );
static void Console_UART_Init( void );
static void prvMiscInitialization( void );

/**
 * @brief Application runtime entry point.
 */
int main( void )
{
	/* Perform any hardware initialization that does not require the RTOS to be
     * running.  */
    prvMiscInitialization();

    demo_app();

    return 0;
}

// Hard fault in CrashCatcher, appears as an unaligned 32-bit write.
// Why has this not happened before in that case?

/*-----------------------------------------------------------*/


unsigned int selectNextDemo(void);

/* Remembers the next demo to run, even if there is a warm restart */
volatile __attribute__((section (".noinit"))) unsigned int demo_test_case_next;

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

// Need to access pxHuart...
typedef struct IotUARTDescriptor
{
    UART_HandleTypeDef * pxHuart;
    IRQn_Type eIrqNum;
    IotUARTCallback_t xUartCallback;
    void * pvUserCallbackContext;
    void* xSemphr;
    void* xSemphrBuffer;
    uint8_t sOpened;
} IotUARTDescriptor_t;

static IotUARTHandle_t xConsoleUart;


void vSTM32L475putc( void * pv, char ch );

void vSTM32L475putc( void * pv,
                     char ch )
{
    int32_t status;

    do {
        status = iot_uart_write_sync( xConsoleUart, ( uint8_t * ) &ch, 1 );
    } while( status == IOT_UART_BUSY );
}

void vSTM32L475getc( void * pv,
                     char * ch )
{
    int32_t status;
	int done = 0;

    do {
        status = iot_uart_read_sync( xConsoleUart, ( uint8_t * ) ch, 1 );
        switch (status) {
        case IOT_UART_SUCCESS:
        	done = 1;
        	break;
        case IOT_UART_INVALID_VALUE:
        	configPRINTF(("vSTM32L475getc(): IOT_UART_INVALID_VALUE"));
        	done = 1;
        	break;
        case IOT_UART_READ_FAILED:
        	configPRINTF(("vSTM32L475getc(): IOT_UART_READ_FAILED"));
        	done = 1;
        	break;
        case IOT_UART_BUSY:
        	/* keep looping */
        	break;
        case IOT_UART_FUNCTION_NOT_SUPPORTED:
        	configPRINTF(("vSTM32L475getc(): IOT_UART_FUNCTION_NOT_SUPPORTED"));
        	done = 1;
        	break;
        case IOT_UART_NOTHING_TO_CANCEL:
        case IOT_UART_WRITE_FAILED:
        default:
        	configPRINTF(("vSTM32L475getc(): unexpected status"));
        	done = 1;
        	break;
        }
    } while (!done);
}

static void prvMiscInitialization( void )
{
    HAL_Init();

    SystemClock_Config();

    // Enable fault on divide-by-zero and unaligned access
    SCB->CCR |= SCB_CCR_DIV_0_TRP_Msk | SCB_CCR_UNALIGN_TRP_Msk;

    // enable UsageFault, BusFault and MPU Fault
    SCB->SHCSR |= SCB_SHCSR_USGFAULTENA_Msk |  SCB_SHCSR_BUSFAULTENA_Msk | SCB_SHCSR_MEMFAULTENA_Msk;

    BSP_LED_Init( LED_GREEN );
    BSP_PB_Init( BUTTON_USER, BUTTON_MODE_EXTI );

    Console_UART_Init();
}


static void Console_UART_Init( void )
{
    int32_t status = IOT_UART_SUCCESS;

     xConsoleUart = iot_uart_open( 0 );
     configASSERT( xConsoleUart != NULL );

     IotUARTConfig_t xConfig =
     {
         .ulBaudrate    = 1000000,
         .xParity      = UART_PARITY_NONE,
         .ucWordlength  = UART_WORDLENGTH_8B,
         .xStopbits    = UART_STOPBITS_1,
         .ucFlowControl = UART_HWCONTROL_NONE
     };

     status = iot_uart_ioctl( xConsoleUart, eUartSetConfig, &xConfig );
     configASSERT( status == IOT_UART_SUCCESS );
}


char _char_from_kbhit = 0;

int kbhit(void)
{
	char ch;
	if (HAL_UART_Receive(xConsoleUart->pxHuart, (uint8_t *) &ch, 1, 0) != HAL_OK)
	{
	    return 0;
	}
	_char_from_kbhit = ch;
	return ch;
}

extern volatile int demo_isrs_enabled;

/* Reads a string from the STLINK VCOM port (could not get scanf to work) */
int get_string(char *buf)
{
  char ch;
  uint32_t count = 0;

  // Disable demo ISRs to pause the demo app during printf calls (avoids overload)...
  demo_isrs_enabled = 0;

  /* Clear pending characters */
  if (HAL_UART_AbortReceive(xConsoleUart->pxHuart) != HAL_OK)
  {
    return -1;
  }

  if (_char_from_kbhit != 0)
  {
	  buf[0] = _char_from_kbhit;
	  vSTM32L475putc(0, _char_from_kbhit);
	  count++;
  }

  if (buf[0] != '\n' && buf[0] != '\r')
  {
	  /* Repeat receiving character  */
	  do
	  {
		/* Get entered character */
		if (HAL_UART_Receive(xConsoleUart->pxHuart, (uint8_t *) &ch, 1, HAL_MAX_DELAY) != HAL_OK)
		{
		  return -2;
		}

		/* Store entered character */
		buf[count] = ch;
		count++;

		/* Print entered character */
		if (ch != 0)
		{
			vSTM32L475putc(0, ch);
		}

	  }
	  while ((ch != '\r') && (ch != 0) && (ch !='\n'));
  }
  /* Clear end of characters symbols */
  do
  {
    buf[count] = 0;
    count--;
  }
  while((buf[count] == '\r') || (buf[count] == '\n'));

  demo_isrs_enabled = 1;

  return count;
}

void Error_Handler( void )
{
    while( 1 )
    {
        BSP_LED_Toggle( LED_GREEN );
        HAL_Delay( 200 );
    }
}

void HAL_TIM_PeriodElapsedCallback( TIM_HandleTypeDef * htim )
{
    if( htim->Instance == TIM6 )
    {
        HAL_IncTick();
    }
}


static void SystemClock_Config( void )
{
    RCC_OscInitTypeDef xRCC_OscInitStruct;
    RCC_ClkInitTypeDef xRCC_ClkInitStruct;
    RCC_PeriphCLKInitTypeDef xPeriphClkInit;

    xRCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_LSE | RCC_OSCILLATORTYPE_MSI;
    xRCC_OscInitStruct.LSEState = RCC_LSE_ON;
    xRCC_OscInitStruct.MSIState = RCC_MSI_ON;
    xRCC_OscInitStruct.MSICalibrationValue = 0;
    xRCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_11;
    xRCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    xRCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_MSI;
    xRCC_OscInitStruct.PLL.PLLM = 6;
    xRCC_OscInitStruct.PLL.PLLN = 20;
    xRCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV7;
    xRCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
    xRCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;

    if( HAL_RCC_OscConfig( &xRCC_OscInitStruct ) != HAL_OK )
    {
        Error_Handler();
    }

    /* Select PLL as system clock source and configure the HCLK, PCLK1 and PCLK2
     * clocks dividers. */
    xRCC_ClkInitStruct.ClockType = ( RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK
                                     | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2 );
    xRCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    xRCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    xRCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
    xRCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

    if( HAL_RCC_ClockConfig( &xRCC_ClkInitStruct, FLASH_LATENCY_4 ) != HAL_OK )
    {
        Error_Handler();
    }

    xPeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_RTC
                                          | RCC_PERIPHCLK_USART1 | RCC_PERIPHCLK_USART3 | RCC_PERIPHCLK_I2C2
                                          | RCC_PERIPHCLK_RNG;
    xPeriphClkInit.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
    xPeriphClkInit.Usart3ClockSelection = RCC_USART3CLKSOURCE_PCLK1;
    xPeriphClkInit.I2c2ClockSelection = RCC_I2C2CLKSOURCE_PCLK1;
    xPeriphClkInit.RTCClockSelection = RCC_RTCCLKSOURCE_LSE;
    xPeriphClkInit.RngClockSelection = RCC_RNGCLKSOURCE_MSI;

    if( HAL_RCCEx_PeriphCLKConfig( &xPeriphClkInit ) != HAL_OK )
    {
        Error_Handler();
    }

    __HAL_RCC_PWR_CLK_ENABLE();

    if( HAL_PWREx_ControlVoltageScaling( PWR_REGULATOR_VOLTAGE_SCALE1 ) != HAL_OK )
    {
        Error_Handler();
    }

    /* Enable MSI PLL mode. */
    HAL_RCCEx_EnableMSIPLLMode();
}

void DemoSimulateExecutionTime(int n)
{
	for (volatile int dummy = 0; dummy < n; dummy++);
}


void HAL_GPIO_EXTI_Callback( uint16_t GPIO_Pin )
{
    if (GPIO_Pin == USER_BUTTON_PIN )
    {
    	// Blue button pressed
    }
}

