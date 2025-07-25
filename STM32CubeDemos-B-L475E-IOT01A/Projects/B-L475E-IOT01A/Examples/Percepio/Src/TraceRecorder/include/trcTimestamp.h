/*
* Percepio Trace Recorder for Tracealyzer v989.878.767
* Copyright 2025 Percepio AB
* www.percepio.com
*
* SPDX-License-Identifier: Apache-2.0
*/

/**
 * @file 
 * 
 * @brief Public trace timestamp APIs.
 */

#ifndef TRC_TIMESTAMP_H
#define TRC_TIMESTAMP_H

#if (TRC_USE_TRACEALYZER_RECORDER == 1)

#include <trcTypes.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup trace_timestamp_apis Trace Timestamp APIs
 * @ingroup trace_recorder_apis
 * @{
 */

/**
 * @brief Trace Timestamp Structure
 */
typedef struct TraceTimestampData	/* Aligned */
{
	uint32_t type;						/**< Timer type (direction) */
	uint32_t period;					/**< Timer Period */
	TraceUnsignedBaseType_t frequency;	/**< Timer Frequency */
	uint32_t wraparounds;				/**< Nr of timer wraparounds */
	uint32_t osTickHz;					/**< RTOS tick frequency */
	uint32_t latestTimestamp;			/**< Latest timestamp */
	uint32_t osTickCount;				/**< RTOS tick count */
} TraceTimestampData_t;

extern TraceTimestampData_t* pxTraceTimestamp;

/**
 * @internal Initialize trace timestamp system.
 * 
 * @param[in] pxBuffer Pointer to memory that will be used by the
 * trace timestamp system.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampInitialize(TraceTimestampData_t *pxBuffer);

#if ((TRC_CFG_USE_TRACE_ASSERT) == 1)

/**
 * @brief Gets current trace timestamp.
 * 
 * @param[out] puiTimestamp Timestamp.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampGet(uint32_t* puiTimestamp);

/**
 * @brief Gets trace timestamp wraparounds.
 * 
 * @param[out] puiTimerWraparounds Timer wraparounds.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampGetWraparounds(uint32_t* puiTimerWraparounds);

/**
 * @brief Sets trace timestamp frequency. 
 * 
 * @param[in] uxFrequency Frequency.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampSetFrequency(TraceUnsignedBaseType_t uxFrequency);

/**
 * @brief Gets trace timestamp frequency.
 * 
 * @param[out] puxFrequency Frequency.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampGetFrequency(TraceUnsignedBaseType_t* puxFrequency);

/**
 * @brief Sets trace timestamp period.
 * 
 * @param[in] uiPeriod Period.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampSetPeriod(uint32_t uiPeriod);

/**
 * @brief Gets trace timestamp period.
 * 
 * @param[out] puiPeriod Period.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampGetPeriod(uint32_t* puiPeriod);

/**
 * @brief Sets trace timestamp OS tick count.
 * 
 * @param[in] uiOsTickCount OS tick count.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampSetOsTickCount(uint32_t uiOsTickCount);

/**
 * @brief Gets trace timestamp OS tick count.
 * 
 * @param[in] puiOsTickCount 
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceTimestampGetOsTickCount(uint32_t *puiOsTickCount);

#else /* ((TRC_CFG_USE_TRACE_ASSERT) == 1) */

/**
 * @brief Gets current trace timestamp.
 * 
 * @param[out] puiTimestamp Timestamp.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#if ((TRC_HWTC_TYPE == TRC_FREE_RUNNING_32BIT_INCR) || (TRC_HWTC_TYPE == TRC_CUSTOM_TIMER_INCR))
#define xTraceTimestampGet(puiTimestamp) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_4(*(puiTimestamp) = TRC_HWTC_COUNT, (*(puiTimestamp) < pxTraceTimestamp->latestTimestamp) ? pxTraceTimestamp->wraparounds++ : 0, pxTraceTimestamp->latestTimestamp = *(puiTimestamp), TRC_SUCCESS)
#elif ((TRC_HWTC_TYPE == TRC_FREE_RUNNING_32BIT_DECR) || (TRC_HWTC_TYPE == TRC_CUSTOM_TIMER_DECR))
#define xTraceTimestampGet(puiTimestamp) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_4(*(puiTimestamp) = TRC_HWTC_COUNT, (*(puiTimestamp) > pxTraceTimestamp->latestTimestamp) ? pxTraceTimestamp->wraparounds++ : 0, pxTraceTimestamp->latestTimestamp = *(puiTimestamp), TRC_SUCCESS)
#elif ((TRC_HWTC_TYPE == TRC_OS_TIMER_INCR) || (TRC_HWTC_TYPE == TRC_OS_TIMER_DECR))
#define xTraceTimestampGet(puiTimestamp) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_4(*(puiTimestamp) = ((TRC_HWTC_COUNT) & 0x00FFFFFFU) + ((pxTraceTimestamp->osTickCount & 0x000000FFU) << 24), pxTraceTimestamp->wraparounds = pxTraceTimestamp->osTickCount, pxTraceTimestamp->latestTimestamp = *(puiTimestamp), TRC_SUCCESS)
#endif

/**
 * @brief Gets trace timestamp wraparounds.
 * 
 * @param[out] puiTimerWraparounds Timer wraparounds.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampGetWraparounds(puiTimerWraparounds) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(*(puiTimerWraparounds) = pxTraceTimestamp->wraparounds, TRC_SUCCESS)

/**
 * @brief Sets trace timestamp frequency. 
 * 
 * @param[in] uxFrequency Frequency.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampSetFrequency(uxFrequency) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(pxTraceTimestamp->frequency = uxFrequency, TRC_SUCCESS)

/**
 * @brief Sets trace timestamp period.
 * 
 * @param[in] uiPeriod Period.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampSetPeriod(uiPeriod) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(pxTraceTimestamp->period = uiPeriod, TRC_SUCCESS)

/**
 * @brief Sets trace timestamp OS tick count.
 * 
 * @param[in] uiOsTickCount OS tick count.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampSetOsTickCount(uiOsTickCount) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(pxTraceTimestamp->osTickCount = uiOsTickCount, TRC_SUCCESS)

/**
 * @brief Gets trace timestamp frequency.
 * 
 * @param[out] puxFrequency Frequency.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampGetFrequency(puxFrequency) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(*(puxFrequency) = pxTraceTimestamp->frequency, TRC_SUCCESS)

/**
 * @brief Gets trace timestamp period.
 * 
 * @param[out] puiPeriod Period.
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampGetPeriod(puiPeriod) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(*(puiPeriod) = pxTraceTimestamp->period, TRC_SUCCESS)

/**
 * @brief Gets trace timestamp OS tick count.
 * 
 * @param[in] puiOsTickCount 
 * 
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
#define xTraceTimestampGetOsTickCount(puiOsTickCount) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2(*(puiOsTickCount) = pxTraceTimestamp->osTickCount, TRC_SUCCESS)

#endif /* ((TRC_CFG_USE_TRACE_ASSERT) == 1) */

/** @} */

#ifdef __cplusplus
}
#endif

#else

#define xTraceTimestampGet(puiTimestamp) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(puiTimestamp), TRC_SUCCESS)
#define xTraceTimestampGetWraparounds(puiTimerWraparounds) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(puiTimerWraparounds), TRC_SUCCESS)
#define xTraceTimestampSetFrequency(uxFrequency) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(uxFrequency), TRC_SUCCESS)
#define xTraceTimestampSetPeriod(uiPeriod) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(uiPeriod), TRC_SUCCESS)
#define xTraceTimestampSetOsTickCount(uiOsTickCount) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(uiOsTickCount), TRC_SUCCESS)
#define xTraceTimestampGetFrequency(puxFrequency) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(puxFrequency), TRC_SUCCESS)
#define xTraceTimestampGetPeriod(puiPeriod) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(puiPeriod), TRC_SUCCESS)
#define xTraceTimestampGetOsTickCount(puiOsTickCount) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_2((void)(puiOsTickCount), TRC_SUCCESS)

#endif

#endif
