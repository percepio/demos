/*
 * Based on the FreeRTOS CORTEX_MPS2_QEMU_IAR_GCC demo startup.
 *
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.
 * SPDX-License-Identifier: MIT
 */

#include <stdint.h>

extern void vPortSVCHandler(void);
extern void xPortPendSVHandler(void);
extern void xPortSysTickHandler(void);
extern void DFM_Fault_Handler(void);

extern int main(void);
extern uint32_t _estack;
extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sbss;
extern uint32_t _ebss;

void Reset_Handler(void);
static void Default_Handler(void) __attribute__((naked));

/* MPS2-AN385 has 32 external interrupt slots. Unused slots deliberately point
 * at Default_Handler so unexpected interrupts stop at a debuggable location. */
const uint32_t * const isr_vector[] __attribute__((section(".isr_vector"), used)) = {
    (uint32_t *)&_estack,
    (uint32_t *)&Reset_Handler,
    (uint32_t *)&Default_Handler,       /* NMI */
    (uint32_t *)&DFM_Fault_Handler,     /* HardFault */
    (uint32_t *)&DFM_Fault_Handler,     /* MemManage */
    (uint32_t *)&DFM_Fault_Handler,     /* BusFault */
    (uint32_t *)&DFM_Fault_Handler,     /* UsageFault */
    0, 0, 0, 0,
    (uint32_t *)&vPortSVCHandler,
    (uint32_t *)&Default_Handler,       /* DebugMon */
    0,
    (uint32_t *)&xPortPendSVHandler,
    (uint32_t *)&xPortSysTickHandler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler,
    (uint32_t *)&Default_Handler, (uint32_t *)&Default_Handler
};

void Reset_Handler(void)
{
    uint32_t *source = &_sidata;
    uint32_t *destination = &_sdata;

    while (destination < &_edata) {
        *destination++ = *source++;
    }

    for (destination = &_sbss; destination < &_ebss; ++destination) {
        *destination = 0U;
    }

    (void)main();
    for (;;) {
        __asm volatile("wfi");
    }
}

static void Default_Handler(void)
{
    __asm volatile(
        "mrs r0, ipsr\n"
        "1: b 1b\n"
    );
}
