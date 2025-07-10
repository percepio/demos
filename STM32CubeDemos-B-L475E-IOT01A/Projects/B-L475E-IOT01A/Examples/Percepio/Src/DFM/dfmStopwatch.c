/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * DFM StopWatch
 */

#include <dfm.h>

/* Depends on TraceRecorder for timestamping */
#include <trcRecorder.h>

#if (TRC_HWTC_TYPE != TRC_FREE_RUNNING_32BIT_INCR)
#error Only hardware ports with TRC_HWTC_TYPE == TRC_FREE_RUNNING_32BIT_INCR are supported.
#endif


dfmStopwatch_t stopwatches[DFM_CFG_MAX_STOPWATCHES];
int32_t stopwatch_count = 0;
int32_t stopwatch_enabled = 1; // Monitoring is disabled while saving alerts.

extern char cDfmPrintBuffer[128];

void prvStopwatchPrint(dfmStopwatch_t* sw, char* testresult);
void prvDfmPrintHeader(void);
void prvDfmStopwatchAlert(char* msg, int high_watermark, int stopwatch_index);

uint32_t xDfmStopwatchHighWatermarkGet(uint32_t index)
{
	if (stopwatch_count < DFM_CFG_MAX_STOPWATCHES)
	{
		return stopwatches[index].high_watermark;
	}
	return 0;
}


dfmStopwatch_t* xDfmStopwatchCreate(const char* name, uint32_t expected_max)
{
	TRACE_ALLOC_CRITICAL_SECTION();
	dfmStopwatch_t* sw = NULL;

	TRACE_ENTER_CRITICAL_SECTION();

	if (stopwatch_count < DFM_CFG_MAX_STOPWATCHES)
	{
		sw = &stopwatches[stopwatch_count];

		sw->expected_duration = expected_max;
		sw->name = name;
		sw->high_watermark = 0;
		sw->start_time = 0;
		sw->id = stopwatch_count + 1; /* starts with 1, id 0 denotes invalid/uninitialized. */
		sw->times_above = 0;                
                
		stopwatch_count++;
	}
	TRACE_EXIT_CRITICAL_SECTION();

	return sw;
}

#ifdef INCLUDE_STOPWATCH_UNIT_TEST
static volatile uint32_t hwtc_count_simulated = 0;
#define DFM_CFG_HWTC_COUNT hwtc_count_simulated
#else
#define DFM_CFG_HWTC_COUNT TRC_HWTC_COUNT
#endif


void vDfmStopwatchBegin(dfmStopwatch_t* sw)
{
   if (sw != NULL)
   {
       sw->start_time = DFM_CFG_HWTC_COUNT;
   }
}

extern void prvAddTracePayload(void);

void vDfmStopwatchEnd(dfmStopwatch_t* sw)
{
	uint32_t end_time = DFM_CFG_HWTC_COUNT;

	if (sw != NULL)
	{          
		/* Overflow in HWTC_COUNT is OK. Say that start_time is 0xFFFFFFFF
		 * and end_time is 1, then we get (1 - 0xFFFFFFFF) = 2.
		 * This since 0xFFFFFFFF equals -1 (signed) and 1 - (-1)) = 2 */
		uint32_t duration = end_time - sw->start_time;

		/* Alert if new highest value is found, assuming it is above expected_duration (provides a lower threshold) */
		if (duration > sw->high_watermark)
		{
			sw->high_watermark = duration;

			if (duration > sw->expected_duration)
			{
				sw->times_above++;

				snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "Stopwatch %d reached %u (exp max: %u)\n", sw->id, (unsigned int)sw->high_watermark, (unsigned int)sw->expected_duration);
				DFM_DEBUG_PRINT(cDfmPrintBuffer);

				prvDfmStopwatchAlert(cDfmPrintBuffer, sw->high_watermark, sw->id);
			}
		}
	}
}

