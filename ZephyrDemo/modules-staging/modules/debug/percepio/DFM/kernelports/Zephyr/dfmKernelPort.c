/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Zephyr Kernel port
 */

#include <zephyr/init.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/reboot.h>
#include <zephyr/arch/exception.h>
#include <kernel_arch_data.h>

#include <dfm.h>
 
#if defined(CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS)
#include <zephyr/debug/coredump.h>
#endif

/* Scratch related includes */
#include <zephyr/storage/flash_map.h>
#include <dfmConfig.h>
#include <dfmUtility.h>

#if ((DFM_CFG_ENABLED) == 1)

#if (CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE >= 1)
static TraceStringHandle_t TzUserEventChannel = 0;
#endif

#if defined(CONFIG_PERCEPIO_DFM_CFG_COREDUMP_RETAIN) && !defined(CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY)
#error "DFM is configured to store Core Dumps in Retained Memory but that isn't enabled in DFM."
#endif

#define MAX_COREDUMP_PARTS 8

dfmTrapInfo_t dfmTrapInfo = {0};

DfmKernelPortData_t* pxKernelPortData;

uint32_t exc_return = 0;

#if defined(PERCEPIO_DFM_CFG_INITIALIZE_FOR_LOCAL_USE)
static int dfm_application_init(void)
{
	xDfmInitializeForLocalUse();

	return 0;
}

/* Specify DFM module initialization stages */
SYS_INIT(dfm_application_init, APPLICATION, 0);
#endif /* PERCEPIO_DFM_CFG_INITIALIZE_FOR_LOCAL_USE */

DfmResult_t xDfmKernelPortInitialize(DfmKernelPortData_t *pxBuffer)
{
	if (pxBuffer == (void*)0)
	{
		return DFM_FAIL;
	}

	pxKernelPortData = pxBuffer;

	return DFM_SUCCESS;
}

DfmResult_t xDfmKernelPortGetCurrentTaskName(const char** pszTaskName)
{
#ifdef CONFIG_THREAD_NAME
	k_tid_t current_thread = k_current_get();
	DfmResult_t ret;
	if (current_thread == (void*)0) {
		current_thread = k_sched_current_thread_query();
	}
	if (current_thread == (void*)0) {
		ret = DFM_FAIL;
	} else {
		*pszTaskName = k_thread_name_get(current_thread);
		ret = DFM_SUCCESS;
	}
	return ret;
#else
	return DFM_FAIL;
#endif
}

/*
 * Functions for the coredump backend api, which in turn will use the dfmBackend for storing data
 * TODO: We probably don't want this in the kernel port but rather in its own file, like with crashcatcher.
 */

enum eDfmCoredumpState {
	DFM_COREDUMP_STATE_STARTED,
	DFM_COREDUMP_STATE_HEADER,
	DFM_COREDUMP_STATE_DATA
};

#if defined(CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS)

typedef struct DfmCoredumpPayload {
	union {
		char id;
		struct coredump_hdr_t hdr;
		struct coredump_arch_hdr_t arch_hdr;
		struct coredump_threads_meta_hdr_t threads_meta_hdr;
		struct coredump_mem_hdr_t mem_hdr;
	} pubHeaderBuffer;
	size_t ulHeaderSize;
	void* pxContent;
	size_t ulContentSize;
} DfmCoredumpPayload_t;

static enum eDfmCoredumpState eCoreDumpState = DFM_COREDUMP_STATE_STARTED;
static DfmCoredumpPayload_t pxDfmCoredumpParts[MAX_COREDUMP_PARTS]; // The zephyr coredump process won't add more than 3 headers
static uint8_t ubDfmCoreDumpHeaderCounter = 0;
static uint8_t ubDfmPayloadBuffer[CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE];
static uint32_t ulDfmPayloadBufferBytesUsed = 0;
static int iDfmError;

