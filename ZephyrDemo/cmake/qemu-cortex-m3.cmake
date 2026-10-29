# SPDX-License-Identifier: Apache-2.0
# Only the documented LM3S6965 QEMU board uses these logged convenience targets.
# All other boards retain their Zephyr-selected emulator, CPU and runner.
if(NOT CONFIG_BOARD_QEMU_CORTEX_M3)
  return()
endif()

# Native Cortex-Debug in launch.json uses these same board/timing arguments.
# If adapting the QEMU debug profile, update both places together.
set(demo_qemu_flags -cpu cortex-m3 -machine lm3s6965evb -nographic -net none)
if(CONFIG_QEMU_ICOUNT)
  if(CONFIG_QEMU_ICOUNT_SLEEP)
    set(demo_qemu_sleep on)
  else()
    set(demo_qemu_sleep off)
  endif()
  list(APPEND demo_qemu_flags
    -icount "shift=${CONFIG_QEMU_ICOUNT_SHIFT},align=off,sleep=${demo_qemu_sleep}"
    -rtc clock=vm
  )
endif()

# Capture console output without a hub or host-side tee. Normalize the completed
# text log after QEMU exits (Zephyr and Windows can both expand line endings).
# Double commas escape a comma in a QEMU option value (paths with spaces are
# already preserved by VERBATIM).
string(REPLACE "," ",," demo_qemu_log "${CMAKE_CURRENT_SOURCE_DIR}/qemu_last_session.log")
list(APPEND demo_qemu_flags
  -chardev "stdio,id=con,mux=on,logfile=${demo_qemu_log},logappend=off"
  -serial chardev:con -mon chardev=con,mode=readline
)
foreach(target run_logged debugserver_logged)
  set(debug_flags)
  if(target STREQUAL "debugserver_logged")
    set(debug_flags -S -gdb tcp:127.0.0.1:1234)
  endif()
  add_custom_target(${target}
    COMMAND ${QEMU} ${demo_qemu_flags} ${debug_flags}
      -kernel $<TARGET_FILE:${logical_target_for_zephyr_elf}>
    COMMAND ${PYTHON_EXECUTABLE}
      "${CMAKE_CURRENT_SOURCE_DIR}/scripts/normalize_qemu_log.py"
      "${CMAKE_CURRENT_SOURCE_DIR}/qemu_last_session.log"
    DEPENDS ${logical_target_for_zephyr_elf}
    WORKING_DIRECTORY ${APPLICATION_SOURCE_DIR}
    COMMENT "[QEMU] Logging UART to qemu_last_session.log; exit with Ctrl+A, X"
    USES_TERMINAL
    VERBATIM
  )
endforeach()
