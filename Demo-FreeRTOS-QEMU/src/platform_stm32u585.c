/* Board support derived from percepio/Tracealyzer-STM32CubeIDE-SWO.
 * The original ST startup, CMSIS and HAL sources are kept in third_party.
 */

#include <stdint.h>
#include <stdio.h>

#include "FreeRTOS.h"
#include "task.h"
#include "cmsis.h"
#include "platform.h"
#include "stm32u5xx_hal.h"

#if DFM_TESTS_ENABLED
#include "dfm_tests.h"
#endif

#define DEMO_COUNT 8U
#define RETAINED_MAGIC 0x50444D4FU /* "PDMO" */

typedef struct DemoRetainedState {
    uint32_t magic;
    uint32_t next_demo;
} DemoRetainedState_t;

static volatile DemoRetainedState_t retained_state
    __attribute__((section(".noinit"), used));

/* HAL normally reserves SysTick for its millisecond time base. FreeRTOS owns
 * SysTick in this image, so prevent HAL_Init() from starting it early. */
HAL_StatusTypeDef HAL_InitTick(uint32_t tick_priority)
{
    (void)tick_priority;
    return HAL_OK;
}

void HAL_MspInit(void)
{
    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_RCC_SYSCFG_CLK_ENABLE();
    HAL_PWREx_DisableUCPDDeadBattery();
}

static int platform_clock_config(void)
{
    RCC_ClkInitTypeDef clock = {0};
    RCC_OscInitTypeDef oscillator = {0};

    if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1) != HAL_OK) {
        return -1;
    }

    oscillator.OscillatorType = RCC_OSCILLATORTYPE_MSI;
    oscillator.MSIState = RCC_MSI_ON;
    oscillator.MSICalibrationValue = RCC_MSICALIBRATION_DEFAULT;
    oscillator.MSIClockRange = RCC_MSIRANGE_0;
    oscillator.PLL.PLLState = RCC_PLL_ON;
    oscillator.PLL.PLLSource = RCC_PLLSOURCE_MSI;
    oscillator.PLL.PLLMBOOST = RCC_PLLMBOOST_DIV4;
    oscillator.PLL.PLLM = 3;
    oscillator.PLL.PLLN = 15;
    oscillator.PLL.PLLP = 2;
    oscillator.PLL.PLLQ = 2;
    oscillator.PLL.PLLR = 2;
    oscillator.PLL.PLLRGE = RCC_PLLVCIRANGE_1;
    oscillator.PLL.PLLFRACN = 0;
    if (HAL_RCC_OscConfig(&oscillator) != HAL_OK) {
        return -1;
    }

    clock.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
        RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2 | RCC_CLOCKTYPE_PCLK3;
    clock.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    clock.AHBCLKDivider = RCC_SYSCLK_DIV1;
    clock.APB1CLKDivider = RCC_HCLK_DIV1;
    clock.APB2CLKDivider = RCC_HCLK_DIV1;
    clock.APB3CLKDivider = RCC_HCLK_DIV1;
    return HAL_RCC_ClockConfig(&clock, FLASH_LATENCY_3) == HAL_OK ? 0 : -1;
}

void platform_initialize(void)
{
    HAL_Init();
    if (platform_clock_config() != 0) {
        for (;;) { }
    }

    (void)HAL_ICACHE_ConfigAssociativityMode(ICACHE_1WAY);
    (void)HAL_ICACHE_Enable();

    SCB->VTOR = FLASH_BASE;
    __DSB();
    __ISB();
}

void platform_trace_timer_initialize(void)
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
#if defined(DWT_LAR)
    DWT->LAR = 0xC5ACCE55UL;
#endif
    DWT->CYCCNT = 0U;
    DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
    __DSB();
    __ISB();
}

uint32_t platform_trace_timer_count(void)
{
    return DWT->CYCCNT;
}

void platform_test_interrupt_trigger(void)
{
    NVIC_ClearPendingIRQ(EXTI0_IRQn);
    NVIC_SetPriority(EXTI0_IRQn, 7U);
    NVIC_EnableIRQ(EXTI0_IRQn);
    NVIC_SetPendingIRQ(EXTI0_IRQn);
}

void platform_test_interrupt_cleanup(void)
{
    NVIC_DisableIRQ(EXTI0_IRQn);
    NVIC_ClearPendingIRQ(EXTI0_IRQn);
}

unsigned int selectNextDemo(void)
{
    unsigned int selected;

    if ((retained_state.magic != RETAINED_MAGIC) ||
        (retained_state.next_demo >= DEMO_COUNT)) {
        retained_state.magic = RETAINED_MAGIC;
        retained_state.next_demo = 0U;
    }

    selected = retained_state.next_demo;
    retained_state.next_demo = selected + 1U;
    return selected;
}

void vApplicationGetIdleTaskMemory(StaticTask_t **tcb,
                                   StackType_t **stack,
                                   configSTACK_DEPTH_TYPE *stack_depth)
{
    static StaticTask_t idle_tcb;
    static StackType_t idle_stack[configMINIMAL_STACK_SIZE];

    *tcb = &idle_tcb;
    *stack = idle_stack;
    *stack_depth = configMINIMAL_STACK_SIZE;
}

#if configUSE_TIMERS
void vApplicationGetTimerTaskMemory(StaticTask_t **tcb,
                                    StackType_t **stack,
                                    configSTACK_DEPTH_TYPE *stack_depth)
{
    static StaticTask_t timer_tcb;
    static StackType_t timer_stack[configTIMER_TASK_STACK_DEPTH];

    *tcb = &timer_tcb;
    *stack = timer_stack;
    *stack_depth = configTIMER_TASK_STACK_DEPTH;
}
#endif

void vApplicationMallocFailedHook(void)
{
    (void)printf("FATAL: FreeRTOS allocation failed\n");
#if DFM_TESTS_ENABLED
    dfm_tests_record_fatal(2U);
#endif
    taskDISABLE_INTERRUPTS();
#if DFM_TESTS_ENABLED
    NVIC_SystemReset();
#endif
    for (;;) { }
}

void vApplicationStackOverflowHook(TaskHandle_t task, char *task_name)
{
    (void)task;
    (void)printf("FATAL: stack overflow in %s\n", task_name);
#if DFM_TESTS_ENABLED
    dfm_tests_record_fatal(5U);
#endif
    taskDISABLE_INTERRUPTS();
#if DFM_TESTS_ENABLED
    NVIC_SystemReset();
#endif
    for (;;) { }
}

void vAssertCalled(const char *file, uint32_t line)
{
    (void)printf("FATAL: assertion at %s:%lu\n", file, (unsigned long)line);
#if DFM_TESTS_ENABLED
    dfm_tests_record_fatal(1U);
#endif
    taskDISABLE_INTERRUPTS();
#if DFM_TESTS_ENABLED
    NVIC_SystemReset();
#endif
    for (;;) { }
}
