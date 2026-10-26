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
 * @brief DFM CrashCatcher integration config
 */

#ifndef DFM_CRASH_CATCHER_CONFIG_H
#define DFM_CRASH_CATCHER_CONFIG_H

#ifdef __cplusplus
extern "C" {
#endif

#include <cmsis.h>

/* CMSIS only exposes these ARMv8-M registers for ARMv8 builds. The shared DFM
 * source calls them unconditionally; on ARMv7-M they are architecturally absent
 * and the intended behavior is a read-as-zero/write-ignored shim. */
#if (__CORTEX_M < 0x08U)
#define __get_PSPLIM() (0U)
#define __set_PSPLIM(value_) ((void)(value_))
#define __get_MSPLIM() (0U)
#define __set_MSPLIM(value_) ((void)(value_))
#endif

/**
 * @brief How many bytes to dump from the stack (relative to current stack pointer).
 */
#ifndef DFM_CFG_STACKDUMP_SIZE
#define DFM_CFG_STACKDUMP_SIZE 300
#endif

#ifndef DFM_CFG_ENABLE_COREDUMPS
#define DFM_CFG_ENABLE_COREDUMPS 1
#endif

/**
 * @brief Start of RAM where the stack(s) are found.
 *
 * Set DFM_CFG_ADDR_CHECK_BEGIN to the beginning of RAM where your stack(s) are
 * located. Note that the whole memory range between DFM_CFG_ADDR_CHECK_BEGIN
 * and (DFM_CFG_ADDR_CHECK_NEXT - 1) must be readable.
 */
#define DFM_CFG_ADDR_CHECK_BEGIN 0x20000000

/**
 * @brief Maximum limit of stack dump.
 *
 * Set DFM_CFG_ADDR_CHECK_NEXT to the first invalid address after the stack(s).
 * In other words, the first byte that must not be read by the stack dump.
 * For example, a reserved memory range following the SRAM.
 */
#if defined(DEMO_PLATFORM_STM32U585)
#define DFM_CFG_ADDR_CHECK_NEXT 0x200C0000
#else
#define DFM_CFG_ADDR_CHECK_NEXT 0x20400000
#endif

/**
 * @brief If this is set to 1 it will attempt to also save a trace with the Alert. This requires the Percepio Trace Recorder to also be included in the project.
 */
#define DFM_CFG_CRASH_ADD_TRACE	(1)

#ifdef __cplusplus
}
#endif

#endif /* DFM_CRASH_CATCHER_CONFIG_H */