void prvStopwatchPrint(dfmStopwatch_t* sw, char* testresult)
{
	if (sw != NULL)
	{
		if (sw->name == NULL)
		{
			sw->name = "NULL";
		}
		printf("%12u, %-14s %9u %9u %9u %s\n", (unsigned int)sw->id, sw->name, (unsigned int)sw->high_watermark, (unsigned int)sw->expected_duration, (unsigned int)sw->start_time, testresult);
	}
	else
	{
		printf("Stopwatch is NULL (ERROR!)\n");
	}
}

void prvDfmPrintHeader(void)
{
    printf("%12s, %-14s %9s %9s %9s\n", "Stopwatch ID", "Name", "High Wm", "Exp Max", "Last Start");
}

void vDfmStopwatchPrintAll(void)
{
	prvDfmPrintHeader();
	for (int i = 0; i < DFM_CFG_MAX_STOPWATCHES; i++)
	{
		if (stopwatches[i].id != 0)
		{
			prvStopwatchPrint(&stopwatches[i], "");
		}
	}
}

void vDfmStopwatchClearAll(void)
{
	for (int i = 0; i < DFM_CFG_MAX_STOPWATCHES; i++)
	{
		stopwatches[i].expected_duration = 0;
		stopwatches[i].name = NULL;
		stopwatches[i].high_watermark = 0;
		stopwatches[i].start_time = 0;
		stopwatches[i].id = 0;
	}
	stopwatch_count = 0;
}

void prvDfmStopwatchAlert(char* msg, int high_watermark, int stopwatch_index)
{
	static DfmAlertHandle_t xAlertHandle;
	if (xDfmAlertBegin(DFM_TYPE_STOPWATCH, msg, &xAlertHandle) == DFM_SUCCESS)
	{
		void* pvBuffer = (void*)0;
		uint32_t ulBufferSize = 0;
		static TraceStringHandle_t TzUserEventChannel = NULL;

		if (TzUserEventChannel == 0)
		{
			(void)xTraceStringRegister("ALERT", &TzUserEventChannel);
		}

		(void)xTracePrint(TzUserEventChannel, cDfmPrintBuffer);

		/* Stopping the tracing while sending the trace data. */
		(void)xTraceDisable();

		(void)xTraceGetEventBuffer(&pvBuffer, &ulBufferSize);
		(void)xDfmAlertAddPayload(xAlertHandle, pvBuffer, ulBufferSize, "dfm_trace.psfs");

		#ifdef DFM_SYMPTOM_HIGH_WATERMARK
		(void)xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_HIGH_WATERMARK, high_watermark);
		#endif

		#ifdef DFM_SYMPTOM_STOPWATCH_ID
		(void)xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_STOPWATCH_ID, stopwatch_index);
		#endif

		/* Assumes "cloud port" is a UART or similar, that is always available. */
		if (xDfmAlertEnd(xAlertHandle) != DFM_SUCCESS)
		{
			DFM_DEBUG_PRINT("DFM: xDfmAlertEnd failed.\n");
		}

                (void)xTraceEnable(TRC_START);

	}
}


#if (INCLUDE_STOPWATCH_TESTS == 1)

void prvStopwatchSetSimulatedTime(uint32_t time);
void prvStopwatchClear(dfmStopwatch_t* sw);


DfmResult_t prvPrintAndCheckStopwatch(dfmStopwatch_t* sw, uint32_t expected_hwm, uint32_t expected_st, uint32_t expected_exp_dur, const char* expected_name, uint32_t expected_id)
{
	DfmResult_t result = DFM_SUCCESS;
	char* status = "(OK)";

	if (sw->start_time != expected_st)
	{
		status = "ERROR (start_time)";
		result = DFM_FAIL;
	}

	if (sw->expected_duration != expected_exp_dur)
	{
		status = "ERROR (expected_duration)";
		result = DFM_FAIL;
	}

	if (sw->high_watermark != expected_hwm)
	{
		status = "ERROR (high_watermark)";
		result = DFM_FAIL;
	}

	if (sw->name != expected_name)
	{
		status = "ERROR (name)";
		result = DFM_FAIL;
	}

	if (sw->id != expected_id)
	{
		status = "ERROR (id)";
		result = DFM_FAIL;
	}

	prvStopwatchPrint(sw, status);

	return result;
}

