/*******************************************************************************
  Direct Memory Access Controller (DMA) PLIB

  Company
    Microchip Technology Inc.

  File Name
    plib_dma0.c

  Summary
    Source for DMA0 peripheral library interface Implementation.

  Description
    This file defines the interface to the DMA peripheral library. This
    library provides access to and control of the DMA controller.

  Remarks:
    None.

*******************************************************************************/

// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2021 Microchip Technology Inc. and its subsidiaries.
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

#include "plib_dma0.h"
#include "interrupts.h"

// *****************************************************************************
// *****************************************************************************
// Section: Global Data
// *****************************************************************************
// *****************************************************************************

#define DMA_CHANNELS_NUMBER        (1U)

/* DMA channels object configuration structure */
typedef struct
{
    DMA_CHANNEL_CALLBACK  callback;
    uintptr_t             context;
    bool                  busyStatus;
} DMA_CH_OBJECT ;

/* DMA Channels object information structure */
volatile static DMA_CH_OBJECT dmaChannelObj[DMA_CHANNELS_NUMBER];

// *****************************************************************************
// *****************************************************************************
// Section: DMA PLib Interface Implementations
// *****************************************************************************
// *****************************************************************************

/*******************************************************************************
This function initializes the DMA controller of the device.
********************************************************************************/

void DMA0_Initialize( void )
{
    uint32_t channel = 0U;

    /* Initialize DMA Channel objects */
    for(channel = 0U; channel < DMA_CHANNELS_NUMBER; channel++)
    {
        dmaChannelObj[channel].callback = NULL;
        dmaChannelObj[channel].context = 0U;
        dmaChannelObj[channel].busyStatus = false;
    }




   /***************** Configure DMA channel 0 ********************/
   DMA0_REGS->CHANNEL[0].DMA_CHCTRLB = DMA_CHCTRLB_TRIG(44U) | DMA_CHCTRLB_PRI(DMA_CHCTRLB_PRI_PRI_1_Val) | DMA_CHCTRLB_RAS(DMA_CHCTRLB_RAS_BYTE_ADDR_INCR_Val) | DMA_CHCTRLB_WAS(DMA_CHCTRLB_WAS_FIXED_BYTE_ADDR_INCR_Val) | DMA_CHCTRLB_CASTEN(0U) ;
   

   DMA0_REGS->CHANNEL[0].DMA_CHXSIZ = DMA_CHXSIZ_CSZ(1U);

   

   DMA0_REGS->CHANNEL[0].DMA_CHINTENSET = DMA_CHINTENSET_BC_Msk;

   


    /* Global configuration */
    DMA0_REGS->DMA_CTRLA = DMA_CTRLA_ENABLE_Msk;
}


/*******************************************************************************
    This function schedules a DMA transfer on the specified DMA channel.
********************************************************************************/

bool DMA0_ChannelTransfer( DMA_CHANNEL channel, const void *srcAddr, const void *destAddr, size_t blockSize )
{
    bool returnStatus = false;

    const uint32_t *XsrcAddr  = (const uint32_t *)srcAddr;
    const uint32_t *XdestAddr = (const uint32_t *)destAddr;

    if (dmaChannelObj[channel].busyStatus == false)
    {
        dmaChannelObj[channel].busyStatus = true;

        /*Set source address */
        DMA0_REGS->CHANNEL[channel].DMA_CHSSA = (uint32_t) XsrcAddr;

        /*Set destination address */
        DMA0_REGS->CHANNEL[channel].DMA_CHDSA = (uint32_t) XdestAddr;

        /* Set the block transfer size in bytes */
        DMA0_REGS->CHANNEL[channel].DMA_CHXSIZ = (DMA0_REGS->CHANNEL[channel].DMA_CHXSIZ & ~DMA_CHXSIZ_BLKSZ_Msk) | (blockSize << DMA_CHXSIZ_BLKSZ_Pos);

        /* Enable the channel */
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA |= DMA_CHCTRLA_ENABLE_Msk;

        /* Verify if Trigger source is Software Trigger */
        if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB & DMA_CHCTRLB_TRIG_Msk) >> DMA_CHCTRLB_TRIG_Pos) == 0x00U)
        {
            /* Trigger the DMA transfer */
            DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA |= DMA_CHCTRLA_SWFRC_Msk;
        }

        returnStatus = true;
    }

    return returnStatus;
}


