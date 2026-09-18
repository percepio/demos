#include "FreeRTOS.h"

extern void DFM_Fault_Handler(void);

#define DFM_FAULT_WRAPPER(name_)                    \
    void name_(void) __attribute__((naked));         \
    void name_(void)                                \
    {                                                \
        __asm volatile("b DFM_Fault_Handler");       \
    }

/* The donor startup vector deliberately sends NMI, MemManage, BusFault and
 * UsageFault through CrashCatcher's HardFault_Handler entry. SecureFault has
 * a separate vector slot and therefore needs the same explicit branch. */
DFM_FAULT_WRAPPER(SecureFault_Handler)

#if DFM_TESTS_ENABLED
extern void DFM_Test_IRQHandler(void);

void EXTI0_IRQHandler(void)
{
    DFM_Test_IRQHandler();
}
#endif
