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
 * @brief DFM Crash Catcher integration defines
 */

#ifndef DFM_CRASHCATCHER_H
#define DFM_CRASHCATCHER_H

#include <dfmCrashCatcherConfig.h>

#define CRASH_DUMP_NAME "cc_coredump.dmp"

/**
 * @brief Should call a function that reboots device
 * Example: #define CRASH_STRATEGY_RESET() HAL_NVIC_SystemReset()
 */
#define CRASH_STRATEGY_RESET() NVIC_SystemReset()

/**
 * @brief Endless loop
 * Example: #define CRASH_STRATEGY_LOOP() while(1)
 */
#define CRASH_STRATEGY_LOOP() while(1)

/**
 * @brief Strategy to use after crash has been handled
 * Values: CRASH_STRATEGY_RESET() or CRASH_STRATEGY_LOOP()
 */
#define CRASH_FINALIZE() DFM_DEBUG_PRINT("DFM: Restarting...\n\n\n"); for (volatile int i = 0; i < 1000000; i++); CRASH_STRATEGY_RESET()

#define CRASH_STACK_CAPTURE_SIZE DFM_CFG_STACKDUMP_SIZE

/* Additional memory ranges to include in the crash dump (e.g. heap memory) */
#define CRASH_MEM_REGION1_START	0xFFFFFFFF /* 0xFFFFFFFF = not used */
#define CRASH_MEM_REGION1_SIZE	0

#define CRASH_MEM_REGION2_START	0xFFFFFFFF /* 0xFFFFFFFF = not used */
#define CRASH_MEM_REGION2_SIZE	0

#define CRASH_MEM_REGION3_START	0xFFFFFFFF /* 0xFFFFFFFF = not used */
#define CRASH_MEM_REGION3_SIZE	0

/* CRASH_DUMP_MAX_SIZE - The size of the temporary RAM buffer for crash dumps.
 * Any attempt to write outside this buffer will be caught in CrashCatcher_DumpMemory() and give an error.
 * Enable DFM_CFG_USE_DEBUG_LOGGING to see the actual usage.
 * */
#define CRASH_DUMP_BUFFER_SIZE (300 + (CRASH_STACK_CAPTURE_SIZE) + (CRASH_MEM_REGION1_SIZE) + (CRASH_MEM_REGION2_SIZE) + (CRASH_MEM_REGION3_SIZE))

typedef struct{
	int alertType;
	char* message;
	char* file;
	int line;
	int restart;
} dfmTrapInfo_t;

extern dfmTrapInfo_t dfmTrapInfo;

extern __attribute__ ((naked)) void dfmCoreDump(void);
  
/* The byte pattern used in DFM_STACK_MARKER. */
#define DFM_STACK_MARKER_MAGIC_STR "coredump_end"
 
/* Saves the arguments to DFM_TRAP in dfmTrapInfo, while preserving all 
  registers so not obstructing the state before the core dump (dfmCoreDump). 
  Must be a macro to avoid modifying r0-r3 before the core dump. */
#define DFM_TRAP_SAVE_ARGS(_alertType, _message, _file, _line, _restart_flag) \
        __asm volatile ("push {r0-r12}" ::: "memory");                        \
        dfmTrapInfo.alertType = (int)(_alertType);                            \
        dfmTrapInfo.message   = (char*)(_message);                            \
        dfmTrapInfo.file      = (char*)(_file);                               \
        dfmTrapInfo.line      = (int)(_line);                                 \
        dfmTrapInfo.restart   = (int)(_restart_flag);                         \
        __asm volatile ("pop  {r0-r12}" ::: "memory");
    
/******************************************************************************
 * DFM_TRAP(alertType, message, restart_flag)
 *
 * Allows for manually triggering a core dump from code, e.g. in error handling
 * code. This can be called from all contexts - from tasks, exceptions and in
 * the startup code (main). Note that fault exceptions doesn't require using
 * DFM_TRAP(), as they are captured by the CrashCatcher fault handler.
 *  
 * Arguments:
 *
 *   - alertType: An integer code for the alert type, matching the Detect
 *                 server configuration (normally to dfmCodes.h).
 *   - message: A string with additional details about the fault.
 *
 *   - restart_flag: If 1, the processor is restarted afterwards.
 *                   If 0, the execution resumes.
 * Example:
 *
 *  if (arg1 < 0) {
 *     DFM_TRAP(DFM_TYPE_ASSERT_FAILED, "Argument arg1 < 0", 0); // No restart
 *     return ERR;
 *  }
 *  
 * Note: On ArmV8-M devices like Cortex M33, the hardware stack overflow
 * checking might kick in on DFM_TRAP() since CrashCatcher jumps to
 * its own stack. If the CC stack happens to be at a lower address than PSPLIM
 * (or MSPLIM) it will appear as a stack overflow a fault exception. 
 * So if PSPLIM or MSPLIM are used (non-zero), they must be set to 0 before 
 * DFM_TRAP is called (and restored if no restart).
 *****************************************************************************/
#define DFM_TRAP(alertType, message, restart_flag)                            \
  do {                                                                        \
    DFM_TRAP_SAVE_ARGS(alertType, message, __FILE__, __LINE__, restart_flag); \
    dfmCoreDump();                                                            \
  } while (0)

/******************************************************************************
 * DFM_STACK_MARKER()
 * Put this first in the task entry function to crop the stack dumps, reducing
 * their size and avoiding GDB warnings from confused stack unwinding.
 *****************************************************************************/
#define DFM_STACK_MARKER() \
    __attribute__((aligned(4))) \
    volatile char dfm_stack_marker[] = DFM_STACK_MARKER_MAGIC_STR;

    
    
#endif
