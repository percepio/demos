# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

set(DEMO_PERCEPIO_SOURCE "local" CACHE STRING "Percepio sources: local or upstream")
set_property(CACHE DEMO_PERCEPIO_SOURCE PROPERTY STRINGS local upstream)
if(DEMO_PERCEPIO_SOURCE STREQUAL "local")
  foreach(library DFM TraceRecorder)
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../PercepioLibs/${library}/kernelports/Zephyr/Kconfig")
      message(FATAL_ERROR
        "Local ${library} sources are missing from ../PercepioLibs. "
        "Check out the complete demo repository or select -DDEMO_PERCEPIO_SOURCE=upstream.")
    endif()
  endforeach()
  list(APPEND EXTRA_ZEPHYR_MODULES "${CMAKE_CURRENT_LIST_DIR}/modules/percepio")
elseif(NOT DEMO_PERCEPIO_SOURCE STREQUAL "upstream")
  message(FATAL_ERROR "DEMO_PERCEPIO_SOURCE must be local or upstream")
endif()
message(STATUS "Percepio source: ${DEMO_PERCEPIO_SOURCE}")

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(zephyr)

# Keep repository source paths relative to the shipped debug bundle.
get_filename_component(DEMO_REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
zephyr_compile_options(
  "-fdebug-prefix-map=${DEMO_REPO_ROOT}=src"
  "-fdebug-prefix-map=${ZEPHYR_BASE}/kernel=."  
)

# Logged terminal targets for the documented QEMU board; other boards keep
# Zephyr's native run/debug/flash targets.
include(cmake/qemu-cortex-m3.cmake)

if(DEFINED DEBUG_PRINTF)
  zephyr_compile_definitions(DEBUG_PRINTF=${DEBUG_PRINTF})
endif()
if(DEFINED SAME_PRIO)
  zephyr_compile_definitions(SAME_PRIO)
endif()
if(DEFINED STATIC_OBJS)
  zephyr_compile_definitions(STATIC_OBJS)
endif()
if(DEFINED FORKS)
  zephyr_compile_definitions(FORKS=${FORKS})
endif()

target_sources(app PRIVATE  
  src/main.c
  src/qemu_reboot_workaround.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/demo_app.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/01_tracerecorder_kernel_tracing.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/02_tracerecorder_data_logging.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/03_tracerecorder_state_logging.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/10_dfm_crash_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/11_dfm_custom_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/12_dfm_stack_corruption_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/13_dfm_stopwatch_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/14_dfm_taskmonitor_alert.c  
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/15_dfm_custom_payload_alert.c
  )

target_include_directories(app PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/src
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples
 )