/*******************************************************************************
    This function function allows a DMA PLIB client to set an event handler.
********************************************************************************/

void DMA0_ChannelCallbackRegister( DMA_CHANNEL channel, const DMA_CHANNEL_CALLBACK callback, const uintptr_t context )
{
    dmaChannelObj[channel].callback = callback;
    dmaChannelObj[channel].context  = context;
}

/*******************************************************************************
    This function returns the status of the channel.
********************************************************************************/

bool DMA0_ChannelIsBusy ( DMA_CHANNEL channel )
{
    return (dmaChannelObj[channel].busyStatus);
}

/*******************************************************************************
    This function disables the specified DMA channel.
********************************************************************************/
void DMA0_ChannelEnable ( DMA_CHANNEL channel )
{
    /* Enable the DMA channel */
    DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA |= DMA_CHCTRLA_ENABLE_Msk;

    dmaChannelObj[channel].busyStatus=true;

}

void DMA0_ChannelDisable ( DMA_CHANNEL channel )
{
    /* Disable the DMA channel */
    DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA &= (~DMA_CHCTRLA_ENABLE_Msk);

    while((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk) != 0U)
    {
        /* Do nothing */

    }

    dmaChannelObj[channel].busyStatus=false;

}

uint32_t DMA0_ChannelGetTransferredCount( DMA_CHANNEL channel )
{
    return (DMA0_REGS->CHANNEL[channel].DMA_CHSTATBC & DMA_CHSTATBC_Msk);
}

void DMA0_ChannelInterruptEnable ( DMA_CHANNEL channel, DMA_INT intSources )
{
    DMA0_REGS->CHANNEL[channel].DMA_CHINTENSET = intSources;
}

void DMA0_ChannelInterruptDisable ( DMA_CHANNEL channel, DMA_INT intSources )
{
    DMA0_REGS->CHANNEL[channel].DMA_CHINTENCLR = intSources;
}

DMA_INT DMA0_ChannelInterruptFlagsGet ( DMA_CHANNEL channel )
{
    return (uint8_t) (DMA0_REGS->CHANNEL[channel].DMA_CHINTF & DMA_CHINTF_Msk);
}

/*-----------------------DMA Pattern Match Related APIs-----------------------*/
void DMA0_ChannelPatternMatchSetup ( DMA_CHANNEL channel, DMA_PATTERN_MATCH_LEN patternLen, uint16_t matchData )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHPDAT = (DMA0_REGS->CHANNEL[channel].DMA_CHPDAT & ~DMA_CHPDAT_PDAT_Msk) | (matchData << DMA_CHPDAT_PDAT_Pos);

        if (patternLen == DMA_PATTERN_MATCH_LEN_1BYTE)
        {
            DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB &= ~DMA_CHCTRLB_PATLEN_Msk;
        }
        else
        {
            DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB |= DMA_CHCTRLB_PATLEN_Msk;
        }

        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB |= DMA_CHCTRLB_PATEN_Msk;
    }
}

void DMA0_ChannelPatternMatchEnable ( DMA_CHANNEL channel )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB |= DMA_CHCTRLB_PATEN_Msk;
    }
}

void DMA0_ChannelPatternMatchDisable ( DMA_CHANNEL channel )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB &= ~DMA_CHCTRLB_PATEN_Msk;
    }
}

void DMA0_ChannelPatternIgnoreByteEnable ( DMA_CHANNEL channel )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB |= DMA_CHCTRLB_PIGNEN_Msk;
    }
}

void DMA0_ChannelPatternIgnoreByteDisable ( DMA_CHANNEL channel )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB &= ~DMA_CHCTRLB_PIGNEN_Msk;
    }
}

void DMA0_ChannelPatternIgnoreValue ( DMA_CHANNEL channel, uint8_t ignoreValue )
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHPDAT = (DMA0_REGS->CHANNEL[channel].DMA_CHPDAT & ~DMA_CHPDAT_PIGN_Msk) | ((uint32_t)ignoreValue << DMA_CHPDAT_PIGN_Pos);
    }
}

/*-----------------------------------------------------------------------------*/

/*******************************************************************************
    This function returns the current channel settings for the specified DMA Channel
********************************************************************************/

