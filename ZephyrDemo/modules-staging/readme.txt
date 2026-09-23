This is a temporary staging folder for updated TraceRecorder and DFM versions for Zephyr, to be merged.
See a summary of the changes below. 

To test the ZephyrDemo app as is, patch your modules/debug/percepio folder with these updated versions.

Zephyr integration reminder:
When applying these staging updates, also update the following file (path
relative to the Zephyr west workspace root):

zephyr/modules/percepio/CMakeLists.txt

A copy of the currently required, corrected integration file is included
beside this readme.txt as CMakeLists.txt.

(This folder can be deleted later, after the merging is done and tested.)
 
DFM 
 include/dfm.h
    - DFM_CFG_MAX_STOPWATCHES, move setting to kconfig
    - Various other changes (keep all)

 include/dfmCodes.h
    - Added new symptom type (reason)

 include/dfmStopwatch.h
    - Added include stdint.h

 include/dfmTaskMonitor.h
    - Removed DFM_CFG_ENABLE_TASK_MONITOR (only TRC_CFG_ENABLE_TASK_MONITOR is important, to enable/disable the switchout hook)

 dfmUtility.c
    - Provides a software-only CRC-16/CCITT implementation, independently of Zephyr's CRC backend

 kernelports/zephyr/cloudports/Serial/dfmCloudPort.c
    - Uses the DFM CRC-16/CCITT implementation instead of Zephyr's CRC API

 kconfig
    - Added PERCEPIO_DFM_CFG_TASK_MONITOR_MAX_TASKS
    - Added PERCEPIO_DFM_CFG_COREDUMP_SEND (option) to allow sending alerts directly, without using retained memory (not all alerts require a restart)
    - Made PERCEPIO_DFM_CFG_ADD_TRACE independent of PERCEPIO_DFM_CFG_ENABLE_COREDUMPS

 kernelports/zephyr/dfmKernelPort.c
    - Various changes, keep all

 dfm.c
    - added cDfmPrintBuffer, keep (was previously in dfmCrashCatcher.c, which isn't used here)

 dfmAlert.c
    - Removed prvDfmAlertCalculateChecksum (was only a placeholder, returned 0)
    - Commits retained memory only after the complete alert has been written

 dfmRetainedMemory.c, include/dfmRetainedMemory.h
    - Added the retained-memory commit step

 kernelports/zephyr/dfmRetainedMemoryPort.c
    - Uses the generic retained-memory backend for fast clear and entry writes
    - Accumulates SUM32 while writing and verifies it once after restart

 dfmCraschCatcher.c
    - Removed DFM_DEBUG_PRINT, replaced with existing DFM_CFG_PRINT

 dfmStopwatch.c
    - Various small fixes, keep all

 dfmTaskMonitor.c
    - DFM_SYMPTOM_CURRENT_TASK still reports 0 as symptom, since no CRC function. Perhaps remove this symptom?


TraceRecorder

 trcHardwarePort.h
    - Support for DWT timestamping in Zephyr (keep!) - #if (CONFIG_PERCEPIO_TRC_CFG_USE_CORTEX_M_DWT == 1)

 trcTaskMonitor.c
    - Fixed issue with secondary alerts, caused by alert send overhead ("ignoreDirtyPeriod" flag)

 trcKernelPort.c 
    - Added DWT init (#if (CONFIG_PERCEPIO_TRC_USE_DWT_TS == 1) ...)
    - Added filtering of k_busy_wait calls.

 kconfig 
    - Added PERCEPIO_TRC_CFG_USE_CORTEX_M_DWT
    - Added PERCEPIO_TRC_CFG_INCLUDE_BUSY_WAIT (default no)
    - Added PERCEPIO_TRC_CFG_INCLUDE_YIELD (default yes)
    - Added PERCEPIO_TRC_CFG_INCLUDE_SCHED_LOCK (default yes)

 config/core/trcConfig.h
    - Added definition of TRC_CFG_ENABLE_TASK_MONITOR based on kconfig







