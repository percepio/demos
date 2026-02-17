# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(zephyr)

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
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/demo_app.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/01_tracerecorder_kernel_tracing.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/02_tracerecorder_data_logging.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/03_tracerecorder_state_logging.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/10_dfm_crash_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/11_dfm_custom_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/12_dfm_stack_corruption_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/13_dfm_stopwatch_alert.c
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples/14_dfm_taskmonitor_alert.c  
  )

target_include_directories(app PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/src
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples
 )