void prvRunTests(void)
{
	int err = 0;

	char swnames[DFM_CFG_MAX_STOPWATCHES][10] = {"SW1", "SW2", "SW2", "SW4"} ;

	printf("\nTest 1: xDfmStopwatchCreate().\n");
    for (int i = 0; i < DFM_CFG_MAX_STOPWATCHES + 1; i++) // Tries creating one too many stopwatches.
    {
    	dfmStopwatch_t* sw = NULL;

    	sw = xDfmStopwatchCreate( swnames[i], 1000 + (i * 100));

    	printf(" Call %d: ", i);

    	if (sw == NULL)
    	{
    		printf("NULL ");
    		if (i >= DFM_CFG_MAX_STOPWATCHES)
    		{
    			printf("(OK)\n");
    		}
    		else
    		{
    			printf("ERROR!\n");
    			err = 1;
    		}
    	}
    	else
    	{
    		printf("Not NULL (OK)\n");
    	}
    }

    prvDfmPrintHeader();
    for (int i = 0; i < DFM_CFG_MAX_STOPWATCHES; i++) // List and verify all stopwatches
    {
    	if (prvPrintAndCheckStopwatch(&stopwatches[i], 0, 0, 1000 + (100*i), swnames[i], i+1) == DFM_FAIL)
    	{
    		err = 1;
    	}
    }

    if (err == 0)
    {
    	dfmStopwatch_t* sw;
    	vDfmStopwatchClearAll();

    	// Test: Zero time elapsed
    	printf("\nTest 2: vDfmStopwatchBegin/End - Zero time elapsed.\n");
    	prvDfmPrintHeader();
    	sw = xDfmStopwatchCreate(swnames[0], 1000);
    	prvStopwatchSetSimulatedTime(0);
    	vDfmStopwatchBegin(sw);
    	vDfmStopwatchEnd(sw);
    	prvPrintAndCheckStopwatch(sw, 0, 0, 1000, swnames[0], 1);

    	printf("\nTest 3: vDfmStopwatchClearAll();\n");
    	vDfmStopwatchClearAll();
    	prvDfmPrintHeader();
    	for (int i = 0; i < DFM_CFG_MAX_STOPWATCHES; i++)
    	{
    		prvPrintAndCheckStopwatch(&stopwatches[i], 0, 0, 0, NULL, 0);
    	}

    	printf("\nTest 4: Begin/End - Overflow at t=0xFFFFFFFF.\n");
    	prvDfmPrintHeader();
    	sw = xDfmStopwatchCreate(swnames[0], 2);
    	prvStopwatchSetSimulatedTime(0xFFFFFFFF);
		vDfmStopwatchBegin(sw);
		prvStopwatchSetSimulatedTime(1);
		vDfmStopwatchEnd(sw);
		prvPrintAndCheckStopwatch(sw, 2, 0xFFFFFFFF, 2, swnames[0], 1);
		vDfmStopwatchClearAll();

    	printf("\nTest 5: Begin/End from 200 to 300.\n");
    	prvDfmPrintHeader();
    	sw = xDfmStopwatchCreate(swnames[0], 1000);
    	prvStopwatchSetSimulatedTime(200);
    	vDfmStopwatchBegin(sw);
    	prvStopwatchSetSimulatedTime(300);
    	vDfmStopwatchEnd(sw);
    	prvPrintAndCheckStopwatch(sw, 100, 200, 1000, swnames[0], 1);
    	vDfmStopwatchClearAll();

		printf("\nTest 6: Begin/End with 0xFFFFFFFF duration\n");
		prvDfmPrintHeader();
		sw = xDfmStopwatchCreate(swnames[0], 0xFFFFFFFF);
		prvStopwatchSetSimulatedTime(0);
		vDfmStopwatchBegin(sw);
		prvStopwatchSetSimulatedTime(0xFFFFFFFF);
		vDfmStopwatchEnd(sw);
		prvPrintAndCheckStopwatch(sw, 0xFFFFFFFF, 0, 0xFFFFFFFF, swnames[0], 1);
		vDfmStopwatchClearAll();

		printf("\nTest 7: Using all stopwatches at the same time.\n");

		{
			dfmStopwatch_t* sw0;
			dfmStopwatch_t* sw1;
			dfmStopwatch_t* sw2;
			dfmStopwatch_t* sw3;

			sw0 = xDfmStopwatchCreate(swnames[0], 100);
			sw1 = xDfmStopwatchCreate(swnames[1], 200);
			sw2 = xDfmStopwatchCreate(swnames[2], 300);
			sw3 = xDfmStopwatchCreate(swnames[3], 400);

			prvStopwatchSetSimulatedTime(10);

			vDfmStopwatchBegin(sw0);
			vDfmStopwatchBegin(sw1);
			vDfmStopwatchBegin(sw2);
			vDfmStopwatchBegin(sw3);

			prvStopwatchSetSimulatedTime(110);
			vDfmStopwatchEnd(sw0);

			prvStopwatchSetSimulatedTime(210);
			vDfmStopwatchEnd(sw1);

			prvStopwatchSetSimulatedTime(310);
			vDfmStopwatchEnd(sw2);

			prvStopwatchSetSimulatedTime(410);
			vDfmStopwatchEnd(sw3);

			prvDfmPrintHeader();
			prvPrintAndCheckStopwatch(sw0, 100, 10, 100, swnames[0], 1);
			prvPrintAndCheckStopwatch(sw1, 200, 10, 200, swnames[1], 2);
			prvPrintAndCheckStopwatch(sw2, 300, 10, 300, swnames[2], 3);
			prvPrintAndCheckStopwatch(sw3, 400, 10, 400, swnames[3], 4);

			vDfmStopwatchClearAll();
		}
    }

    for (;;);
}

