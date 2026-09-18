#include <stdint.h>
#include <stdio.h>

#include "FreeRTOS.h"
#include "task.h"
#include "cmsis.h"
#include "platform.h"

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

extern const uint32_t * const isr_vector[];

void platform_initialize(void)
{
    SCB->VTOR = (uint32_t)(uintptr_t)isr_vector;
    __DSB();
    __ISB();
}

void platform_trace_timer_initialize(void)
{
    CMSDK_TIMER0->CTRL = 0U;
    CMSDK_TIMER0->INTCLEAR = 1U;
    CMSDK_TIMER0->RELOAD = UINT32_MAX;
    CMSDK_TIMER0->CTRL = CMSDK_TIMER_CTRL_EN_Msk;
}

uint32_t platform_trace_timer_count(void)
{
    return UINT32_MAX - CMSDK_TIMER0->VALUE;
}

void platform_test_interrupt_trigger(void)
{
    NVIC_ClearPendingIRQ(PORT0_7_IRQn);
    NVIC_SetPriority(PORT0_7_IRQn, 7U);
    NVIC_EnableIRQ(PORT0_7_IRQn);
    NVIC_SetPendingIRQ(PORT0_7_IRQn);
}

void platform_test_interrupt_cleanup(void)
{
    NVIC_DisableIRQ(PORT0_7_IRQn);
    NVIC_ClearPendingIRQ(PORT0_7_IRQn);
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
