#ifndef DEMO_CMSIS_H
#define DEMO_CMSIS_H

/* Keep the DFM, CrashCatcher and test sources independent of the selected
 * board. CMake puts this wrapper ahead of the target-specific CMSIS tree. */
#if defined(DEMO_PLATFORM_STM32U585)
#include <stm32u5xx.h>
#else
#include <SMM_MPS2.h>
#endif

#endif /* DEMO_CMSIS_H */
