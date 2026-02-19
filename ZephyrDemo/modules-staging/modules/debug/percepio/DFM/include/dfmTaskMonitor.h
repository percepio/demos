/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * @file
 *
 * @brief DFM TaskMonitor API
 */

#ifndef DFM_TASK_MONITOR_H
#define DFM_TASK_MONITOR_H

#include <dfm.h>

#if ((DFM_CFG_ENABLED) >= 1)

#include <stdint.h>
/* The task monitor functionality requires Percepio TraceRecorder */
#include <trcRecorder.h>

#ifdef __cplusplus
extern "C" {
#endif

#if ((TRC_CFG_ENABLE_TASK_MONITOR) >= 1)

/**
 * @defgroup dfm_task_monitor_apis DFM Task Monitor API
 * @ingroup dfm_apis
 * @{
 */

/**
 * @brief Initializes the DFM Task Monitor so it generate alerts on TaskMonitor
 * anomalies, i.e. when task has a CPU load outside the expected range.
 * This is called automatically when DFM is initialized. 
 * Call xDfmTaskMonitorRegister for each task you want to monitor, then call
 * xDfmTaskMonitorPoll periodically to perform the actual monitoring.
 * 
 * @retval TRC_SUCCESS Success
 */
void xDfmTaskMonitorInit(void);

/**
 * @brief Set a callback function to be called when a task's CPU load is outside the accepted range.
 * The function should accept a TraceTaskMonitorCallbackData_t* parameter.
 * The failing task's name and address can be retrieved using the parameter (pxData) with
 * xTraceEntryGetSymbol(pxData->xTaskHandle, &szName) and
 * xTraceEntryGetAddress(pxData->xTaskHandle, &pvAddress) respectively.
 * The task's CPU load, low limit, and high limit can be accessed through
 * pxData->uxCPULoad, pxData->uxLowLimit, and pxData->uxHighLimit.
 * 
 * Callback example:
 * void my_callback(TraceTaskMonitorCallbackData_t* pxData);
 * 
 * @param[in] xCallback Callback function.
 */
#define xDfmTaskMonitorSetCallback(xCallback) xTraceTaskMonitorSetCallback(xCallback)

/**
 * @brief Registers the task to the task monitor.
 * 
 * @param[in] pvTask Task. If NULL, the currently executing task is registered.
 * @param[in] uxLow Minimum accepted percentage CPU load.
 * @param[in] uxHigh Maximum accepted percentage CPU load.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xDfmTaskMonitorRegister(pvTask, uxLow, uxHigh) xTraceTaskMonitorRegister(pvTask, uxLow, uxHigh)

/**
 * @brief Unregister task from the task monitor.
 * 
 * @param[in] pvTask Task.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xDfmTaskMonitorUnregister(pvTask) xTraceTaskMonitorUnregister(pvTask)

/**
 * @brief Call this regularly to poll the system and check if any tasks are
 * outside the accepted range.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xDfmTaskMonitorPoll() xTraceTaskMonitorPoll()

/**
 * @brief This will reset all timestamps to start a new poll interval.
 * Only need to call this if xDfmTaskMonitorPoll() hasn't been called regularly.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xDfmTaskMonitorPollReset() xTraceTaskMonitorPollReset()


/**
 * @brief Prints the high and low watermark for the CPU load of each monitored task.
 * 
 * @retval TRC_SUCCESS Success
 */
#define xDfmTaskMonitorPrint() xTraceTaskMonitorPrint()



/** @} */

#else

/* Dummy defines */
#define xDfmTaskMonitorSetCallback(xCallback) (DFM_FAIL)
#define xDfmTaskMonitorRegister(pvTask, uxLow, uxHigh) (DFM_FAIL)
#define xDfmTaskMonitorUnregister(pvTask) (DFM_FAIL)
#define xDfmTaskMonitorPoll() (DFM_FAIL)
#define xDfmTaskMonitorPollReset() (DFM_FAIL)

#endif

#ifdef __cplusplus
}
#endif

#else

/* Dummy defines */
#define xDfmTaskMonitorSetCallback(xCallback) (DFM_FAIL)
#define xDfmTaskMonitorRegister(pvTask, uxLow, uxHigh) (DFM_FAIL)
#define xDfmTaskMonitorUnregister(pvTask) (DFM_FAIL)
#define xDfmTaskMonitorPoll() (DFM_FAIL)

#endif

#endif