// Only intended for unit testing
void prvStopwatchSetSimulatedTime(uint32_t time)
{
	hwtc_count_simulated = time;
}


/******************************************************************************
 * Profiling results on 80 MHz Arm Cortex-M4 (STM32L475)
 *
 * Clock cycles needed for one measurement (xDfmStopwatchBegin() +
 * xDfmStopwatchEnd()) in the normal case (no alert or new high watermark).
 * - No Optimizations (-O0): 108 cycles
 * - Basic Optimizations (-O1): 65 cycles
 * - Full Optimizations (-O3): 31 cycles
 *
 * This means, with 1000 measurements per second on this 80 MHz device, the
 * execution time overhead would be 0,04%-0.14%.
 *****************************************************************************/

void prvTestOverhead(void)
{
    int counter = 0;
    dfmStopwatch_t* my_stopwatch;

    uint32_t starttime1;
    uint32_t endtime1;
    uint32_t max1 = 0;
    uint32_t starttime2;
    uint32_t endtime2;
    uint32_t max2 = 0;
    uint32_t dur;

    my_stopwatch = xDfmStopwatchCreate("MyStopwatch1", 10);
    if (my_stopwatch == NULL)
    {
    	printf("ERROR, my_stopwatch == NULL\n");
    	return;
    }

	starttime1 = TRC_HWTC_COUNT;
	vDfmStopwatchBegin(my_stopwatch);
	endtime1 = TRC_HWTC_COUNT;

	starttime2 = TRC_HWTC_COUNT;
	vDfmStopwatchEnd(my_stopwatch);
	endtime2 = TRC_HWTC_COUNT;

	dur = endtime1 - starttime1;
	printf("Begin: %u", (unsigned int)dur);

	if (dur > max1)
	{
		printf(" - new high watermark.\n");
		max1 = dur;
	}
	else
	{
		printf("\n");
	}

	dur = endtime2 - starttime2;
	printf("End: %u", (unsigned int)dur);
	if (dur > max2)
	{
		printf(" - new high watermark.\n");
		max2 = dur;
	}
	else
	{
		printf("\n");
	}
}

#endif

