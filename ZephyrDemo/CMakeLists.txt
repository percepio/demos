# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(zephyr)

# Zephyr's standard QEMU console is connected to stdio. Add a project-specific
# debug-server target that sends the guest console through QEMU's hub to both
# stdio and a file in the application root, without an external tee utility.
# A separate file backend is important on Windows: logging the stdio backend
# directly turns the guest's CRLF line endings into CRCRLF.
if(CONFIG_BOARD_QEMU_CORTEX_M3)
  get_property(qemu_device_flags GLOBAL PROPERTY ZEPHYR_QEMU_FLAGS_DEVICE)
  set(qemu_logged_device_flags)
  set(qemu_console_found FALSE)
  set(qemu_monitor_option_found FALSE)
  set(qemu_monitor_found FALSE)

  foreach(qemu_flag IN LISTS qemu_device_flags)
    if(qemu_flag STREQUAL "stdio,id=con,mux=on")
      list(APPEND qemu_logged_device_flags
        "stdio,id=qemu_stdio"
        -chardev
        "file,id=qemu_log,path=${CMAKE_CURRENT_LIST_DIR}/qemu_last_session.log,append=off"
        -chardev
        "hub,id=con,chardevs.0=qemu_stdio,chardevs.1=qemu_log"
      )
      set(qemu_console_found TRUE)
    elseif(qemu_flag STREQUAL "-mon")
      list(APPEND qemu_logged_device_flags -monitor)
      set(qemu_monitor_option_found TRUE)
    elseif(qemu_flag STREQUAL "chardev=con,mode=readline")
      # A hub cannot be stacked with Zephyr's console multiplexer. The GDB
      # monitor remains available through the gdbstub for reset and shutdown.
      list(APPEND qemu_logged_device_flags none)
      set(qemu_monitor_found TRUE)
    else()
      list(APPEND qemu_logged_device_flags "${qemu_flag}")
    endif()
  endforeach()

  if(NOT qemu_console_found OR
     NOT qemu_monitor_option_found OR
     NOT qemu_monitor_found)
    message(FATAL_ERROR "Could not create the logged QEMU console")
  endif()

  get_property(qemu_extra_flags GLOBAL PROPERTY ZEPHYR_QEMU_FLAGS_EXTRA)
  get_property(qemu_debugserver_flags GLOBAL PROPERTY ZEPHYR_QEMU_TARGET_FLAGS_debugserver_qemu)
  get_property(qemu_target_depends GLOBAL PROPERTY ZEPHYR_QEMU_TARGET_DEPENDS)

  add_custom_target(debugserver_qemu_logged
    COMMAND
      ${QEMU}
      ${QEMU_BOARD_FLAGS}
      ${qemu_logged_device_flags}
      ${qemu_extra_flags}
      ${qemu_debugserver_flags}
      -kernel $<TARGET_FILE:${logical_target_for_zephyr_elf}>
    DEPENDS ${logical_target_for_zephyr_elf}
    WORKING_DIRECTORY ${APPLICATION_BINARY_DIR}
    COMMENT "[QEMU] Starting GDB server and logging console to qemu_last_session.log"
    USES_TERMINAL
  )

  if(qemu_target_depends)
    add_dependencies(debugserver_qemu_logged ${qemu_target_depends})
  endif()
endif()

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
  )

target_include_directories(app PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/src
  ${CMAKE_CURRENT_LIST_DIR}/../UsageExamples
 )
