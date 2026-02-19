/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * DFM Crash Catcher integration
 */

#include <string.h>
#include <dfm.h>
#include <dfmKernelPort.h>

static void prvOnTaskAnomaly(TraceTaskMonitorCallbackData_t *pxData);

void xDfmTaskMonitorInit(void)
{
    xDfmTaskMonitorSetCallback(prvOnTaskAnomaly); 
}

static void prvOnTaskAnomaly(TraceTaskMonitorCallbackData_t *pxData)
{ 
    DfmAlertHandle_t xAlertHandle;    

    if (pxData->uxCPULoad > pxData->uxHighLimit)
      snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "Task %s executed more than expected (%u %%).\n", pxData->acName, pxData->uxCPULoad);
    else if (pxData->uxCPULoad < pxData->uxLowLimit)
      snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "Task %s executed less than expected (%u %%).\n", pxData->acName, pxData->uxCPULoad);
    else
      // Not supposed to happen...
      snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "TaskMonitor alert, Task %s, CPU load %u %%, unknown reason.\n", pxData->acName, pxData->uxCPULoad);
        
    if (xDfmAlertBegin(DFM_TYPE_TASKMONITOR_ANOMALY, cDfmPrintBuffer, &xAlertHandle) == DFM_SUCCESS)
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

        #ifdef DFM_SYMPTOM_CURRENT_TASK
        //extern uint32_t prvCalculateChecksum(char *ptr, size_t maxlen);
        xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_CURRENT_TASK, 0 /* prvCalculateChecksum(pxData->acName, 32) */ );
        #endif
        
        if (xDfmAlertEnd(xAlertHandle) != DFM_SUCCESS)
        {
                DFM_CFG_PRINT("DFM: xDfmAlertEnd failed.\n");
        }

        (void)xTraceEnable(TRC_START);
    }    
}
