This is a temporary staging folder for updated TraceRecorder and DFM versions for Zephyr, to be merged.
See a summary of the changes below. 

To test the ZephyrDemo app as is, patch your modules/debug/percepio folder with these updated versions.

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

 kernelports/zephyr/cloudports/Serial/dfmCloudPort.c
    - Removed crc16_ccitt call for CRC calculation and just setting 0 instead.
      Using the Zephyr CRC functions in the alert output is problematic since the Receiver then must know what RTOS and CRC that is used. 
      Planning to integrate a CRC function in DFM that is the same for all targets/platforms.

 kconfig
    - Added PERCEPIO_DFM_CFG_TASK_MONITOR_MAX_TASKS
    - Added PERCEPIO_DFM_CFG_COREDUMP_SEND (option) to allow sending alerts directly, without using retained memory (not all alerts require a restart)

 kernelports/zephyr/dfmKernelPort.c
    - Various changes, keep all

 dfm.c
    - added cDfmPrintBuffer, keep (was previously in dfmCrashCatcher.c, which isn't used here)

 dfmAlert.c
    - Removed prvDfmAlertCalculateChecksum (was only a placeholder, returned 0)

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







