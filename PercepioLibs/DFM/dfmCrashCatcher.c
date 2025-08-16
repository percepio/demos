/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * DFM Crash Catcher integration
 */

#include <stdint.h>
#include <string.h>
#include <CrashCatcher.h>
#include <dfm.h>
#include <dfmCrashCatcher.h>
#include <CrashCatcherPriv.h>
#include <dfmKernelPort.h>

#if ((DFM_CFG_ENABLED) >= 1)

#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
#include <trcRecorder.h>
static void prvAddTracePayload(void);
#endif

/* See https://developer.arm.com/documentation/dui0552/a/cortex-m3-peripherals/system-control-block/configurable-fault-status-register*/
#define ARM_CORTEX_M_CFSR_REGISTER *(uint32_t*)0xE000ED28

static DfmAlertHandle_t xAlertHandle = 0;

// CrashCatcher changes stack, so we need to restore sp to allow returning from CrashCatcher.
volatile uint32_t g_saved_sp = 0; 

dfmTrapInfo_t dfmTrapInfo = {-1, NULL, NULL, -1, 0};

#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
static TraceStringHandle_t TzUserEventChannel = NULL;
#endif

uintptr_t __stack_chk_guard = 0xDEADBEEF;

static uint8_t* ucBufferPos;
static uint8_t ucDataBuffer[CRASH_DUMP_BUFFER_SIZE] __attribute__ ((aligned (8)));

static void dumpHalfWords(const uint16_t* pMemory, size_t elementCount);
static void dumpWords(const uint32_t* pMemory, size_t elementCount);

uint32_t stackPointer = 0;

/* Used for snprintf calls */
char cDfmPrintBuffer[128];

/* Used for __FILE__ macro to extract the filename from the full path. */
static char* prvGetFileNameFromPath(char* szPath)
{
        char* pos = strrchr(szPath, '/');
        if (pos != NULL) return pos+1;
  
        // No forward slash, look for windows backslash char.
        pos = strrchr(szPath, '\\');
        if (pos != NULL) return pos+1;
          
	return 0; /* No slash found */
}

uint32_t prvCalculateChecksum(char *ptr, size_t maxlen)
{
	uint32_t chksum = 0;
	size_t i = 0;

	if (ptr == NULL)
	{
		return 0;
	}

	while ((ptr[i] != (char)0) && (i < maxlen))
	{
		chksum += (uint32_t)ptr[i];
		i++;
	}

	return chksum;
}

extern uint8_t ucHeap[ configTOTAL_HEAP_SIZE ];

const CrashCatcherMemoryRegion* CrashCatcher_GetMemoryRegions(void)
{
	static CrashCatcherMemoryRegion regions[] = {
		{0xFFFFFFFF, 0xFFFFFFFF, CRASH_CATCHER_BYTE},
		{CRASH_MEM_REGION1_START, CRASH_MEM_REGION1_START + CRASH_MEM_REGION1_SIZE, CRASH_CATCHER_BYTE},
		{CRASH_MEM_REGION2_START, CRASH_MEM_REGION2_START + CRASH_MEM_REGION2_SIZE, CRASH_CATCHER_BYTE},
		{CRASH_MEM_REGION3_START, CRASH_MEM_REGION3_START + CRASH_MEM_REGION3_SIZE, CRASH_CATCHER_BYTE}
	};

	/* Region 0 is reserved, always relative to the current stack pointer */
	
    
    regions[0].startAddress = (uint32_t)stackPointer;
	regions[0].endAddress = (uint32_t)stackPointer + CRASH_STACK_CAPTURE_SIZE;

	// If inside the stack memory area, we verify that we don't overrun the endAddress...
	if ( (regions[0].startAddress >= DFM_CFG_ADDR_CHECK_BEGIN) && (regions[0].startAddress < DFM_CFG_ADDR_CHECK_NEXT))
	{
		// Check that not reading outside the valid memory range.
		if ( regions[0].endAddress >= DFM_CFG_ADDR_CHECK_NEXT)
		{
			regions[0].endAddress = DFM_CFG_ADDR_CHECK_NEXT - 4;
		}
	}

	return regions;
}

