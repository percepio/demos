// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*******************************************************************************/
// DOM-IGNORE-END

#include <libpic32c.h>
#include <stdbool.h>
#include <stddef.h>
#include "device.h"
#include "interrupts.h"

/*
 *  The MPLAB X Simulator does not yet support simulation of programming the
 *  GPNVM bits yet. We can remove this once it supports the FRDY bit.
 */
 /* MISRAC 2012 deviation block start */
/* MISRA C-2012 Rule 21.1 deviated 1 time. Deviation record ID -  H3_MISRAC_2012_R_21_1_DR_1 */
#ifdef __MPLAB_DEBUGGER_SIMULATOR
#define __XC32_SKIP_STARTUP_GPNVM_WAIT
#endif
/* MISRAC 2012 deviation block end */

/*
 *  This startup code relies on features that are specific to the MPLAB XC32
 *  toolchain. Do not use it with other toolchains.
 */
#ifndef __XC32
#warning This startup code is intended for use with the MPLAB XC32 Compiler only.
#endif

/* MISRAC 2012 deviation block start */
/* MISRA C-2012 Rule 21.2 deviated 5 times. Deviation record ID -  H3_MISRAC_2012_R_21_2_DR_1 */
/* MISRA C-2012 Rule 8.6 deviated 6 times.  Deviation record ID -  H3_MISRAC_2012_R_8_6_DR_1 */

/* array initialization  function */
extern void __attribute__((long_call)) __libc_init_array(void);

/* Optional application-provided functions */
extern void __attribute__((weak,long_call, alias("Dummy_App_Func"))) _on_reset(void);
extern void __attribute__((weak,long_call, alias("Dummy_App_Func"))) _on_bootstrap(void);

/* Reserved for use by the MPLAB XC32 Compiler */
extern void __attribute__((weak,long_call, alias("Dummy_App_Func"))) __xc32_on_reset(void);
extern void __attribute__((weak,long_call, alias("Dummy_App_Func"))) __xc32_on_bootstrap(void);

/* Linker defined variables */
extern uint32_t __svectors;
#if defined (__REINIT_STACK_POINTER)
extern uint32_t _stack;
#endif

/* MISRAC 2012 deviation block end */


extern int main(void);

__STATIC_INLINE void __attribute__((optimize("-O1"))) CMCC_Configure(void)
{
    CMCC_REGS->CMCC_CTRL &= ~(CMCC_CTRL_CEN_Msk);
    while((CMCC_REGS->CMCC_SR & CMCC_SR_CSTS_Msk) == CMCC_SR_CSTS_Msk)
    {
        /*Wait for the operation to complete*/
    }
    CMCC_REGS->CMCC_CFG = CMCC_CFG_CSIZESW(2U)| CMCC_CFG_DCDIS_Msk;
    CMCC_REGS->CMCC_CTRL = (CMCC_CTRL_CEN_Msk);
}

#if (__ARM_FP==14) || (__ARM_FP==4)

/* Enable FPU */
__STATIC_INLINE void __attribute__((optimize("-O1"))) FPU_Enable(void)
{
    uint32_t primask = __get_PRIMASK();
    __disable_irq();
    SCB->CPACR |= (((uint32_t)0xFU) << 20);
    SCB->NSACR |= (((uint32_t)0x3U) << 10);
    FPU->FPCCR |= (uint32_t)0xfc000000U;
    __DSB();
    __ISB();

    if (primask == 0U)
    {
        __enable_irq();
    }
}
#endif /* (__ARM_FP==14) || (__ARM_FP==4) */


/* Brief default application function used as a weak reference */
extern void Dummy_App_Func(void);
void __attribute__((optimize("-O1"),long_call))Dummy_App_Func(void)
{
    /* Do nothing */
    return;
}

/**
 * \brief This is the code that gets called on processor reset.
 * To initialize the device, and call the main() routine.
 */
void __attribute__((optimize("-O1"), section(".text.Reset_Handler"), long_call, noreturn)) Reset_Handler(void)
{
#ifdef SCB_VTOR_TBLOFF_Msk
    uint32_t *pSrc;
#endif

#if defined (__REINIT_STACK_POINTER)
    /* Initialize SP from linker-defined _stack symbol. */
    __set_MSP((uint32_t)&_stack);

#ifdef SCB_VTOR_TBLOFF_Msk
    /* Buy stack for locals */
    __asm__ volatile ("sub sp, sp, #8" : : : "sp");
#endif
    __asm__ volatile ("add r7, sp, #0" : : : "r7");
#endif

    /* Call the optional application-provided _on_reset() function. */
    _on_reset();

    /* Reserved for use by MPLAB XC32. */
    __xc32_on_reset();

#if (__ARM_FP==14) || (__ARM_FP==4)
    /* Enable the FPU if the application is built with -mfloat-abi=softfp or -mfloat-abi=hard */
    FPU_Enable();
#endif

    /* Configure CMCC */
    CMCC_Configure();

    /* Copy the demo variable to a local varible, restore it after!*/
    
    /* Initialize data after TCM is enabled.
     * Data initialization from the XC32 .dinit template */
    __pic32c_data_initialization();


#  ifdef SCB_VTOR_TBLOFF_Msk
    /*  Set the vector-table base address in FLASH */
    pSrc = (uint32_t *) & __svectors;
    SCB->VTOR = ((uint32_t) pSrc & SCB_VTOR_TBLOFF_Msk);
#  endif /* SCB_VTOR_TBLOFF_Msk */

    /* Initialize the C library */
    __libc_init_array();

    /* Call the optional application-provided _on_bootstrap() function. */
    _on_bootstrap();

    /* Reserved for use by MPLAB XC32. */
    __xc32_on_bootstrap();

    /* Branch to application's main function */
    (void)main();

#if (defined(__DEBUG) || defined(__DEBUG_D)) && defined(__XC32)
    __builtin_software_breakpoint();
#endif

    while (true)
    {
        /* Infinite loop */
    }
}
