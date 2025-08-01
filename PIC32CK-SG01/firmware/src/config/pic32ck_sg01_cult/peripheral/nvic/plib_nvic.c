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
* Copyright (C) 2020 Microchip Technology Inc. and its subsidiaries.
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
    /* Enable the interrupt sources as configured from within the "Interrupt Manager" of MHC. */
    NVIC_SetPriority(DMA0_PRI0_IRQn, 7);
    NVIC_EnableIRQ(DMA0_PRI0_IRQn);
    NVIC_SetPriority(DMA0_PRI1_IRQn, 7);
    NVIC_EnableIRQ(DMA0_PRI1_IRQn);
    NVIC_SetPriority(DMA0_PRI2_IRQn, 7);
    NVIC_EnableIRQ(DMA0_PRI2_IRQn);
    NVIC_SetPriority(TCC0_OTHER_IRQn, 7);
    NVIC_EnableIRQ(TCC0_OTHER_IRQn);
    NVIC_SetPriority(SERCOM4_56_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_56_IRQn);
    NVIC_SetPriority(SERCOM4_0_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_0_IRQn);
    NVIC_SetPriority(SERCOM4_1_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_1_IRQn);
    NVIC_SetPriority(SERCOM4_2_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_2_IRQn);
    NVIC_SetPriority(SERCOM4_3_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_3_IRQn);
    NVIC_SetPriority(SERCOM4_4_IRQn, 7);
    NVIC_EnableIRQ(SERCOM4_4_IRQn);
    NVIC_SetPriority(SERCOM5_56_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_56_IRQn);
    NVIC_SetPriority(SERCOM5_0_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_0_IRQn);
    NVIC_SetPriority(SERCOM5_1_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_1_IRQn);
    NVIC_SetPriority(SERCOM5_2_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_2_IRQn);
    NVIC_SetPriority(SERCOM5_3_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_3_IRQn);
    NVIC_SetPriority(SERCOM5_4_IRQn, 7);
    NVIC_EnableIRQ(SERCOM5_4_IRQn);

}

void NVIC_INT_Enable( void )
{
    __DMB();
    __enable_irq();
}

bool NVIC_INT_Disable( void )
{
    bool processorStatus;

    processorStatus = (bool) (__get_PRIMASK() == 0);

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
