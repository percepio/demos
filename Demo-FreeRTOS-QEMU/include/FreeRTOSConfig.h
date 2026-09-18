#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#include <stddef.h>
#include <stdint.h>

#define configUSE_PREEMPTION                         1
#define configUSE_TIME_SLICING                       1
#define configUSE_IDLE_HOOK                          0
#define configUSE_TICK_HOOK                          0
#if defined(DEMO_PLATFORM_STM32U585)
#define configCPU_CLOCK_HZ                           ((uint32_t)120000000U)
#else
#define configCPU_CLOCK_HZ                           ((uint32_t)25000000U)
#endif
#define configTICK_RATE_HZ                           ((TickType_t)1000U)
#define configTICK_TYPE_WIDTH_IN_BITS                TICK_TYPE_WIDTH_32_BITS
#define configMAX_PRIORITIES                         9U
#define configMINIMAL_STACK_SIZE                     256U
#define configMAX_TASK_NAME_LEN                      16U
#define configIDLE_SHOULD_YIELD                      0

#define configSUPPORT_STATIC_ALLOCATION              1
#define configSUPPORT_DYNAMIC_ALLOCATION             1
#define configTOTAL_HEAP_SIZE                        ((size_t)(128U * 1024U))
#define configAPPLICATION_ALLOCATED_HEAP              0

#define configUSE_TRACE_FACILITY                     1
#define configUSE_MUTEXES                            1
#define configUSE_RECURSIVE_MUTEXES                  0
#define configUSE_COUNTING_SEMAPHORES                0
#define configUSE_QUEUE_SETS                         0
#define configQUEUE_REGISTRY_SIZE                    16U
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS      1

#define configCHECK_FOR_STACK_OVERFLOW               2
#define configUSE_MALLOC_FAILED_HOOK                 1
#define configUSE_DAEMON_TASK_STARTUP_HOOK           0
#if DFM_TESTS_ENABLED
#define configUSE_TIMERS                             1
#define configTIMER_TASK_PRIORITY                    1U
#define configTIMER_QUEUE_LENGTH                     8U
#define configTIMER_TASK_STACK_DEPTH                 512U
#else
#define configUSE_TIMERS                             0
#endif
#define configUSE_TASK_NOTIFICATIONS                 1
#define configTASK_NOTIFICATION_ARRAY_ENTRIES        1

#define configUSE_CO_ROUTINES                        0
#define configUSE_STATS_FORMATTING_FUNCTIONS         0
#define configGENERATE_RUN_TIME_STATS                0
#define configENABLE_BACKWARD_COMPATIBILITY          0

#define INCLUDE_vTaskDelete                          1
#define INCLUDE_vTaskDelay                           1
#define INCLUDE_vTaskDelayUntil                      1
#define INCLUDE_vTaskPrioritySet                     1
#define INCLUDE_uxTaskPriorityGet                    1
#define INCLUDE_uxTaskGetStackHighWaterMark          1
#define INCLUDE_uxTaskGetStackHighWaterMark2         1
#define INCLUDE_xTaskGetSchedulerState               1
#define INCLUDE_xTaskGetIdleTaskHandle               1
#define INCLUDE_eTaskGetState                        1
#define INCLUDE_vTaskSuspend                         1
#if DFM_TESTS_ENABLED
#define INCLUDE_xTimerPendFunctionCall               1
#else
#define INCLUDE_xTimerPendFunctionCall               0
#endif

#if defined(DEMO_PLATFORM_STM32U585)
#define configPRIO_BITS                              4U
#define configLIBRARY_LOWEST_INTERRUPT_PRIORITY      15U
#define configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY 5U
#define configKERNEL_INTERRUPT_PRIORITY              \
    (configLIBRARY_LOWEST_INTERRUPT_PRIORITY << (8U - configPRIO_BITS))
#define configMAX_SYSCALL_INTERRUPT_PRIORITY         \
    (configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY << (8U - configPRIO_BITS))
#define configENABLE_MPU                             0
#define configENABLE_FPU                             1
#define configENABLE_MVE                             0
#define configENABLE_TRUSTZONE                       0
#define configRUN_FREERTOS_SECURE_ONLY               1
#define configENABLE_PAC                             0
#define configENABLE_BTI                             0
#else
/* QEMU does not model a restricted number of implemented NVIC priority bits. */
#define configKERNEL_INTERRUPT_PRIORITY              255U
#define configMAX_SYSCALL_INTERRUPT_PRIORITY         4U
#endif
#define configUSE_PORT_OPTIMISED_TASK_SELECTION      1

void vAssertCalled(const char *file, uint32_t line);
#define configASSERT(expression) \
    do { if ((expression) == 0) { vAssertCalled(__FILE__, (uint32_t)__LINE__); } } while (0)

/* Must remain last: this installs the FreeRTOS trace hooks. */
#include "trcRecorder.h"

#endif /* FREERTOS_CONFIG_H */
