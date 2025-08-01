/*
 * Trace Recorder for Tracealyzer v989.878.767
 * Copyright 2025 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Configuration parameters for the kernel port.
 * More settings can be found in trcKernelPortStreamingConfig.h and
 * trcKernelPortSnapshotConfig.h.
 */

#ifndef TRC_KERNEL_PORT_CONFIG_H
#define TRC_KERNEL_PORT_CONFIG_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @def TRC_CFG_FREERTOS_VERSION
 * @brief Specify what version of FreeRTOS that is used (don't change unless using the
 * trace recorder library with an older version of FreeRTOS).
 *
 * TRC_FREERTOS_VERSION_7_3_X				If using FreeRTOS v7.3.X
 * TRC_FREERTOS_VERSION_7_4_X				If using FreeRTOS v7.4.X 
 * TRC_FREERTOS_VERSION_7_5_X				If using FreeRTOS v7.5.X
 * TRC_FREERTOS_VERSION_7_6_X				If using FreeRTOS v7.6.X
 * TRC_FREERTOS_VERSION_8_X_X				If using FreeRTOS v8.X.X
 * TRC_FREERTOS_VERSION_9_0_0				If using FreeRTOS v9.0.0
 * TRC_FREERTOS_VERSION_9_0_1				If using FreeRTOS v9.0.1
 * TRC_FREERTOS_VERSION_9_0_2				If using FreeRTOS v9.0.2
 * TRC_FREERTOS_VERSION_10_0_0				If using FreeRTOS v10.0.0
 * TRC_FREERTOS_VERSION_10_0_1				If using FreeRTOS v10.0.1
 * TRC_FREERTOS_VERSION_10_1_0				If using FreeRTOS v10.1.0
 * TRC_FREERTOS_VERSION_10_1_1				If using FreeRTOS v10.1.1
 * TRC_FREERTOS_VERSION_10_2_0				If using FreeRTOS v10.2.0
 * TRC_FREERTOS_VERSION_10_2_1				If using FreeRTOS v10.2.1
 * TRC_FREERTOS_VERSION_10_3_0				If using FreeRTOS v10.3.0
 * TRC_FREERTOS_VERSION_10_3_1				If using FreeRTOS v10.3.1
 * TRC_FREERTOS_VERSION_10_4_0				If using FreeRTOS v10.4.0
 * TRC_FREERTOS_VERSION_10_4_1				If using FreeRTOS v10.4.1
 * TRC_FREERTOS_VERSION_10_4_2				If using FreeRTOS v10.4.2
 * TRC_FREERTOS_VERSION_10_4_3				If using FreeRTOS v10.4.3
 * TRC_FREERTOS_VERSION_10_5_0				If using FreeRTOS v10.5.0
 * TRC_FREERTOS_VERSION_10_5_1				If using FreeRTOS v10.5.1
 * TRC_FREERTOS_VERSION_10_6_0				If using FreeRTOS v10.6.0
 * TRC_FREERTOS_VERSION_10_6_1				If using FreeRTOS v10.6.1
 * TRC_FREERTOS_VERSION_10_6_2				If using FreeRTOS v10.6.2
 * TRC_FREERTOS_VERSION_11_0_0				If using FreeRTOS v11.0.0
 * TRC_FREERTOS_VERSION_11_0_1				If using FreeRTOS v11.0.1
 * TRC_FREERTOS_VERSION_11_1_0				If using FreeRTOS v11.1.0 or later
 */
#define TRC_CFG_FREERTOS_VERSION TRC_FREERTOS_VERSION_11_1_0

/**
 * @def TRC_CFG_INCLUDE_EVENT_GROUP_EVENTS
 * @brief Macro which should be defined as either zero (0) or one (1).
 *
 * If this is zero (0), the trace will exclude any "event group" events.
 *
 * Default value is 0 (excluded) since dependent on event_groups.c
 */
#define TRC_CFG_INCLUDE_EVENT_GROUP_EVENTS 0

/**
 * @def TRC_CFG_INCLUDE_TIMER_EVENTS
 * @brief Macro which should be defined as either zero (0) or one (1).
 *
 * If this is zero (0), the trace will exclude any Timer events.
 *
 * Default value is 0 since dependent on timers.c
 */
#define TRC_CFG_INCLUDE_TIMER_EVENTS 0

/**
 * @def TRC_CFG_INCLUDE_PEND_FUNC_CALL_EVENTS
 * @brief Macro which should be defined as either zero (0) or one (1).
 *
 * If this is zero (0), the trace will exclude any "pending function call" 
 * events, such as xTimerPendFunctionCall().
 *
 * Default value is 0 since dependent on timers.c
 */
#define TRC_CFG_INCLUDE_PEND_FUNC_CALL_EVENTS 0

/**
 * @def TRC_CFG_INCLUDE_STREAM_BUFFER_EVENTS
 * @brief Macro which should be defined as either zero (0) or one (1).
 *
 * If this is zero (0), the trace will exclude any stream buffer or message
 * buffer events.
 *
 * Default value is 0 since dependent on stream_buffer.c (new in FreeRTOS v10)
 */
#define TRC_CFG_INCLUDE_STREAM_BUFFER_EVENTS 0

/**
 * @def TRC_CFG_ACKNOWLEDGE_QUEUE_SET_SEND
 * @brief When using FreeRTOS v10.3.0 or v10.3.1, please make sure that the trace
 * point in prvNotifyQueueSetContainer() in queue.c is renamed from
 * traceQUEUE_SEND to traceQUEUE_SET_SEND in order to tell them apart from
 * other traceQUEUE_SEND trace points. Then set this to TRC_ACKNOWLEDGED.
 */
#define TRC_CFG_ACKNOWLEDGE_QUEUE_SET_SEND  0 /* TRC_ACKNOWLEDGED */

/**
 * @def TRC_CFG_KERNEL_PORT_TASK_MONITOR_TLS_INDEX
 * @brief The index used for TraceTaskMonitorTaskData_t* in Thread Local Storage.
 */
#define TRC_CFG_KERNEL_PORT_TASK_MONITOR_TLS_INDEX 0

#ifdef __cplusplus
}
#endif

#endif /* TRC_KERNEL_PORT_CONFIG_H */