DfmResult_t xDfmAlertAddCoredump(DfmAlertHandle_t xAlertHandle)
{
	if (ubDfmCoreDumpHeaderCounter < 1)
		return DFM_FAIL;

	ulDfmPayloadBufferBytesUsed = 0;
	memset(ubDfmPayloadBuffer, 0, sizeof(ubDfmPayloadBuffer));
	uint8_t* pubDfmPayloadBufferPosition = ubDfmPayloadBuffer;

	for (int i = 0; i < ubDfmCoreDumpHeaderCounter; i++)
	{
		DfmCoredumpPayload_t* pxCurrentPayload = &pxDfmCoredumpParts[i];

		size_t ulContentSize = pxCurrentPayload->ulContentSize;		

		/* Initial size check to avoid overflowing the buffer, i.e. does this part of the chunk fit within the chunk */
		if (ulDfmPayloadBufferBytesUsed + pxCurrentPayload->ulHeaderSize + ulContentSize > CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE)
			return DFM_FAIL;

		/* Copy the header */
		memcpy(pubDfmPayloadBufferPosition, &pxCurrentPayload->pubHeaderBuffer, pxCurrentPayload->ulHeaderSize);
		pubDfmPayloadBufferPosition += pxCurrentPayload->ulHeaderSize;
		ulDfmPayloadBufferBytesUsed += pxCurrentPayload->ulHeaderSize;

		if (pxCurrentPayload->pxContent != (void*)0)
		{
			/* Copy the content */
			memcpy(pubDfmPayloadBufferPosition, pxCurrentPayload->pxContent, ulContentSize);
			pubDfmPayloadBufferPosition += ulContentSize;
			ulDfmPayloadBufferBytesUsed += ulContentSize;
		}
	}

	DfmResult_t xResult;
	xResult = xDfmAlertAddPayload(
		xAlertHandle,
		ubDfmPayloadBuffer,
		ulDfmPayloadBufferBytesUsed,
		"coredump.zpr"
	);

	return xResult;
}

/**
 * Start a new coredump, will wipe the memory area and reset the internal counters used by this kernel port when a coredump
 * is saved.
 * This function is called from the Zephyr kernel.
 */
static void xDfmCoredumpBackendStart(void)
{
	eCoreDumpState = DFM_COREDUMP_STATE_STARTED;
	ubDfmCoreDumpHeaderCounter = 0;
	memset(pxDfmCoredumpParts, 0, sizeof(pxDfmCoredumpParts));
	iDfmError = 0;
}

/**
 * Internally store a part of a coredump within the internal array of DfmCoreDumpPayloads.
 * This function is called from the Zephyr kernel.
 * @param pxBuffer
 * @param ulBufferLength
 */
static void xDfmCoredumpBackendBufferOutput(uint8_t* pxBuffer, size_t ulBufferLength)
{
	/*
	 * To avoid nasty buffer overflows, stop dumping any more data in case the maximum
	 * amount of payloads has been reached. Since the signature of the function expected by Zephyr
	 * for outputting backend data is a void, error handling can unfortunately not be implemented here.
	 */
	if (ubDfmCoreDumpHeaderCounter >= MAX_COREDUMP_PARTS)
		return;

	DfmCoredumpPayload_t* pxCurrentPayload = &pxDfmCoredumpParts[ubDfmCoreDumpHeaderCounter];

	switch (eCoreDumpState)
	{

		case DFM_COREDUMP_STATE_STARTED:
		{
			pxCurrentPayload->ulHeaderSize = ulBufferLength;
			memcpy(&pxCurrentPayload->pubHeaderBuffer, pxBuffer, ulBufferLength);
			ubDfmCoreDumpHeaderCounter++;
			eCoreDumpState = DFM_COREDUMP_STATE_HEADER;
			break;
		}

		case DFM_COREDUMP_STATE_HEADER:
		{
			pxCurrentPayload->ulHeaderSize = ulBufferLength;
			memcpy(&pxCurrentPayload->pubHeaderBuffer, pxBuffer, ulBufferLength);
			eCoreDumpState = DFM_COREDUMP_STATE_DATA;
			break;
		}

		case DFM_COREDUMP_STATE_DATA: {
			pxCurrentPayload->ulContentSize = ulBufferLength;
			pxCurrentPayload->pxContent = pxBuffer;
			ubDfmCoreDumpHeaderCounter++;
			eCoreDumpState = DFM_COREDUMP_STATE_HEADER;
			break;
		}

	}

}


#include <zephyr/fatal_types.h>

const char *zephyr_reason_to_str(unsigned int reason)
{
    switch (reason) {
    case K_ERR_CPU_EXCEPTION:   return "Fatal error: CPU exception";
    case K_ERR_KERNEL_OOPS:     return "Fatal error: Kernel oops";
    case K_ERR_KERNEL_PANIC:    return "Fatal error: Kernel panic";
    case K_ERR_STACK_CHK_FAIL:  return "Fatal error: Stack check fail";
    case K_ERR_SPURIOUS_IRQ:    return "Fatal error: Spurious IRQ";    
    default:      
		snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "Fatal error: Other (reason code: %u)", reason);
		return cDfmPrintBuffer;
    }
}


/* Used for __FILE__ macro to extract the filename from the full path. */
static char* prvGetFileNameFromPath(char* szPath)
{
    char* pos = strrchr(szPath, '/');

	if (pos != (void*)0)
		return pos + 1;
  
    // No forward slash, look for windows backslash char.
    pos = strrchr(szPath, '\\');
	if (pos != (void*)0)
		return pos + 1;

	return 0; /* No slash found */
}

