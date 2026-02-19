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
 * @brief DFM StopWatch API
 */

#ifndef DFM_STOPWATCH_H_
#define DFM_STOPWATCH_H_

#include <stdint.h>

typedef struct {
	uint32_t start_time;
	uint32_t expected_duration;
	uint32_t high_watermark;
	uint32_t id; /* Starts with 1, 0 is invalid */
	uint32_t times_above;
	const char* name;
} dfmStopwatch_t;


/* PUBLIC API */

dfmStopwatch_t* xDfmStopwatchCreate(const char* name, uint32_t expected_max);

void vDfmStopwatchBegin(dfmStopwatch_t* sw);

void vDfmStopwatchEnd(dfmStopwatch_t* sw);

void vDfmStopwatchClearAll(void);

void vDfmStopwatchPrintAll(void);

uint32_t xDfmStopwatchHighWatermarkGet(uint32_t index);


#endif
