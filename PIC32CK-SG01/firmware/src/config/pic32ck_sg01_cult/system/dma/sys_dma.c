/*******************************************************************************
  DMA System Service Library Implementation Source File

  Company
    Microchip Technology Inc.

  File Name
    sys_dma.c

  Summary
    DMA system service library interface implementation.

  Description
    This file implements the interface to the DMA system service library.

  Remarks:
    DMA controller initialize will be done from within the MCC.

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
#include "system/dma/sys_dma.h"

//******************************************************************************
/* Function:
    void SYS_DMA_AddressingModeSetup(SYS_DMA_CHANNEL channel, SYS_DMA_SOURCE_ADDRESSING_MODE sourceAddrMode, SYS_DMA_DESTINATION_ADDRESSING_MODE destAddrMode);

  Summary:
    Setup addressing mode of selected DMA channel.

  Remarks:
    Check sys_dma.h for more info.
*/
void SYS_DMA_AddressingModeSetup(SYS_DMA_CHANNEL channel, SYS_DMA_SOURCE_ADDRESSING_MODE sourceAddrMode, SYS_DMA_DESTINATION_ADDRESSING_MODE destAddrMode)
{
	uint32_t config;
	uint32_t ras_value;
	uint32_t was_value;

	config = (uint32_t)DMA0_ChannelSettingsGet((DMA_CHANNEL)channel);

	ras_value = (config & 0x70U) >> 4;
	was_value = config & 0x07U;

	if (sourceAddrMode == SYS_DMA_SOURCE_ADDRESSING_MODE_FIXED)
	{
		if (ras_value < 3U)
		{
			ras_value += 3U;
		}
	}
	else
	{
		if (ras_value >= 3U)
		{
			ras_value -= 3U;
		}
	}

	if (destAddrMode == SYS_DMA_DESTINATION_ADDRESSING_MODE_FIXED)
	{
		if (was_value < 3U)
		{
			was_value += 3U;
		}
	}
	else
	{
		if (was_value >= 3U)
		{
			was_value -= 3U;
		}
	}
	config = (config & ~0x77U) | ( (ras_value << 4) | was_value );
	(void) DMA0_ChannelSettingsSet((DMA_CHANNEL)channel, (DMA_CHANNEL_CONFIG)config);

}

//******************************************************************************
/* Function:
    void SYS_DMA_DataWidthSetup(SYS_DMA_CHANNEL channel, SYS_DMA_WIDTH dataWidth);

  Summary:
    Setup data width of selected DMA channel.

  Remarks:
    Check sys_dma.h for more info.
*/
void SYS_DMA_DataWidthSetup(SYS_DMA_CHANNEL channel, SYS_DMA_WIDTH dataWidth)
{

	uint32_t config;
	uint32_t ras_value;
	uint32_t was_value;

	config = (uint32_t)DMA0_ChannelSettingsGet((DMA_CHANNEL)channel);

	ras_value = (config & 0x70U) >> 4;
	was_value = config & 0x07U;

	if (ras_value < 3U)
	{
		ras_value = (uint32_t)dataWidth;
	}
	else
	{
		ras_value = 0x03U + (uint32_t)dataWidth;
	}

	if (was_value < 3U)
	{
		was_value = (uint32_t)dataWidth;
	}
	else
	{
		was_value = 0x03U + (uint32_t)dataWidth;
	}


	config = (config & ~0x77U) | ( (ras_value << 4) | was_value );
	(void) DMA0_ChannelSettingsSet((DMA_CHANNEL)channel, (DMA_CHANNEL_CONFIG)config);

}