void CrashCatcher_DumpStart(const CrashCatcherInfo* pInfo)
{
	int alerttype;
	char* szFileName = (void*)0;
	char* szCurrentTaskName = (void*)0;

	stackPointer = pInfo->sp;

	ucBufferPos = &ucDataBuffer[0];

    CC_DBG_LOG("CrashCatcher_DumpStart" LNBR);
    
	if (dfmTrapInfo.alertType >= 0)
	{
		/* Called on DFM_TRAP calls.
		 * The dfmCoreDump function copies the args to dfmTrapInfo:
		 * dfmTrapInfo.message = "Assert failed" or similar.
		 * dfmTrapInfo.file = __FILE__ (full path, extract the filename from this!)
		 * dfmTrapInfo.line = __LINE__ (integer)
		 * */
		szFileName = prvGetFileNameFromPath(dfmTrapInfo.file);
		snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "%s at %s:%u", dfmTrapInfo.message, szFileName, dfmTrapInfo.line);

		alerttype = dfmTrapInfo.alertType;
	}
	else
	{
		/* On processor fault handlers (not DFM_TRAP) */
		snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "Fault exception, CFSR: 0x%08X", (unsigned int)ARM_CORTEX_M_CFSR_REGISTER);

		alerttype = DFM_TYPE_HARDFAULT;
	}

	#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
	if (TzUserEventChannel == 0)
	{
		xTraceStringRegister("ALERT", &TzUserEventChannel);
	}
	xTracePrint(TzUserEventChannel, cDfmPrintBuffer);
     xTraceDisable();
	#endif

	DFM_DEBUG_PRINT(LNBR "DFM Alert: ");
	DFM_DEBUG_PRINT(cDfmPrintBuffer);
	DFM_DEBUG_PRINT(LNBR);

	if (xDfmAlertBegin(alerttype, cDfmPrintBuffer, &xAlertHandle) == DFM_SUCCESS)
	{
		(void)xDfmKernelPortGetCurrentTaskName(&szCurrentTaskName);

		#ifdef DFM_SYMPTOM_CURRENT_TASK
		xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_CURRENT_TASK, prvCalculateChecksum(szCurrentTaskName, 32));
		#endif

		#ifdef DFM_SYMPTOM_STACKPTR
		xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_STACKPTR, pInfo->sp);
		#endif

		if (dfmTrapInfo.alertType >= 0)
		{
			/* On DFM_TRAP */
			#ifdef DFM_SYMPTOM_FILE
			xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_FILE, prvCalculateChecksum(szFileName, 32));
			#endif

			#ifdef DFM_SYMPTOM_LINE
			xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_LINE, dfmTrapInfo.line);
			#endif
		}
		else
		{
			/* On hard faults */
			#ifdef DFM_SYMPTOM_CFSR
			xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_CFSR, ARM_CORTEX_M_CFSR_REGISTER);
			#endif
		}

		#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
		prvAddTracePayload();
		#endif

		DFM_DEBUG_PRINT("  DFM: Storing the alert." LNBR);
	}
	else
	{
		DFM_DEBUG_PRINT("  DFM: Not yet initialized. Alert ignored." LNBR); // Always log this!
	}
	DFM_DEBUG_PRINT(LNBR);

}

#if ((DFM_CFG_CRASH_ADD_TRACE) >= 1)
static void prvAddTracePayload(void)
{
	void* pvBuffer = (void*)0;
	uint32_t ulBufferSize = 0;	
    
    // Note that tracing is already disabled at this point.
	xTraceGetEventBuffer(&pvBuffer, &ulBufferSize);
	xDfmAlertAddPayload(xAlertHandle, pvBuffer, ulBufferSize, "dfm_trace.psfs");
}
#endif

void CrashCatcher_DumpMemory(const void* pvMemory, CrashCatcherElementSizes elementSize, size_t elementCount)
{
	int32_t current_usage = (uint32_t)ucBufferPos - (uint32_t)ucDataBuffer;
    
	if ( current_usage + (elementSize*elementCount) >= CRASH_DUMP_BUFFER_SIZE)
	{
		DFM_ERROR_PRINT(LNBR "DFM: Error, ucDataBuffer not large enough!" LNBR LNBR);
		return;
	}

	/* This function is called when CrashCatcher detects an internal stack overflow (it has a separate stack) */
	if (g_crashCatcherStack[0] != CRASH_CATCHER_STACK_SENTINEL)
	{
		/* Always try to print this error. But it might actually not print since the memory has been corrupted. */
		DFM_ERROR_PRINT("DFM: ERROR, stack overflow in CrashCatcher, see comment in dfmCrashCatcher.c" LNBR LNBR);

		/**********************************************************************************************************

		If you get here, there has been a stack overflow on the CrashCatcher stack.
		This is separate from the main stack and defined in CrashCatcher.c (g_crashCatcherStack).

		This error might happen because of diagnostic prints and other function calls while saving the alert.
		You may increase the stack size in CrashCatcherPriv.h or turn off the logging (DFM_CFG_USE_DEBUG_LOGGING).

		***********************************************************************************************************/

		// vDfmDisableInterrupts();
		for (;;); // Stop here...
	}

	if (elementCount == 0)
	{
		/* May happen if CRASH_MEM_REGION<X>_SIZE is set to 0 by mistake (e.g. if using 0 instead of 0xFFFFFFFF for CRASH_MEM_REGION<X>_START on unused slots. */
		DFM_ERROR_PRINT("DFM: Warning, memory region size is zero!" LNBR LNBR);
		return;
	}

	switch (elementSize)
	{

		case CRASH_CATCHER_BYTE: 
            memcpy((void*)ucBufferPos, pvMemory, elementCount);
            ucBufferPos += elementCount;
			break;

		case CRASH_CATCHER_HALFWORD:
			dumpHalfWords(pvMemory, elementCount);
			break;

		case CRASH_CATCHER_WORD:
			dumpWords(pvMemory, elementCount);

			break;

		default:
			DFM_ERROR_PRINT(LNBR "DFM: Error, unhandled case!" LNBR LNBR);
			break;
	}
}

