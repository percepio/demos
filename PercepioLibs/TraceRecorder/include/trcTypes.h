/*
* Percepio Trace Recorder for Tracealyzer v989.878.767
* Copyright 2025 Percepio AB
* www.percepio.com
*
* SPDX-License-Identifier: Apache-2.0
*
* The common types.
*/

#ifndef TRC_TYPES_H
#define TRC_TYPES_H

#include <stdint.h>
#include <trcConfig.h>
#include <trcHardwarePort.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef TRC_BASE_TYPE
#define TRC_BASE_TYPE int32_t
#endif

#ifndef TRC_UNSIGNED_BASE_TYPE
#define TRC_UNSIGNED_BASE_TYPE uint32_t
#endif

typedef TRC_UNSIGNED_BASE_TYPE TraceUnsignedBaseType_t;

typedef TRC_BASE_TYPE TraceBaseType_t;

typedef void* TraceHandleBaseType_t;

typedef TraceUnsignedBaseType_t traceResult;

typedef TraceHandleBaseType_t TraceEventHandle_t;

typedef TraceHandleBaseType_t TraceISRHandle_t;

typedef TraceHandleBaseType_t TraceEntryHandle_t;

typedef TraceHandleBaseType_t TraceTaskHandle_t;

typedef TraceHandleBaseType_t TraceObjectHandle_t;

typedef TraceHandleBaseType_t TraceExtensionHandle_t;

typedef TraceHandleBaseType_t TraceHeapHandle_t;

typedef TraceHandleBaseType_t TraceIntervalChannelSetHandle_t;

typedef TraceHandleBaseType_t TraceIntervalChannelHandle_t;

typedef TraceHandleBaseType_t TraceIntervalInstanceHandle_t;

typedef TraceHandleBaseType_t TraceStateMachineHandle_t;

typedef TraceHandleBaseType_t TraceStateMachineStateHandle_t;

typedef TraceHandleBaseType_t TraceStringHandle_t;

typedef TraceHandleBaseType_t TraceCounterHandle_t;

typedef TraceHandleBaseType_t TraceRunnableHandle_t;

typedef TraceHandleBaseType_t TraceRunnableStaticSetHandle_t;

typedef TraceHandleBaseType_t TraceProcessHandle_t;

typedef TraceHandleBaseType_t TraceThreadHandle_t;

typedef void (*TraceCounterCallback_t)(TraceCounterHandle_t xCounterHandle);

#ifdef __cplusplus
}
#endif

#endif /* TRC_TYPES_H */
