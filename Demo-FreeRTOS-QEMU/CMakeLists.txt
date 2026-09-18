cmake_minimum_required(VERSION 3.24)

project(Demo-FreeRTOS-QEMU LANGUAGES C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

option(DFM_TESTS_ENABLED "Build the FreeRTOS DFM QEMU test harness" OFF)
set(DEMO_TARGET "qemu_mps2_m3" CACHE STRING
    "Firmware target: qemu_mps2_m3 or b_u585i_iot02a")
set_property(CACHE DEMO_TARGET PROPERTY STRINGS qemu_mps2_m3 b_u585i_iot02a)
set(DEMO_OPTIMIZATION "-O0")

if(DEMO_TARGET STREQUAL "qemu_mps2_m3")
  set(DEMO_CPU_OPTIONS -mcpu=cortex-m3 -mthumb -mfloat-abi=soft)
  set(DEMO_PLATFORM_DEFINE DEMO_PLATFORM_QEMU_MPS2_M3=1)
  set(DEMO_PLATFORM_SOURCES
    src/platform_mps2.c
    src/startup_gcc.c
    src/stdio_uart.c
  )
  set(DEMO_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/linker/mps2_m3.ld")
  set(FREERTOS_PORT_DIR
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/FreeRTOS-Kernel/portable/GCC/ARM_CM3")
  set(FREERTOS_PORT_SOURCES "${FREERTOS_PORT_DIR}/port.c")
  set(DEMO_PLATFORM_INCLUDE_DIRS
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/CMSIS")
  set(DEMO_BUILD_TARGET_NAME "qemu_mps2_an385_cortex_m3")
elseif(DEMO_TARGET STREQUAL "b_u585i_iot02a")
  set(DEMO_CPU_OPTIONS
    -mcpu=cortex-m33 -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard)
  set(DEMO_PLATFORM_DEFINE DEMO_PLATFORM_STM32U585=1)
  set(STM32U5_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/STM32U5")
  set(DEMO_PLATFORM_SOURCES
    src/platform_stm32u585.c
    src/stdio_uart_stm32u585.c
    src/interrupts_stm32u585.c
    "${STM32U5_DIR}/Startup/startup_stm32u585aiix.s"
    "${STM32U5_DIR}/CMSIS/Device/ST/STM32U5xx/Source/Templates/system_stm32u5xx.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_cortex.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_flash.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_flash_ex.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_gpio.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_icache.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_pwr.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_pwr_ex.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_rcc.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_rcc_ex.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_uart.c"
    "${STM32U5_DIR}/HAL/Src/stm32u5xx_hal_uart_ex.c"
  )
  set(DEMO_LINKER_SCRIPT
      "${CMAKE_CURRENT_SOURCE_DIR}/linker/stm32u585aiix_flash.ld")
  set(FREERTOS_PORT_DIR
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/FreeRTOS-Kernel/portable/GCC/ARM_CM33_NTZ/non_secure")
  set(FREERTOS_PORT_SOURCES
    "${FREERTOS_PORT_DIR}/port.c"
    "${FREERTOS_PORT_DIR}/portasm.c"
  )
  set(DEMO_PLATFORM_INCLUDE_DIRS
    "${STM32U5_DIR}/CMSIS/Include"
    "${STM32U5_DIR}/CMSIS/Device/ST/STM32U5xx/Include"
    "${STM32U5_DIR}/HAL/Inc"
  )
  set(DEMO_PLATFORM_DEFINITIONS STM32U585xx USE_HAL_DRIVER)
  set(DEMO_BUILD_TARGET_NAME "b_u585i_iot02a_stm32u585")
else()
  message(FATAL_ERROR "Unsupported DEMO_TARGET: ${DEMO_TARGET}")
endif()

if(DFM_TESTS_ENABLED)
  include("${CMAKE_CURRENT_SOURCE_DIR}/dfm_tests/CMakeLists.txt")
  set(DEMO_OPTIMIZATION "${DFM_TEST_OPTIMIZATION}")
endif()

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
  ${DEMO_CPU_OPTIONS}
  -ffreestanding
  -ffunction-sections
  -fdata-sections
  -fstack-protector-strong
  -fno-omit-frame-pointer
  -g3
  ${DEMO_OPTIMIZATION}
  -Wall
  -Wextra
  -Wshadow
  -Wno-unused-parameter
)
add_compile_definitions(
  ${DEMO_PLATFORM_DEFINE}
  ${DEMO_PLATFORM_DEFINITIONS}
  USE_UNIX_STYLE_LINEBREAKS=1
  PICOLIBC_INTEGER_PRINTF_SCANF=1
  DFM_CFG_CRASH_ADD_TRACE=1
)

if(DFM_TESTS_ENABLED)
  add_compile_definitions(
    DFM_TESTS_ENABLED=1
    DFM_CFG_FIRMWARE_VERSION="${DFM_TEST_VARIANT_REVISION}"
    DFM_CFG_ENABLE_COREDUMPS=${DFM_TEST_ENABLE_COREDUMPS}
    DFM_CFG_STACKDUMP_SIZE=${DFM_TEST_STACKDUMP_SIZE}
  )
  if(NOT DFM_TEST_MAX_COREDUMP_SIZE STREQUAL "")
    add_compile_definitions(
      DFM_CFG_MAX_COREDUMP_SIZE=${DFM_TEST_MAX_COREDUMP_SIZE}
    )
  endif()
else()
  add_compile_definitions(DFM_TESTS_ENABLED=0)
endif()

# FreeRTOS-Kernel's CMake build consumes this interface target.
add_library(freertos_config INTERFACE)
target_include_directories(freertos_config SYSTEM INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/config"
  ${DEMO_PLATFORM_INCLUDE_DIRS}
  "${TRACERECORDER_DIR}/include"
  "${TRACERECORDER_DIR}/kernelports/FreeRTOS/include"
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
  ${FREERTOS_PORT_SOURCES}
  "${FREERTOS_KERNEL_DIR}/portable/MemMang/heap_4.c"
)
target_include_directories(freertos_kernel SYSTEM PUBLIC
  "${FREERTOS_KERNEL_DIR}/include"
  "${FREERTOS_PORT_DIR}"
)
target_link_libraries(freertos_kernel PUBLIC freertos_config)

set(COMMON_INCLUDE_DIRS
  "${CMAKE_CURRENT_SOURCE_DIR}/config"
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  ${DEMO_PLATFORM_INCLUDE_DIRS}
  "${USAGE_EXAMPLES_DIR}"
  "${TRACERECORDER_DIR}/include"
  "${TRACERECORDER_DIR}/kernelports/FreeRTOS/include"
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
  "${TRACERECORDER_DIR}/kernelports/FreeRTOS/trcKernelPort.c"
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

set(DFM_TEST_OBJECTS)
if(DFM_TESTS_ENABLED)
  add_library(dfm_test_firmware OBJECT ${DFM_TEST_SOURCES})
  target_include_directories(dfm_test_firmware PRIVATE
    ${COMMON_INCLUDE_DIRS}
    "${CMAKE_CURRENT_SOURCE_DIR}/dfm_tests/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/dfm_tests/src"
  )
  target_compile_definitions(dfm_test_firmware PRIVATE
    DFM_TEST_VARIANT_ID=${DFM_TEST_VARIANT_ID}
    DFM_TEST_VARIANT_NAME="${DFM_TEST_VARIANT}"
    DFM_TEST_CASE_ID=${DFM_TEST_CASE_ID}
    DFM_TEST_RUN_COOKIE=${DFM_TEST_RUN_COOKIE}
  )
  target_link_libraries(dfm_test_firmware PRIVATE freertos_kernel)
  set(DFM_TEST_OBJECTS $<TARGET_OBJECTS:dfm_test_firmware>)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/dfm_tests/build-config.json.in"
    "${CMAKE_CURRENT_BINARY_DIR}/build-config.json"
    @ONLY
  )
endif()

add_executable(Demo-FreeRTOS-QEMU
  src/main.c
  ${DEMO_PLATFORM_SOURCES}
  $<TARGET_OBJECTS:percepio_trace>
  $<TARGET_OBJECTS:percepio_dfm>
  $<TARGET_OBJECTS:crashcatcher>
  $<TARGET_OBJECTS:usage_examples>
  ${DFM_TEST_OBJECTS}
)
target_include_directories(Demo-FreeRTOS-QEMU PRIVATE ${COMMON_INCLUDE_DIRS})
if(DFM_TESTS_ENABLED)
  target_include_directories(Demo-FreeRTOS-QEMU PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/dfm_tests/include"
  )
  target_compile_definitions(Demo-FreeRTOS-QEMU PRIVATE RUN_TESTS_ONLY=1)
else()
  target_compile_definitions(Demo-FreeRTOS-QEMU PRIVATE RUN_TESTS_ONLY=0)
endif()
target_link_libraries(Demo-FreeRTOS-QEMU PRIVATE freertos_kernel m)
target_link_options(Demo-FreeRTOS-QEMU PRIVATE
  ${DEMO_CPU_OPTIONS}
  --specs=picolibc.specs
  -nostartfiles
  "-T${DEMO_LINKER_SCRIPT}"
  "-Wl,-Map,${CMAKE_CURRENT_BINARY_DIR}/Demo-FreeRTOS-QEMU.map"
  -Wl,--gc-sections
  -Wl,--cref
)
set_target_properties(Demo-FreeRTOS-QEMU PROPERTIES SUFFIX ".elf")

add_custom_command(TARGET Demo-FreeRTOS-QEMU POST_BUILD
  COMMAND "${CMAKE_SIZE}" "$<TARGET_FILE:Demo-FreeRTOS-QEMU>"
  COMMENT "Firmware size"
)

if(DEMO_TARGET STREQUAL "b_u585i_iot02a")
  add_custom_command(TARGET Demo-FreeRTOS-QEMU POST_BUILD
    COMMAND "${CMAKE_OBJCOPY}" -O ihex
            "$<TARGET_FILE:Demo-FreeRTOS-QEMU>"
            "${CMAKE_CURRENT_BINARY_DIR}/Demo-FreeRTOS-QEMU.hex"
    COMMAND "${CMAKE_OBJCOPY}" -O binary
            "$<TARGET_FILE:Demo-FreeRTOS-QEMU>"
            "${CMAKE_CURRENT_BINARY_DIR}/Demo-FreeRTOS-QEMU.bin"
    COMMENT "Generating STM32 HEX and BIN images"
  )
endif()

if(DEMO_TARGET STREQUAL "qemu_mps2_m3")
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
endif()