static void dumpHalfWords(const uint16_t* pMemory, size_t elementCount)
{
	size_t i;
    
	for (i = 0 ; i < elementCount ; i++)
	{
		uint16_t val = *pMemory++;
		memcpy((void*)ucBufferPos, &val, sizeof(val));
        
		ucBufferPos += sizeof(val);
	}
}

static void dumpWords(const uint32_t* pMemory, size_t elementCount)
{
	size_t i;
	for (i = 0 ; i < elementCount ; i++)
	{
		uint32_t val = *pMemory++;
		memcpy((void*)ucBufferPos, &val, sizeof(val));
        
        CC_DBG_LOG("%02d: %08X" LNBR, i, val);
        
		ucBufferPos += sizeof(val);
	}
}

CrashCatcherReturnCodes CrashCatcher_DumpEnd(void)
{
    CC_DBG_LOG("CrashCatcher_DumpEnd (DFM output begins)" LNBR);
    
	if (xAlertHandle != 0)
	{
		uint32_t size = (uint32_t)ucBufferPos - (uint32_t)ucDataBuffer;
		if (xDfmAlertAddPayload(xAlertHandle, ucDataBuffer, size, CRASH_DUMP_NAME) != DFM_SUCCESS)
		{
			DFM_ERROR_PRINT("DFM: Error, xDfmAlertAddPayload failed." LNBR);
		}

#ifdef DFM_CLOUD_PORT_ALWAYS_ATTEMPT_TRANSFER
		/* The cloud port has indicated it is always OK to attempt to transfer */
		if (xDfmAlertEnd(xAlertHandle) != DFM_SUCCESS)
		{
			DFM_DEBUG_PRINT("DFM: xDfmAlertEnd failed." LNBR);
		}

#else
		/* Cloud port transfer cannot be trusted, so we only attempt to store it */
		if (xDfmAlertEndOffline(xAlertHandle) != DFM_SUCCESS)
		{
			DFM_DEBUG_PRINT("DFM: xDfmAlertEndOffline failed." LNBR);
		}
#endif

	}

    
     CC_DBG_LOG("dfmTrapInfo.alertType: %d" LNBR, dfmTrapInfo.alertType);
	// If triggered by DFM_TRAP
	if (dfmTrapInfo.alertType != -1)
	{
        if (dfmTrapInfo.restart == 1)
		{
            CC_DBG_LOG("Type: DFM_TRAP with restart." LNBR);
			CRASH_FINALIZE();
		}
		else
		{
            CC_DBG_LOG("Type: DFM_TRAP, no restart." LNBR);
			// Not restarting, so start tracing again.
			xTraceEnable(TRC_START);
		}
                
		dfmTrapInfo.alertType = -1;
		dfmTrapInfo.message = NULL;
		dfmTrapInfo.restart = 0;
		dfmTrapInfo.file = NULL;
		dfmTrapInfo.line = 0;
	}
	else
	{
        CC_DBG_LOG("Type: Fault Exception." LNBR);
		// if triggered by hard fault or similar
		CRASH_FINALIZE();
	}

	return CRASH_CATCHER_EXIT;
}

/* Called by gcc stack-checking code when using the gcc option -fstack-protector-strong */
void __stack_chk_fail(void)
{
	#ifdef DFM_TYPE_STACK_CHK_FAILED
	// The stack has been corrupted by the previous function in the call stack (before __stack_chk_fail)
	DFM_TRAP(DFM_TYPE_STACK_CHK_FAILED, "Stack corruption detected", 1);
	#endif
        
        while(1); // Avoids warnings in IAR (declared "noreturn").

}

#if (0)
void test_dfmCoreDump_with_known_regs()
{
    // Sets core regs to known values.
    __asm volatile (
        "ldr r0,  =0x0000A0A0 \n"
        "ldr r1,  =0x1111B1B1 \n"
        "ldr r2,  =0x2222C2C2 \n"
        "ldr r3,  =0x3333D3D3 \n"
        "ldr r4,  =0x4444E4E4 \n"
        "ldr r5,  =0x5555F5F5 \n"
        "ldr r6,  =0x6666A6A6 \n"
        "ldr r7,  =0x7777B7B7 \n"
        "ldr r8,  =0x8888C8C8 \n"
        "ldr r9,  =0x9999D9D9 \n"
        "ldr r10, =0xAAAAEAEA \n"
        "ldr r11, =0xBBBBFBFB \n"
        "ldr r12, =0xCCCCACAC \n"
        ::: "r0","r1","r2","r3","r4","r5","r6","r7","r8","r9","r10","r11","r12",
          "cc","memory"
    );
    
    __asm volatile ("nop");
    DFM_TRAP(DFM_TYPE_STACK_CHK_FAILED, "TEST ALERT", 0);
    __asm volatile ("nop");

}
#endif  


#endif