/**
 * This function is called from the the Zephyr kernel.
 */
static void xDfmCoredumpBackendEnd(void)
{
	DfmAlertHandle_t xAlertHandle;

	/* Examine the header to see whether this was a coredump created by the user or triggered from Zephyr */
	struct coredump_hdr_t* pxCoredumpHeader = &pxDfmCoredumpParts[0].pubHeaderBuffer.hdr;

	int alertType = dfmTrapInfo.alertType;
	const char *message;
	if (alertType == 0)
	{
		alertType = DFM_TYPE_ZEPHYR_FATAL_ERROR;
		message = zephyr_reason_to_str(pxCoredumpHeader->reason);
	}
	else
	{	
		char* szFileName = prvGetFileNameFromPath((char*)dfmTrapInfo.file);
		snprintf(cDfmPrintBuffer, sizeof(cDfmPrintBuffer), "%s at %s:%u", dfmTrapInfo.message, szFileName, dfmTrapInfo.line);
		message = cDfmPrintBuffer;
	}

	if (xDfmAlertBegin(alertType, message, &xAlertHandle) == DFM_SUCCESS)
	{
		/* TODO: Look into how to add various symptoms caught by the coredump here */
		xDfmAlertAddCoredump(xAlertHandle);

		/* Add the reason code as a symptom */
		if (alertType == DFM_TYPE_ZEPHYR_FATAL_ERROR)
		{
			xDfmAlertAddSymptom(xAlertHandle, DFM_SYMPTOM_ZEPHYR_FATAL_ERROR_REASON, pxCoredumpHeader->reason);
		}

#if defined(CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE)
		if (TzUserEventChannel == 0)
		{
			xTraceStringRegister("ALERT", &TzUserEventChannel);
		}
		xTracePrint(TzUserEventChannel, message);

		xDfmAlertAddTrace(xAlertHandle);
#endif

#if defined(CONFIG_PERCEPIO_DFM_CFG_COREDUMP_RETAIN)
	xDfmAlertEndCustom(xAlertHandle, DFM_ALERT_END_TYPE_RETAIN);
#elif defined(CONFIG_PERCEPIO_DFM_CFG_COREDUMP_STORE)
	xDfmAlertEndCustom(xAlertHandle, DFM_ALERT_END_TYPE_STORE);
#elif defined(CONFIG_PERCEPIO_DFM_CFG_COREDUMP_SEND)
	xDfmAlertEndCustom(xAlertHandle, DFM_ALERT_END_TYPE_SEND);
#else
		xDfmAlertEnd();
#endif
	}

}

static int xDfmCoredumpBackendCmd(enum coredump_cmd_id eCmdId, void *arg)
{
	int ret;

	switch (eCmdId) {
	case COREDUMP_CMD_CLEAR_ERROR:
		ret = 0;
		iDfmError = 0;
		break;
	default:
		ret = -ENOTSUP;
		break;
	}

	return ret;
}

static int xDfmCoredumpBackendQuery(enum coredump_query_id eQueryId, void *arg)
{
	int ret;

	switch (eQueryId) {
	case COREDUMP_QUERY_GET_ERROR:
		ret = iDfmError;
		break;
	default:
		ret = -ENOTSUP;
		break;
	}

	return ret;
}

struct coredump_backend_api coredump_backend_other = {
	.start = xDfmCoredumpBackendStart,
	.end = xDfmCoredumpBackendEnd,
	.buffer_output = xDfmCoredumpBackendBufferOutput,
	.cmd = xDfmCoredumpBackendCmd,
	.query = xDfmCoredumpBackendQuery
};
#endif

#if defined(CONFIG_PERCEPIO_TRACERECORDER) && defined(CONFIG_PERCEPIO_TRC_CFG_STREAM_PORT_RINGBUFFER)
DfmResult_t xDfmAlertAddTrace(DfmAlertHandle_t xAlertHandle)
{
	void* pvBuffer = (void*)0;
	uint32_t ulBufferSize = 0;

	if (xTraceIsRecorderEnabled() == 1)
	{
		xTraceDisable();
	}
	else
	{
		return DFM_FAIL;
	}

	if (xTraceGetEventBuffer(&pvBuffer, &ulBufferSize) != DFM_SUCCESS)
	{
		return DFM_FAIL;
	}

	if (xDfmAlertAddPayload(xAlertHandle, pvBuffer, ulBufferSize, "dfm_trace.psfs") != DFM_SUCCESS)
	{
		return DFM_FAIL;
	}

	return DFM_SUCCESS;
}
#endif


