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
 * @brief DFM Zephyr Kernel port API
 */

#ifndef DFM_KERNEL_PORT_H
#define DFM_KERNEL_PORT_H

#include <dfmConfig.h>
#include <zephyr/kernel.h>
#include <zephyr/irq.h>

#if ((DFM_CFG_ENABLED) == 1)

#define K_ERR_DFM_TRAP  (0xd00d)	/* used as a 'reason' when generating a coredump without a fatal error */

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup dfm_kernel_port_zephyr_apis DFM Zephyr Kernel port API
 * @ingroup dfm_apis
 * @{
 */

/**
 * @brief Kernel port system data
 */
typedef struct DfmKernelPortData
{
	uint32_t dummy;
} DfmKernelPortData_t;

/**
 * @brief Initialize Kernel port system
 *
 * @param[in] pxBuffer Kernel port system buffer.
 *
 * @retval DFM_FAIL Failure
 * @retval DFM_SUCCESS Success
 */
DfmResult_t xDfmKernelPortInitialize(DfmKernelPortData_t* pxBuffer);

/**
 * @brief Retrieves the current task name
 *
 * @param[in] ppvTask Pointer where current task will be written.
 *
 * @retval DFM_FAIL Failure
 * @retval DFM_SUCCESS Success
 */
DfmResult_t xDfmKernelPortGetCurrentTaskName(const char** pszTaskName);

/** @} */

/**
 * Disable interrupts, kernel port specific
 */
#define vDfmDisableInterrupts() irq_lock();

#if defined(CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS)
/**
 * Append a coredump to an alert. Where a normal coredump called from the kernel will result in a new alert being generated,
 * this is meant for alerts with a reason >= 0x100. When calling upon this function, the internal state stored within the
 * kernel port is appended to the alert specified (which could be either to be sent directly to the CloudPort or stored
 * by the StoragePort, depending on CloudPort availability and user settings).
 * @param xAlertHandle The alert which the coredump should be attached to
 * @return
 */
DfmResult_t xDfmAlertAddCoredump(DfmAlertHandle_t xAlertHandle);
#else
#define xDfmAlertAddCoredump(xAlertHandle) (DFM_FAIL)
#endif

#if defined(CONFIG_PERCEPIO_TRACERECORDER) && CONFIG_PERCEPIO_TRACERECORDER == 1 && defined(CONFIG_PERCEPIO_TRC_CFG_STREAM_PORT_RINGBUFFER)
/**
 * Attach a trace to the Alert. This requires the TraceAlyzer module to be enabled and configured to use the Ring Buffer.
 * Note that this function will disable tracing to be able to capture and attach the trace, thus, if you wish to have the
 * tracing continue after adding the trace to your alert, you will need to re-enable tracing bu executing xTraceEnable(TRC_START)
 * afterwards.
 *
 * @param xAlertHandle The alert which the trace should be attached to
 * @return
 */
DfmResult_t xDfmAlertAddTrace(DfmAlertHandle_t xAlertHandle);
#endif


typedef struct {
	int alertType;
	const struct arch_esf *esf;
	const char* message;	/* "Assert failed" or similar. */
	const char* file;		/* __FILE__ (full path, filename will be extracted from this) */
	int line;				/* __LINE__ */
	int restart;
} dfmTrapInfo_t;

extern dfmTrapInfo_t dfmTrapInfo;

/**
 * @param message "Assert failed" or similar.
 * @param file    __FILE__ (full path, filename will be extracted from this)
 * @param line    __LINE__
 */
extern void prvDfmTrap(int alertType, const char *message, const char *file, int line, int restart);

/**
 * @param message "Assert failed" or similar.
 * @param restart nonzero if a restart is requested; ignored unless CONFIG_REBOOT
 */
#define DFM_TRAP(type, msg, restart) { prvDfmTrap(type, msg, __FILE__, __LINE__, restart); }


#ifdef __cplusplus
}
#endif

#endif /* DFM_CFG_ENABLED */

#endif /* DFM_KERNEL_PORT_H */