DMA_CHANNEL_CONFIG DMA0_ChannelSettingsGet (DMA_CHANNEL channel)
{
    return DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB;
}

/*******************************************************************************
    This function changes the current settings of the specified DMA channel.
********************************************************************************/

bool DMA0_ChannelSettingsSet (DMA_CHANNEL channel, DMA_CHANNEL_CONFIG setting)
{
    bool ChannelSettingsSet = false;
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if (((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk)) == 0U)
    {
        /* Set the new settings */
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB = setting;
        ChannelSettingsSet = true;
    }

    return ChannelSettingsSet;
}

/*******************************************************************************
    This function disables the CRC functionality of the specified DMA channel
********************************************************************************/

void DMA0_ChannelCRCDisable(DMA_CHANNEL channel)
{
    // CHCTRLBk is CHCTRLAk.ENABLE=1 write protected
    if ((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk) == 0U)
    {
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB &= ~DMA_CHCTRLB_CRCEN_Msk;
    }
}

/*******************************************************************************
    This function sets the CRC functionality of the specified DMA channel
    for calculating CRC. This Function has to be called before submitting
    DMA transfer request for the channel to calculate CRC
********************************************************************************/

void DMA0_ChannelCRCSetup(DMA_CHANNEL channel, DMA_CRC_SETUP *CRCSetup)
{
    uint32_t crcSettings = 0U;

    /* Disable CRC Engine before configuring */
    DMA0_ChannelCRCDisable(channel);

    if ((CRCSetup->crc_mode == DMA_CRC_MODE_16_BIT_CRCPOLYA) || (CRCSetup->crc_mode == DMA_CRC_MODE_32_BIT_CRCPOLYA))
    {
        DMA0_REGS->DMA_CRCPOLYA = CRCSetup->polynomial;
    }
    else if ((CRCSetup->crc_mode == DMA_CRC_MODE_16_BIT_CRCPOLYB) || (CRCSetup->crc_mode == DMA_CRC_MODE_32_BIT_CRCPOLYB))
    {
        DMA0_REGS->DMA_CRCPOLYB = CRCSetup->polynomial;
    }
    else
    {
       /* MISRA C compliance */
    }

    /* CHCTRLBk is CHCTRLAk.ENABLE=1 write protected */
    if ((DMA0_REGS->CHANNEL[channel].DMA_CHCTRLA & DMA_CHCTRLA_ENABLE_Msk) == 0U)
    {
        /* Store Initial Seed value */
        DMA0_REGS->CHANNEL[channel].DMA_CHCRCDAT = CRCSetup->seed;

        crcSettings = DMA_CHCTRLCRC_CRCMD(CRCSetup->crc_mode);

        if (CRCSetup->appendMode)
        {
            crcSettings |= DMA_CHCTRLCRC_CRCAPP_Msk;
        }
        if (CRCSetup->xorMode)
        {
            crcSettings |= DMA_CHCTRLCRC_CRCXOR_Msk;
        }
        if (CRCSetup->reflectedOutput)
        {
            crcSettings |= DMA_CHCTRLCRC_CRCROUT_Msk;
        }
        if (CRCSetup->reflectedInput)
        {
            crcSettings |= DMA_CHCTRLCRC_CRCRIN_Msk;
        }

        /* Setup the CRC engine for DMA Channel */
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLCRC = crcSettings;

        /* Enable CRC for DMA Channel */
        DMA0_REGS->CHANNEL[channel].DMA_CHCTRLB |= DMA_CHCTRLB_CRCEN_Msk;
    }
}

/*******************************************************************************
    This function returns the caclculated CRC Value.
********************************************************************************/

uint32_t DMA0_ChannelCRCRead(DMA_CHANNEL channel)
{
    return DMA0_REGS->CHANNEL[channel].DMA_CHCRCDAT;
}

