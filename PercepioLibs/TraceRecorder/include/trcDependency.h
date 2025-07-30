/*
* Percepio Trace Recorder for Tracealyzer v989.878.767
* Copyright 2025 Percepio AB
* www.percepio.com
*
* SPDX-License-Identifier: Apache-2.0
*/

/**
 * @file
 *
 * @brief Public trace dependency APIs.
 */

#ifndef TRC_DEPENDENCY_H
#define TRC_DEPENDENCY_H

#if (TRC_USE_TRACEALYZER_RECORDER == 1)

#include <trcTypes.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup trace_dependency_apis Trace Dependency APIs
 * @ingroup trace_recorder_apis
 * @{
 */

/**
 * @brief Registers a dependency.
 *
 * @param[in] szName Name.
 * @param[in] uxDependencyType The type of dependency.
 *				TRC_DEPENDENCY_TYPE_ELF: .elf file. Currently the only supported type.
 *
 * @retval TRC_FAIL Failure
 * @retval TRC_SUCCESS Success
 */
traceResult xTraceDependencyRegister(const char* szName, TraceUnsignedBaseType_t uxDependencyType);

/** @} */

#ifdef __cplusplus
}
#endif

#else

#ifndef xTraceDependencyRegister
#define xTraceDependencyRegister(szName, uxDependencyType) TRC_COMMA_EXPR_TO_STATEMENT_EXPR_3((void)(szName), (void)(uxDependencyType), TRC_SUCCESS)
#endif

#endif

#endif
