/*******************************************************************************
  NVIC PLIB Implementation

  Company:
    Microchip Technology Inc.

  File Name:
    plib_nvic.c

  Summary:
    NVIC PLIB Source File

  Description:
    None

*******************************************************************************/

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

#include "device.h"
#include "plib_nvic.h"


// *****************************************************************************
// *****************************************************************************
// Section: NVIC Implementation
// *****************************************************************************
// *****************************************************************************

void NVIC_Initialize( void )
{
    /* Priority 0 to 7 and no sub-priority. 0 is the highest priority */
    NVIC_SetPriorityGrouping( 0x00 );

    /* Enable NVIC Controller */
    __DMB();
    __enable_irq();

    /* Enable the interrupt sources and configure the priorities as configured
     * from within the "Interrupt Manager" of MHC. */
    NVIC_SetTargetState(SVCall_IRQn);
    NVIC_SetTargetState(PendSV_IRQn);
    NVIC_SetTargetState(SysTick_IRQn);
    NVIC_SetTargetState(DMA0_PRI0_IRQn);
    NVIC_SetTargetState(DMA0_PRI1_IRQn);
    NVIC_SetTargetState(DMA0_PRI2_IRQn);
    NVIC_SetTargetState(TCC0_OTHER_IRQn);
    NVIC_SetTargetState(SERCOM4_56_IRQn);
    NVIC_SetTargetState(SERCOM4_0_IRQn);
    NVIC_SetTargetState(SERCOM4_1_IRQn);
    NVIC_SetTargetState(SERCOM4_2_IRQn);
    NVIC_SetTargetState(SERCOM4_3_IRQn);
    NVIC_SetTargetState(SERCOM4_4_IRQn);
    NVIC_SetTargetState(SERCOM5_56_IRQn);
    NVIC_SetTargetState(SERCOM5_0_IRQn);
    NVIC_SetTargetState(SERCOM5_1_IRQn);
    NVIC_SetTargetState(SERCOM5_2_IRQn);
    NVIC_SetTargetState(SERCOM5_3_IRQn);
    NVIC_SetTargetState(SERCOM5_4_IRQn);




}

void NVIC_INT_Enable( void )
{
    __DMB();
    __enable_irq();
}

bool NVIC_INT_Disable( void )
{
    bool processorStatus = (__get_PRIMASK() == 0U);

    __disable_irq();
    __DMB();

    return processorStatus;
}

void NVIC_INT_Restore( bool state )
{
    if( state == true )
    {
        __DMB();
        __enable_irq();
    }
    else
    {
        __disable_irq();
        __DMB();
    }
}

bool NVIC_INT_SourceDisable( IRQn_Type source )
{
    bool processorStatus;
    bool intSrcStatus;

    processorStatus = NVIC_INT_Disable();
    intSrcStatus = (NVIC_GetEnableIRQ(source) != 0U);
    NVIC_DisableIRQ( source );
    NVIC_INT_Restore( processorStatus );

    /* return the source status */
    return intSrcStatus;
}

void NVIC_INT_SourceRestore( IRQn_Type source, bool status )
{
    if( status ) {
       NVIC_EnableIRQ( source );
    }

    return;
}