//*******************************************************************************
//    Functions to handle DMA interrupt events.
//*******************************************************************************
static void __attribute__((used)) DMA_interruptHandler(uint32_t channel)
{
    volatile DMA_CH_OBJECT  *dmacChObj;
    volatile uint32_t chIntFlagStatus = 0U;
    volatile uint32_t chIntFlagsEnabled = 0U;

    DMA_TRANSFER_EVENT event = 0U;

    dmacChObj = &dmaChannelObj[channel];

    /* Get the DMA channel interrupt flag status */
    chIntFlagStatus = DMA0_REGS->CHANNEL[channel].DMA_CHINTF;

    /* Update the event flag for the interrupts that have been enabled. Always update for Read and Write error interrupts */
    chIntFlagsEnabled = chIntFlagStatus & (DMA0_REGS->CHANNEL[channel].DMA_CHINTENSET | (DMA_CHINTF_WRE_Msk | DMA_CHINTF_RDE_Msk));

    /* An start trigger event has been detected and the block transfer has started */
    if ((chIntFlagsEnabled & DMA_CHINTF_SD_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_START_DETECTED;
    }

    /* An abort trigger event has been detected and the DMA transfer has been aborted */
    if ((chIntFlagsEnabled & DMA_CHINTF_TA_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_TRANSFER_ABORTED;
    }

    /* A cell transfer has been completed (CSZ bytes has been transferred) */
    if ((chIntFlagsEnabled & DMA_CHINTF_CC_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_CELL_TRANSFER_COMPLETE;
    }

    /* A block transfer has been completed */
    if ((chIntFlagsEnabled & DMA_CHINTF_BC_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_BLOCK_TRANSFER_COMPLETE;
    }

    /* A half block transfer has been completed */
    if ((chIntFlagsEnabled & DMA_CHINTF_BH_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_HALF_BLOCK_TRANSFER_COMPLETE;
    }

    /* A link list done event has been completed */
    if ((chIntFlagsEnabled & DMA_CHINTF_LL_Msk) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_LINKED_LIST_TRANSFER_COMPLETE;
    }

    /* A write error or read error event has been detected */
    if ((chIntFlagsEnabled & (DMA_CHINTF_WRE_Msk | DMA_CHINTF_RDE_Msk)) != 0U)
    {
        event |= DMA_TRANSFER_EVENT_ERROR;
    }

    if ((chIntFlagStatus & (DMA_CHINTF_WRE_Msk | DMA_CHINTF_RDE_Msk | DMA_CHINTF_LL_Msk | DMA_CHINTF_BC_Msk | DMA_CHINTF_TA_Msk)) != 0U)
    {
        dmacChObj->busyStatus = false;
    }

    /* Clear all the interrupt flags */
    DMA0_REGS->CHANNEL[channel].DMA_CHINTF = chIntFlagStatus;

    /* Execute the callback function */
    if ((dmacChObj->callback != NULL) && (event != 0U))
    {
        uintptr_t context = dmacChObj->context;

        dmacChObj->callback (event, context);
    }
}

void __attribute__((used)) DMA0_PRI0_InterruptHandler( void )
{
    volatile uint32_t dmaIntPriority1Status = 0U;
    uint32_t channel = 0U;

    /* Get the DMA channel interrupt status */
    dmaIntPriority1Status = DMA0_REGS->DMA_INTSTAT1;

    for (channel = 0U; channel < 1U; channel++)
    {
        if ((dmaIntPriority1Status & ((uint32_t)1U << channel)) != (uint32_t)0U)
        {
            DMA_interruptHandler(channel);
        }
    }
}
void __attribute__((used)) DMA0_PRI1_InterruptHandler( void )
{
    volatile uint32_t dmaIntPriority2Status = 0U;
    uint32_t channel = 0U;

    /* Get the DMA channel interrupt status */
    dmaIntPriority2Status = DMA0_REGS->DMA_INTSTAT2;

    for (channel = 0U; channel < 1U; channel++)
    {
        if ((dmaIntPriority2Status & ((uint32_t)1U << channel)) != (uint32_t)0U)
        {
            DMA_interruptHandler(channel);
        }
    }
}
void __attribute__((used)) DMA0_PRI2_InterruptHandler( void )
{
    volatile uint32_t dmaIntPriority3Status = 0U;
    uint32_t channel = 0U;

    /* Get the DMA channel interrupt status */
    dmaIntPriority3Status = DMA0_REGS->DMA_INTSTAT3;

    for (channel = 0U; channel < 1U; channel++)
    {
        if ((dmaIntPriority3Status & ((uint32_t)1U << channel)) != (uint32_t)0U)
        {
            DMA_interruptHandler(channel);
        }
    }
}
