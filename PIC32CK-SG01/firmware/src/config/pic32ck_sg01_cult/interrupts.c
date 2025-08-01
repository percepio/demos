/*******************************************************************************
 System Interrupts File

  Company:
    Microchip Technology Inc.

  File Name:
    interrupt.c

  Summary:
    Interrupt vectors mapping

  Description:
    This file maps all the interrupt vectors to their corresponding
    implementations. If a particular module interrupt is used, then its ISR
    definition can be found in corresponding PLIB source file. If a module
    interrupt is not used, then its ISR implementation is mapped to dummy
    handler.
 *******************************************************************************/

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

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************
#include "configuration.h"
#include "device_vectors.h"
#include "interrupts.h"
#include "definitions.h"
#include "portasm.h"




// *****************************************************************************
// *****************************************************************************
// Section: System Interrupt Vector Functions
// *****************************************************************************
// *****************************************************************************

/* MISRA C-2012 Rule 8.6 deviated below. Deviation record ID -  H3_MISRAC_2012_R_8_6_DR_1 */
extern uint32_t _stack;
extern const H3DeviceVectors exception_table;

extern void Dummy_Handler(void);

/* Brief default interrupt handler for unused IRQs.*/
void __attribute__((optimize("-O1"), long_call, noreturn, used))Dummy_Handler(void)
{
#if defined(__DEBUG) || defined(__DEBUG_D) && defined(__XC32)
    __builtin_software_breakpoint();
#endif
    while (true)
    {
    }
}

/* MISRAC 2012 deviation block start */
/* MISRA C-2012 Rule 8.6 deviated 1 times.  Deviation record ID -  H3_MISRAC_2012_R_8_6_DR_1 */
/* Device vectors list dummy definition*/
extern void xPortSysTickHandler        ( void ) __attribute__((weak, alias("Dummy_Handler")));


/* MISRAC 2012 deviation block end */

/* Multiple handlers for vector */


extern void DFM_Fault_Handler(void);

__attribute__ ((section(".vectors"), used))
const H3DeviceVectors exception_table=
{
    /* Configure Initial Stack Pointer, using linker-generated symbols */
    .pvStack = &_stack,

    .pfnReset_Handler              = Reset_Handler,
    .pfnNonMaskableInt_Handler     = DFM_Fault_Handler, 
    .pfnHardFault_Handler          = DFM_Fault_Handler, /* HardFault_Handler*/     
    .pfnMemoryManagement_Handler   = DFM_Fault_Handler,
    .pfnBusFault_Handler           = DFM_Fault_Handler,
    .pfnUsageFault_Handler         = DFM_Fault_Handler,
    .pfnSecureFaultMonitor_Handler = DFM_Fault_Handler,
    .pfnSVCall_Handler             = vPortSVCHandler,
    .pfnPendSV_Handler             = xPortPendSVHandler,
    .pfnSysTick_Handler            = xPortSysTickHandler,
    .pfnDMA0_PRI0_Handler          = DMA0_PRI0_InterruptHandler,
    .pfnDMA0_PRI1_Handler          = DMA0_PRI1_InterruptHandler,
    .pfnDMA0_PRI2_Handler          = DMA0_PRI2_InterruptHandler,
    .pfnTCC0_OTHER_Handler         = TCC0_OTHER_InterruptHandler,
    .pfnSERCOM4_56_Handler         = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM4_0_Handler          = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM4_1_Handler          = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM4_2_Handler          = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM4_3_Handler          = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM4_4_Handler          = SERCOM4_I2C_InterruptHandler,
    .pfnSERCOM5_56_Handler         = SERCOM5_USART_InterruptHandler,
    .pfnSERCOM5_0_Handler          = SERCOM5_USART_InterruptHandler,
    .pfnSERCOM5_1_Handler          = SERCOM5_USART_InterruptHandler,
    .pfnSERCOM5_2_Handler          = SERCOM5_USART_InterruptHandler,
    .pfnSERCOM5_3_Handler          = SERCOM5_USART_InterruptHandler,
    .pfnSERCOM5_4_Handler          = SERCOM5_USART_InterruptHandler,


};

/*******************************************************************************
 End of File
*/
