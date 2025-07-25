/*
* Percepio Trace Recorder for Tracealyzer v989.878.767
* Copyright 2025 Percepio AB
* www.percepio.com
*
* SPDX-License-Identifier: Apache-2.0
*
* The implementation for the static buffer.
*/

#include <trcRecorder.h>

#if (TRC_USE_TRACEALYZER_RECORDER == 1)

TraceStaticBufferTable_t *pxTraceStaticBufferTable TRC_CFG_RECORDER_DATA_ATTRIBUTE;

traceResult xTraceStaticBufferInitialize(TraceStaticBufferTable_t *pxBuffer)
{
	/* This should never fail */
	TRC_ASSERT(pxBuffer != (void*)0);

	pxTraceStaticBufferTable = pxBuffer;

	(void)xTraceSetComponentInitialized(TRC_RECORDER_COMPONENT_STATIC_BUFFER);
	
	return TRC_SUCCESS;
}

#if ((TRC_CFG_USE_TRACE_ASSERT) == 1)

/* Returns a pointer to a maximum sized static buffer */
traceResult xTraceStaticBufferGet(void **ppvBuffer)
{
	int32_t ISR_nesting;

	/* This should never fail */
	TRC_ASSERT(xTraceIsComponentInitialized(TRC_RECORDER_COMPONENT_STATIC_BUFFER));

	TRC_ASSERT(ppvBuffer != (void*)0);
	
	TRC_ASSERT(xTraceISRGetCurrentNesting(&ISR_nesting) ==  TRC_SUCCESS);
	
	/* Task dummy events begin at 0, ISR dummy events begin at index 1 */
	*ppvBuffer = (void*)&pxTraceStaticBufferTable->coreDummyEvents[TRC_CFG_GET_CURRENT_CORE()].dummyEvents[ISR_nesting + 1];

	return TRC_SUCCESS;
}

#endif

#endif