/* CONFIG_IRQ_OFFLOAD is needed for DFM_TRAP to return */
#if !defined(CONFIG_IRQ_OFFLOAD)
#warning irq_offload() not available, DFM_TRAP() will halt the system
#endif
#if !defined(CONFIG_REBOOT)
#warning sys_reboot() not availabe, DFM_TRAP() cannot restart the system
#endif

#if defined(CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS) && defined(CONFIG_IRQ_OFFLOAD) && defined(CONFIG_ARM)

#include <cmsis_core.h>

static inline int in_msp_context(void)
{
    /* If handler mode (exception/ISR) -> always MSP stack*/
    if (__get_IPSR() != 0U) {
        return 1;
    }

    /* In thread mode -> CONTROL.SPSEL bit tells is MSP or PSP stack is used. */
    return ((__get_CONTROL() & CONTROL_SPSEL_Msk) == 0U) ? 1 : 0;
}

#define DFM_COREDUMP_DEBUG 0

static struct arch_esf regsdump;

static void prvDfmRunCoreDump(const void *parameter)
{
	
	const uint32_t* exc_frame = (const uint32_t *)(uintptr_t)__get_PSP();
	const uint32_t* msp_before_svc = (const uint32_t *)(uintptr_t)parameter;

	/* DFM_TRAP with coredumps assumes Arm Cortex-M
	   This solution relies on the specifics of the Arm Cortex-M SVC handler, 
	   where the first push to the MSP stack is the LR register containing
	   the EXC_RETURN code. This is found at the word before *msp_before_svc.
 	*/
	const uint32_t exc_return = *(msp_before_svc-1);

	if ((exc_return & 0xFFFFFF00U) != 0xFFFFFF00U)
	{
		#if (DFM_COREDUMP_DEBUG == 1)
		printk("prvDfmRunCoreDump: Sanity check of exc_return value failed. Coredump aborted. ")
		#endif

		return;
	}

	#if (DFM_COREDUMP_DEBUG == 1)
	printk("\nException frame at %p:\n\n", exc_frame);		
	printk(" R0:   0x%08X\n", exc_frame[0]);
	printk(" R1:   0x%08X\n", exc_frame[1]);
	printk(" R2:   0x%08X\n", exc_frame[2]);
	printk(" R3:   0x%08X\n", exc_frame[3]);
	printk(" R12:  0x%08X\n", exc_frame[4]);
	printk(" LR:   0x%08X\n", exc_frame[5]);
	printk(" PC:   0x%08X\n", exc_frame[6]);
	printk(" xPSR: 0x%08X\n", exc_frame[7]);
	printk("\nStacked LR/EXC_RETURN: 0x%08x\n", exc_return);	
	#endif

	/* The arch_esf object (regsdump) is used by arch_coredump_info_dump() to read the register values 
	during the coredump() call. */
	memset(&regsdump, 0, sizeof(regsdump));
	
	/* First copy the exception frame (8 regs) that is automatically stacked by the svc exception. */
	memcpy(&regsdump.basic, exc_frame, sizeof(regsdump.basic));
	
	/* If "extra registers" should be included, populate these too. Setting callee to NULL skips assigning
	   the R4-R11 values (since not available).  This is only for compatibility with CONFIG_EXTRA_EXCEPTION_INFO
	   if this option would be desired on fault exceptions. */
#if defined(CONFIG_EXTRA_EXCEPTION_INFO)
	regsdump.extra_info.callee = (void*)0;
	regsdump.extra_info.msp = __get_MSP();
	regsdump.extra_info.exc_return = exc_return;
#endif	

	/* Sets the sp value correctly (so it excludes the hw-stacked exception frame) */
	z_arm_set_fault_sp((struct arch_esf*)exc_frame, exc_return);

	/* Now the regsdump object is ready to enable a regular Zephyr coredump() call. */
	coredump(K_ERR_DFM_TRAP, &regsdump, k_current_get());
}

void prvDfmTrap(int alertType, const char *message, const char *file, int line, int restart)
{
	if (in_msp_context())
	{
		/* Generate an alert without coredump (not supported in MSP/handler mode) */
		return;
	}

	dfmTrapInfo.alertType = alertType;
	dfmTrapInfo.message = message;
	dfmTrapInfo.file = file;
	dfmTrapInfo.line = line;
	dfmTrapInfo.restart = restart;

	/* 
		Since always in PSP/thread mode here, the prvDfmRunCoreDump function can find the exception frame
	   	by reading the thread stack pointer (PSP), which is untouched after this point (prvDfmRunCoreDump
	   	runs in handler mode on MSP stack via irq_offload). We also include the PSP stack pointer before
	   	the SVC exception to find the stacked LR register (EXC_RETURN value) which is stacked right after.
	*/

	irq_offload(prvDfmRunCoreDump, (const void *)(uintptr_t)__get_MSP()); 
}

#endif

#endif

