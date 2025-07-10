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

#include <stm32l4xx.h>

/**
 * @brief How many bytes to dump from the stack (relative to current stack pointer).
 */
#define DFM_CFG_STACKDUMP_SIZE 300

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
#define DFM_CFG_ADDR_CHECK_NEXT 0x20018000

/**
 * @brief If this is set to 1 it will attempt to also save a trace with the Alert. This requires the Percepio Trace Recorder to also be included in the project.
 */
#define DFM_CFG_CRASH_ADD_TRACE	(1)

#ifdef __cplusplus
}
#endif

#endif /* DFM_CRASH_CATCHER_CONFIG_H */
