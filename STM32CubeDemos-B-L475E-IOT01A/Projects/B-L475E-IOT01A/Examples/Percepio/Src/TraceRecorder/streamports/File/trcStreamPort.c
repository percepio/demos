/*
 * Trace Recorder for Tracealyzer v989.878.767
 * Copyright 2025 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Supporting functions for trace streaming, used by the "stream ports" 
 * for reading and writing data to the interface.
 * Existing ports can easily be modified to fit another setup, e.g., a 
 * different TCP/IP stack, or to define your own stream port.
 */

#include <trcRecorder.h>
#include <stdio.h>

#if (TRC_USE_TRACEALYZER_RECORDER == 1)

TraceStreamPortFile_t* pxStreamPortFile TRC_CFG_RECORDER_DATA_ATTRIBUTE;

traceResult xTraceStreamPortInitialize(TraceStreamPortBuffer_t* pxBuffer)
{
	TRC_ASSERT_EQUAL_SIZE(TraceStreamPortBuffer_t, TraceStreamPortFile_t);

	TRC_ASSERT(pxBuffer != 0);

	pxStreamPortFile = (TraceStreamPortFile_t*)pxBuffer;
	pxStreamPortFile->pxFile = 0;

#if (TRC_USE_INTERNAL_BUFFER == 1)
	return xTraceInternalEventBufferInitialize(pxStreamPortFile->buffer, sizeof(pxStreamPortFile->buffer));
#else
	return TRC_SUCCESS;
#endif
}

traceResult xTraceStreamPortOnTraceBegin(void)
{
	if (pxStreamPortFile == 0)
	{
		return TRC_FAIL;
	}
	
	if (pxStreamPortFile->pxFile == 0)
	{
#if defined(__STDC_WANT_LIB_EXT1__) && __STDC_WANT_LIB_EXT1__ == 1
		errno_t err = fopen_s(&pxStreamPortFile->pxFile, TRC_CFG_STREAM_PORT_TRACE_FILE, "wb");
		if (err != 0)
		{
			printf("Could not open trace file, error code %d.\n", err);

			return TRC_FAIL;
		}
		else
		{
			printf("Trace file created.\n");
		}
#else
		FILE * file = fopen(TRC_CFG_STREAM_PORT_TRACE_FILE, "wb");
		if (file == NULL)
		{
			printf("Could not open trace file, error code %d.\n", errno);

			return TRC_FAIL;
		}
		else
		{
			pxStreamPortFile->pxFile = file;
			printf("Trace file created.\n");
		}
#endif
	}
	
	return TRC_SUCCESS;
}

traceResult xTraceStreamPortOnTraceEnd(void)
{
	if (pxStreamPortFile == 0)
	{
		return TRC_FAIL;
	}
	
	if (pxStreamPortFile->pxFile != 0)
	{
		fclose(pxStreamPortFile->pxFile);
		pxStreamPortFile->pxFile = 0;
		printf("Trace file closed.\n");
	}
	
	return TRC_SUCCESS;
}

#endif /*(TRC_USE_TRACEALYZER_RECORDER == 1)*/
