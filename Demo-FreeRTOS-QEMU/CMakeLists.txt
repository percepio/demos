cmake_minimum_required(VERSION 3.24)

project(Demo-FreeRTOS-QEMU LANGUAGES C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

get_filename_component(DEMO_REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
set(USAGE_EXAMPLES_DIR "${DEMO_REPO_ROOT}/UsageExamples" CACHE PATH
    "Path to the shared Percepio UsageExamples directory")
set(TRACERECORDER_DIR "${DEMO_REPO_ROOT}/PercepioLibs/TraceRecorder" CACHE PATH
    "Path to the TraceRecorder source directory")
set(DFM_DIR
    "${DEMO_REPO_ROOT}/ZephyrDemo/modules-staging/modules/debug/percepio/DFM"
    CACHE PATH "Path to the DFM source directory")
set(CRASHCATCHER_DIR "${DEMO_REPO_ROOT}/PercepioLibs/CrashCatcher" CACHE PATH
    "Path to the CrashCatcher source directory")
set(FREERTOS_KERNEL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/FreeRTOS-Kernel")

if(NOT EXISTS "${USAGE_EXAMPLES_DIR}/demo_app.c")
  message(FATAL_ERROR "UsageExamples not found at ${USAGE_EXAMPLES_DIR}")
endif()
if(NOT EXISTS "${TRACERECORDER_DIR}/include/trcRecorder.h")
  message(FATAL_ERROR "TraceRecorder not found at ${TRACERECORDER_DIR}")
endif()
if(NOT EXISTS "${DFM_DIR}/include/dfm.h")
  message(FATAL_ERROR "DFM not found at ${DFM_DIR}")
endif()
if(NOT EXISTS "${CRASHCATCHER_DIR}/Core/src/CrashCatcher.c")
  message(FATAL_ERROR "CrashCatcher not found at ${CRASHCATCHER_DIR}")
endif()
if(NOT EXISTS "${FREERTOS_KERNEL_DIR}/include/FreeRTOS.h")
  message(FATAL_ERROR "Vendored FreeRTOS-Kernel not found at ${FREERTOS_KERNEL_DIR}")
endif()

add_compile_options(
  -mcpu=cortex-m3
  -mthumb
  -mfloat-abi=soft
  -ffreestanding
  -ffunction-sections
  -fdata-sections
  -fstack-protector-strong
  -fno-omit-frame-pointer
  -g3
  -O0
  -Wall
  -Wextra
  -Wshadow
  -Wno-unused-parameter
)
add_compile_definitions(
  USE_UNIX_STYLE_LINEBREAKS=1
  PICOLIBC_INTEGER_PRINTF_SCANF=1
)

# FreeRTOS-Kernel's CMake build consumes this interface target.
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/config"
  "${CMAKE_CURRENT_SOURCE_DIR}/third_party/CMSIS"
  "${TRACERECORDER_DIR}/include"
  "${TRACERECORDER_DIR}/streamports/RingBuffer/include"
)

add_library(freertos_kernel STATIC
  "${FREERTOS_KERNEL_DIR}/croutine.c"
  "${FREERTOS_KERNEL_DIR}/event_groups.c"
  "${FREERTOS_KERNEL_DIR}/list.c"
  "${FREERTOS_KERNEL_DIR}/queue.c"
  "${FREERTOS_KERNEL_DIR}/stream_buffer.c"
  "${FREERTOS_KERNEL_DIR}/tasks.c"
  "${FREERTOS_KERNEL_DIR}/timers.c"
  "${FREERTOS_KERNEL_DIR}/portable/GCC/ARM_CM3/port.c"
  "${FREERTOS_KERNEL_DIR}/portable/MemMang/heap_4.c"
)
target_include_directories(freertos_kernel SYSTEM PUBLIC
  "${FREERTOS_KERNEL_DIR}/include"
  "${FREERTOS_KERNEL_DIR}/portable/GCC/ARM_CM3"
)
target_link_libraries(freertos_kernel PUBLIC freertos_config)

set(COMMON_INCLUDE_DIRS
  "${CMAKE_CURRENT_SOURCE_DIR}/config"
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/third_party/CMSIS"
  "${USAGE_EXAMPLES_DIR}"
  "${TRACERECORDER_DIR}/include"
  "${TRACERECORDER_DIR}/streamports/RingBuffer/include"
  "${DFM_DIR}/include"
  "${DFM_DIR}/kernelports/FreeRTOS/include"
  "${DFM_DIR}/cloudports/Serial/include"
  "${DFM_DIR}/storageports/Dummy/include"
  "${CRASHCATCHER_DIR}/include"
  "${CRASHCATCHER_DIR}/Core/src"
)

add_library(percepio_trace OBJECT
  "${TRACERECORDER_DIR}/trcAssert.c"
  "${TRACERECORDER_DIR}/trcCounter.c"
  "${TRACERECORDER_DIR}/trcDependency.c"
  "${TRACERECORDER_DIR}/trcDiagnostics.c"
  "${TRACERECORDER_DIR}/trcEntryTable.c"
  "${TRACERECORDER_DIR}/trcError.c"
  "${TRACERECORDER_DIR}/trcEvent.c"
  "${TRACERECORDER_DIR}/trcEventBuffer.c"
  "${TRACERECORDER_DIR}/trcExtension.c"
  "${TRACERECORDER_DIR}/trcHardwarePort.c"
  "${TRACERECORDER_DIR}/trcHeap.c"
  "${TRACERECORDER_DIR}/trcInternalEventBuffer.c"
  "${TRACERECORDER_DIR}/trcInterval.c"
  "${TRACERECORDER_DIR}/trcISR.c"
  "${TRACERECORDER_DIR}/trcKernelPort.c"
  "${TRACERECORDER_DIR}/trcMultiCoreEventBuffer.c"
  "${TRACERECORDER_DIR}/trcObject.c"
  "${TRACERECORDER_DIR}/trcPrint.c"
  "${TRACERECORDER_DIR}/trcRunnable.c"
  "${TRACERECORDER_DIR}/trcStackMonitor.c"
  "${TRACERECORDER_DIR}/trcStateMachine.c"
  "${TRACERECORDER_DIR}/trcStaticBuffer.c"
  "${TRACERECORDER_DIR}/trcStreamingRecorder.c"
  "${TRACERECORDER_DIR}/trcString.c"
  "${TRACERECORDER_DIR}/trcTask.c"
  "${TRACERECORDER_DIR}/trcTaskMonitor.c"
  "${TRACERECORDER_DIR}/trcTimestamp.c"
  "${TRACERECORDER_DIR}/streamports/RingBuffer/trcStreamPort.c"
)
target_include_directories(percepio_trace PRIVATE ${COMMON_INCLUDE_DIRS})
target_link_libraries(percepio_trace PRIVATE freertos_kernel)

add_library(crashcatcher OBJECT
  "${CRASHCATCHER_DIR}/Core/src/CrashCatcher.c"
  "${CRASHCATCHER_DIR}/Core/src/CrashCatcher_armv7m.S"
)
target_include_directories(crashcatcher PRIVATE ${COMMON_INCLUDE_DIRS})

add_library(percepio_dfm OBJECT
  "${DFM_DIR}/dfm.c"
  "${DFM_DIR}/dfmAlert.c"
  "${DFM_DIR}/dfmCloud.c"
  "${DFM_DIR}/dfmCoreDump-GCC.S"
  "${DFM_DIR}/dfmCrashCatcher.c"
  "${DFM_DIR}/dfmEntry.c"
  "${DFM_DIR}/dfmRetainedMemory.c"
  "${DFM_DIR}/dfmSession.c"
  "${DFM_DIR}/dfmStopwatch.c"
  "${DFM_DIR}/dfmStorage.c"
  "${DFM_DIR}/dfmTaskMonitor.c"
  "${DFM_DIR}/dfmUtility.c"
  "${DFM_DIR}/kernelports/FreeRTOS/dfmKernelPort.c"
  "${DFM_DIR}/cloudports/Serial/dfmCloudPort.c"
  "${DFM_DIR}/storageports/Dummy/dfmStoragePort.c"
)
target_include_directories(percepio_dfm PRIVATE ${COMMON_INCLUDE_DIRS})
target_link_libraries(percepio_dfm PRIVATE freertos_kernel)

add_library(usage_examples OBJECT
  "${USAGE_EXAMPLES_DIR}/demo_app.c"
  "${USAGE_EXAMPLES_DIR}/01_tracerecorder_kernel_tracing.c"
  "${USAGE_EXAMPLES_DIR}/02_tracerecorder_data_logging.c"
  "${USAGE_EXAMPLES_DIR}/03_tracerecorder_state_logging.c"
  "${USAGE_EXAMPLES_DIR}/10_dfm_crash_alert.c"
  "${USAGE_EXAMPLES_DIR}/11_dfm_custom_alert.c"
  "${USAGE_EXAMPLES_DIR}/12_dfm_stack_corruption_alert.c"
  "${USAGE_EXAMPLES_DIR}/13_dfm_stopwatch_alert.c"
  "${USAGE_EXAMPLES_DIR}/14_dfm_taskmonitor_alert.c"
)
target_include_directories(usage_examples PRIVATE ${COMMON_INCLUDE_DIRS})
target_link_libraries(usage_examples PRIVATE freertos_kernel)

add_executable(Demo-FreeRTOS-QEMU
  src/main.c
  src/platform_mps2.c
  src/startup_gcc.c
  src/stdio_uart.c
  $<TARGET_OBJECTS:percepio_trace>
  $<TARGET_OBJECTS:percepio_dfm>
  $<TARGET_OBJECTS:crashcatcher>
  $<TARGET_OBJECTS:usage_examples>
)
target_include_directories(Demo-FreeRTOS-QEMU PRIVATE ${COMMON_INCLUDE_DIRS})
target_link_libraries(Demo-FreeRTOS-QEMU PRIVATE freertos_kernel m)
target_link_options(Demo-FreeRTOS-QEMU PRIVATE
  -mcpu=cortex-m3
  -mthumb
  -mfloat-abi=soft
  --specs=picolibc.specs
  -nostartfiles
  "-T${CMAKE_CURRENT_SOURCE_DIR}/linker/mps2_m3.ld"
  "-Wl,-Map,${CMAKE_CURRENT_BINARY_DIR}/Demo-FreeRTOS-QEMU.map"
  -Wl,--gc-sections
  -Wl,--cref
)
set_target_properties(Demo-FreeRTOS-QEMU PROPERTIES SUFFIX ".elf")

add_custom_command(TARGET Demo-FreeRTOS-QEMU POST_BUILD
  COMMAND "${CMAKE_SIZE}" "$<TARGET_FILE:Demo-FreeRTOS-QEMU>"
  COMMENT "Firmware size"
)

find_program(POWERSHELL_EXECUTABLE NAMES pwsh powershell REQUIRED)
add_custom_target(run
  COMMAND "${POWERSHELL_EXECUTABLE}" -NoProfile -ExecutionPolicy Bypass
          -File "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Invoke-Qemu.ps1"
          -Elf "$<TARGET_FILE:Demo-FreeRTOS-QEMU>"
  DEPENDS Demo-FreeRTOS-QEMU
  USES_TERMINAL
)
add_custom_target(debugserver
  COMMAND "${POWERSHELL_EXECUTABLE}" -NoProfile -ExecutionPolicy Bypass
          -File "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Invoke-Qemu.ps1"
          -Elf "$<TARGET_FILE:Demo-FreeRTOS-QEMU>" -DebugServer
  DEPENDS Demo-FreeRTOS-QEMU
  USES_TERMINAL
)
