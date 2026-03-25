/*
 * Percepio DFM v2.1.0
 * Copyright 2026 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * DFM utility functions
 */

#include <dfm.h>

#if ((DFM_CFG_ENABLED) >= 1)

#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
#include <trcRecorder.h>
#endif

/* Used for __FILE__ macro to extract the filename from the full path. */
const char * szDfmGetFileNameFromPath(const char *szPath);

uint32_t ulDfmCalculateChecksum(const char *ptr, size_t maxlen);

/* Returns DFM_SUCCESS if both symptoms could be added. */
DfmResult_t xDfmAddFileAndLineSymptoms(DfmAlertHandle_t xAlertHandle, const char *szFileName, int iLineNumber);

#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
/* Acquires the event buffer from the Trace Recorder and adds as a payload. */
DfmResult_t vDfmAddTracePayload(DfmAlertHandle_t xAlertHandle);
#endif

#endif /* DFM_CFG_ENABLED */
