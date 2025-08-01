/*******************************************************************************
  Serial Communication Interface Inter-Integrated Circuit (SERCOM I2C) Library
  Source File

  Company:
    Microchip Technology Inc.

  File Name:
    plib_sercom4_i2c.c

  Summary:
    SERCOM I2C PLIB Implementation file

  Description:
    This file defines the interface to the SERCOM I2C peripheral library.
    This library provides access to and control of the associated peripheral
    instance.

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

#include "interrupts.h"
#include "plib_sercom4_i2c_master.h"


// *****************************************************************************
// *****************************************************************************
// Section: Global Data
// *****************************************************************************
// *****************************************************************************


#define SERCOM4_I2CM_SPEED_HZ           100000

/* SERCOM4 I2C baud value */
#define SERCOM4_I2CM_BAUD_VALUE         (0xFFU)


volatile static SERCOM_I2C_OBJ sercom4I2CObj;

// *****************************************************************************
// *****************************************************************************
// Section: SERCOM4 I2C Implementation
// *****************************************************************************
// *****************************************************************************
// *****************************************************************************

void SERCOM4_I2C_Initialize(void)
{
    /* Reset the module */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA = SERCOM_I2CM_CTRLA_SWRST_Msk ;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Enable smart mode */
    SERCOM4_REGS->I2CM.SERCOM_CTRLB = SERCOM_I2CM_CTRLB_SMEN_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Baud rate - Master Baud Rate*/
    SERCOM4_REGS->I2CM.SERCOM_BAUD = SERCOM4_I2CM_BAUD_VALUE;

    /* Set Operation Mode (Master), SDA Hold time, run in stand by and i2c master enable */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA = SERCOM_I2CM_CTRLA_MODE_I2C_MASTER | SERCOM_I2CM_CTRLA_SDAHOLD_75NS | SERCOM_I2CM_CTRLA_SPEED_SM | SERCOM_I2CM_CTRLA_SCLSM(0UL) | SERCOM_I2CM_CTRLA_ENABLE_Msk | SERCOM_I2CM_CTRLA_SLEWRATE(SERCOM_I2CM_CTRLA_SLEWRATE_FM_Val);

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Initial Bus State: IDLE */
    SERCOM4_REGS->I2CM.SERCOM_STATUS = (uint16_t)SERCOM_I2CM_STATUS_BUSSTATE(0x01UL);

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Initialize the SERCOM4 PLib Object */
    sercom4I2CObj.error = SERCOM_I2C_ERROR_NONE;
    sercom4I2CObj.state = SERCOM_I2C_STATE_IDLE;

    /* Enable all Interrupts */
    SERCOM4_REGS->I2CM.SERCOM_INTENSET = (uint8_t)SERCOM_I2CM_INTENSET_Msk;
}

static bool SERCOM4_I2C_CalculateBaudValue(uint32_t srcClkFreq, uint32_t i2cClkSpeed, uint32_t* baudVal)
{
    uint32_t baudValue = 0U;
    float fSrcClkFreq = (float)srcClkFreq;
    float fI2cClkSpeed = (float)i2cClkSpeed;
    float fBaudValue = 0.0f;

    /* Reference clock frequency must be atleast two times the baud rate */
    if (srcClkFreq < (2U * i2cClkSpeed))
    {
        return false;
    }

    if (i2cClkSpeed <= 1000000U)
    {
        /* Standard, FM and FM+ baud calculation */
        fBaudValue = (fSrcClkFreq / fI2cClkSpeed) - ((fSrcClkFreq * (100.0f / 1000000000.0f)) + 10.0f);
        baudValue = (uint32_t)fBaudValue;
    }
    else
    {
        return false;
    }
    if (i2cClkSpeed <= 400000U)
    {
        /* For I2C clock speed upto 400 kHz, the value of BAUD<7:0> determines both SCL_L and SCL_H with SCL_L = SCL_H */
        if (baudValue > (0xFFU * 2U))
        {
            /* Set baud rate to the minimum possible value */
            baudValue = 0xFFU;
        }
        else if (baudValue <= 1U)
        {
            /* Baud value cannot be 0. Set baud rate to maximum possible value */
            baudValue = 1U;
        }
        else
        {
            baudValue /= 2U;
        }
    }
    else
    {
        /* To maintain the ratio of SCL_L:SCL_H to 2:1, the max value of BAUD_LOW<15:8>:BAUD<7:0> can be 0xFF:0x7F. Hence BAUD_LOW + BAUD can not exceed 255+127 = 382 */
        if (baudValue >= 382U)
        {
            /* Set baud rate to the minimum possible value while maintaining SCL_L:SCL_H to 2:1 */
            baudValue = (0xFFUL << 8U) | (0x7FU);
        }
        else if (baudValue <= 3U)
        {
            /* Baud value cannot be 0. Set baud rate to maximum possible value while maintaining SCL_L:SCL_H to 2:1 */
            baudValue = (2UL << 8U) | 1U;
        }
        else
        {
            /* For Fm+ mode, I2C SCL_L:SCL_H to 2:1 */
            baudValue  = ((((baudValue * 2U)/3U) << 8U) | (baudValue/3U));
        }
    }
    *baudVal = baudValue;
    return true;
}

bool SERCOM4_I2C_TransferSetup(SERCOM_I2C_TRANSFER_SETUP* setup, uint32_t srcClkFreq )
{
    uint32_t baudValue;
    uint32_t i2cClkSpeed;
    uint32_t i2cSpeedMode = 0;

    if (setup == NULL)
    {
        return false;
    }

    i2cClkSpeed = setup->clkSpeed;

    if( srcClkFreq == 0U)
    {
        srcClkFreq = 60000000UL;
    }

    if (SERCOM4_I2C_CalculateBaudValue(srcClkFreq, i2cClkSpeed, &baudValue) == false)
    {
        return false;
    }

    if (i2cClkSpeed > 400000U)
    {
        i2cSpeedMode = 1U;
    }

    /* Disable the I2C before changing the I2C clock speed */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA &= ~SERCOM_I2CM_CTRLA_ENABLE_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }


    /* Baud rate - Master Baud Rate*/
    SERCOM4_REGS->I2CM.SERCOM_BAUD = baudValue;

    SERCOM4_REGS->I2CM.SERCOM_CTRLA  = ((SERCOM4_REGS->I2CM.SERCOM_CTRLA & ~SERCOM_I2CM_CTRLA_SPEED_Msk) | (SERCOM_I2CM_CTRLA_SPEED(i2cSpeedMode)));

    /* Re-enable the I2C module */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA |= SERCOM_I2CM_CTRLA_ENABLE_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }


    /* Since the I2C module was disabled, re-initialize the bus state to IDLE */
    SERCOM4_REGS->I2CM.SERCOM_STATUS = (uint16_t)SERCOM_I2CM_STATUS_BUSSTATE(0x01UL);

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    return true;
}

void SERCOM4_I2C_CallbackRegister(SERCOM_I2C_CALLBACK callback, uintptr_t contextHandle)
{
    sercom4I2CObj.callback = callback;

    sercom4I2CObj.context  = contextHandle;
}


static void SERCOM4_I2C_SendAddress(uint16_t address, bool dir)
{
    /* If operation is I2C read */
    if(dir)
    {
        /* <xxxx-xxxR> <read-data> <P> */

        /* Next state will be to read data */
        sercom4I2CObj.state = SERCOM_I2C_STATE_TRANSFER_READ;
    }
    else
    {
        /* <xxxx-xxxW> <write-data> <P> */

        /* Next state will be to write data */
        sercom4I2CObj.state = SERCOM_I2C_STATE_TRANSFER_WRITE;
    }


    SERCOM4_REGS->I2CM.SERCOM_ADDR = ((uint32_t)address << 1U) | (dir ? 1UL :0UL);

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

}

static void SERCOM4_I2C_InitiateTransfer(uint16_t address, bool dir)
{
    sercom4I2CObj.writeCount = 0U;
    sercom4I2CObj.readCount = 0U;

    /* Clear all flags */
    SERCOM4_REGS->I2CM.SERCOM_INTFLAG = (uint8_t)SERCOM_I2CM_INTFLAG_Msk;

    /* Smart mode enabled with SCLSM = 0, - ACK is set to send while receiving the data */
    SERCOM4_REGS->I2CM.SERCOM_CTRLB &= ~SERCOM_I2CM_CTRLB_ACKACT_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }


    SERCOM4_I2C_SendAddress(address, dir);
}

static bool SERCOM4_I2C_XferSetup(
    uint16_t address,
    uint8_t* wrData,
    uint32_t wrLength,
    uint8_t* rdData,
    uint32_t rdLength,
    bool dir,
    bool isHighSpeed
)
{
    /* Check for ongoing transfer */
    if(sercom4I2CObj.state != SERCOM_I2C_STATE_IDLE)
    {
        return false;
    }

    sercom4I2CObj.address        = address;
    sercom4I2CObj.readBuffer     = rdData;
    sercom4I2CObj.readSize       = rdLength;
    sercom4I2CObj.writeBuffer    = wrData;
    sercom4I2CObj.writeSize      = wrLength;
    sercom4I2CObj.transferDir    = dir;
    sercom4I2CObj.isHighSpeed    = isHighSpeed;
    sercom4I2CObj.error          = SERCOM_I2C_ERROR_NONE;


    SERCOM4_I2C_InitiateTransfer(address, dir);

    return true;
}

bool SERCOM4_I2C_Read(uint16_t address, uint8_t* rdData, uint32_t rdLength)
{
    return SERCOM4_I2C_XferSetup(address, NULL, 0, rdData, rdLength, true, false);
}

bool SERCOM4_I2C_Write(uint16_t address, uint8_t* wrData, uint32_t wrLength)
{
    return SERCOM4_I2C_XferSetup(address, wrData, wrLength, NULL, 0, false, false);
}

bool SERCOM4_I2C_WriteRead(uint16_t address, uint8_t* wrData, uint32_t wrLength, uint8_t* rdData, uint32_t rdLength)
{
    return SERCOM4_I2C_XferSetup(address, wrData, wrLength, rdData, rdLength, false, false);
}


bool SERCOM4_I2C_BusScan(uint16_t start_addr, uint16_t end_addr, void* pDevicesList, uint8_t* nDevicesFound)
{
    uint8_t* pDevList = (uint8_t*)pDevicesList;
    uint8_t nDevFound = 0;

    /* Check for ongoing transfer */
    if(sercom4I2CObj.state != SERCOM_I2C_STATE_IDLE)
    {
        return false;
    }

    if ((pDevicesList == NULL) || (nDevicesFound == NULL))
    {
        return false;
    }

    *nDevicesFound = 0;

    /* Clear all flags */
    SERCOM4_REGS->I2CM.SERCOM_INTFLAG = (uint8_t)SERCOM_I2CM_INTFLAG_Msk;

    /* Disable all interrupts */
    SERCOM4_REGS->I2CM.SERCOM_INTENCLR = (uint8_t)SERCOM_I2CM_INTENCLR_Msk;

    for (uint16_t dev_addr = start_addr; dev_addr <= end_addr; dev_addr++)
    {
        while(((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_BUSSTATE_Msk) != SERCOM_I2CM_STATUS_BUSSTATE(0x01U)))
        {
            /* Wait for the bus to become IDLE */
        }

        /* Put the 7-bit device address on the bus with WR bit */
            SERCOM4_REGS->I2CM.SERCOM_ADDR = ((uint32_t)dev_addr << 1U);

        /* Wait for synchronization */
        while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
        {
            /* Do nothing */
        }

        while ((SERCOM4_REGS->I2CM.SERCOM_INTFLAG & SERCOM_I2CM_INTFLAG_MB_Msk) == 0U)
        {
            /* Wait for the address transfer to complete */
        }

        if ((SERCOM4_REGS->I2CM.SERCOM_STATUS & (SERCOM_I2CM_STATUS_ARBLOST_Msk | SERCOM_I2CM_STATUS_BUSERR_Msk | SERCOM_I2CM_STATUS_RXNACK_Msk)) == 0U)
        {
            /* No error and device responded with an ACK. Add the device to the list of found devices. */
            pDevList[nDevFound] = (uint8_t)dev_addr;

            nDevFound += 1U;
        }

        /* Issue stop condition */
        SERCOM4_REGS->I2CM.SERCOM_CTRLB |= SERCOM_I2CM_CTRLB_CMD(3UL);

        /* Wait for synchronization */
        while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
        {
            /* Do nothing */
        }
    }

    *nDevicesFound = nDevFound;

    /* Re-enable all interrupts */
    SERCOM4_REGS->I2CM.SERCOM_INTENSET = (uint8_t)SERCOM_I2CM_INTENSET_Msk;

    return true;
}

bool SERCOM4_I2C_IsBusy(void)
{
    bool isBusy = true;
    if((sercom4I2CObj.state == SERCOM_I2C_STATE_IDLE))
    {
        if(((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_BUSSTATE_Msk) == SERCOM_I2CM_STATUS_BUSSTATE(0x01U)))
        {
           isBusy = false;
        }
    }
    return isBusy;
}

SERCOM_I2C_ERROR SERCOM4_I2C_ErrorGet(void)
{
    return sercom4I2CObj.error;
}

void SERCOM4_I2C_TransferAbort( void )
{
    sercom4I2CObj.error = SERCOM_I2C_ERROR_NONE;

    // Reset the plib to IDLE state
    sercom4I2CObj.state = SERCOM_I2C_STATE_IDLE;

    /* Disable the I2C module */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA &= ~SERCOM_I2CM_CTRLA_ENABLE_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Re-enable the I2C module */
    SERCOM4_REGS->I2CM.SERCOM_CTRLA |= SERCOM_I2CM_CTRLA_ENABLE_Msk;

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }

    /* Since the I2C module was disabled, re-initialize the bus state to IDLE */
    SERCOM4_REGS->I2CM.SERCOM_STATUS = (uint16_t)SERCOM_I2CM_STATUS_BUSSTATE(0x01UL);

    /* Wait for synchronization */
    while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
    {
        /* Do nothing */
    }
}

void __attribute__((used)) SERCOM4_I2C_InterruptHandler(void)
{
    if(SERCOM4_REGS->I2CM.SERCOM_INTENSET != 0U)
    {
        uintptr_t context = sercom4I2CObj.context;

        /* Checks if the arbitration lost in multi-master scenario */
        if((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_ARBLOST_Msk) == SERCOM_I2CM_STATUS_ARBLOST_Msk)
        {
            /* Set Error status */
            sercom4I2CObj.state = SERCOM_I2C_STATE_ERROR;
            sercom4I2CObj.error = SERCOM_I2C_ERROR_BUS;

        }
        /* Check for Bus Error during transmission */
        else if((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_BUSERR_Msk) == SERCOM_I2CM_STATUS_BUSERR_Msk)
        {
            /* Set Error status */
            sercom4I2CObj.state = SERCOM_I2C_STATE_ERROR;
            sercom4I2CObj.error = SERCOM_I2C_ERROR_BUS;
        }
        /* Checks slave acknowledge for address or data */
        else if((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_RXNACK_Msk) == SERCOM_I2CM_STATUS_RXNACK_Msk)
        {
            sercom4I2CObj.state = SERCOM_I2C_STATE_ERROR;
            sercom4I2CObj.error = SERCOM_I2C_ERROR_NAK;
        }
        else
        {
            switch(sercom4I2CObj.state)
            {
                case SERCOM_I2C_REINITIATE_TRANSFER:

                    if (sercom4I2CObj.writeSize != 0U)
                    {
                        /* Initiate Write transfer */
                        SERCOM4_I2C_InitiateTransfer(sercom4I2CObj.address, false);
                    }
                    else
                    {
                        /* Initiate Read transfer */
                        SERCOM4_I2C_InitiateTransfer(sercom4I2CObj.address, true);
                    }

                    break;


                case SERCOM_I2C_STATE_IDLE:

                    break;



                case SERCOM_I2C_STATE_TRANSFER_WRITE:
                {
                    size_t writeCount = sercom4I2CObj.writeCount;

                    if (writeCount == (sercom4I2CObj.writeSize))
                    {
                        if(sercom4I2CObj.readSize != 0U)
                        {

                            /* Write 7bit address with direction (ADDR.ADDR[0]) equal to 1*/
                            SERCOM4_REGS->I2CM.SERCOM_ADDR =  ((uint32_t)(sercom4I2CObj.address) << 1U) | (uint32_t)I2C_TRANSFER_READ;

                            /* Wait for synchronization */
                            while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
                            {
                                /* Do nothing */
                            }

                            sercom4I2CObj.state = SERCOM_I2C_STATE_TRANSFER_READ;

                        }
                        else
                        {
                            SERCOM4_REGS->I2CM.SERCOM_CTRLB |= SERCOM_I2CM_CTRLB_CMD(3UL);

                            /* Wait for synchronization */
                            while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
                            {
                                /* Do nothing */
                            }


                            sercom4I2CObj.state = SERCOM_I2C_STATE_TRANSFER_DONE;
                        }
                    }
                    /* Write next byte */
                    else
                    {
                        SERCOM4_REGS->I2CM.SERCOM_DATA = sercom4I2CObj.writeBuffer[writeCount];
                        writeCount++;
                        /* Wait for synchronization */
                            while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
                            {
                                /* Do nothing */
                            }
                        sercom4I2CObj.writeCount = writeCount;
                    }
                }

                    break;

                case SERCOM_I2C_STATE_TRANSFER_READ:
                {
                    size_t readCount = sercom4I2CObj.readCount;


                    if(readCount == (sercom4I2CObj.readSize - 1U))
                    {
                        /* Set NACK and send stop condition to the slave from master */
                        SERCOM4_REGS->I2CM.SERCOM_CTRLB |= SERCOM_I2CM_CTRLB_ACKACT_Msk | SERCOM_I2CM_CTRLB_CMD(3UL);

                        /* Wait for synchronization */
                        while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
                        {
                            /* Do nothing */
                        }

                        sercom4I2CObj.state = SERCOM_I2C_STATE_TRANSFER_DONE;
                    }

                    /* Wait for synchronization */
                        while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
                        {
                            /* Do nothing */
                        }

                    /* Read the received data */
                    sercom4I2CObj.readBuffer[readCount] = (uint8_t) SERCOM4_REGS->I2CM.SERCOM_DATA;
                    readCount++;

                    sercom4I2CObj.readCount = readCount;
                }

                    break;

                default:

                    /* Do nothing */
                    break;
            }
        }

        /* Error Status */
        if(sercom4I2CObj.state == SERCOM_I2C_STATE_ERROR)
        {
            /* Reset the PLib objects and Interrupts */
            sercom4I2CObj.state = SERCOM_I2C_STATE_IDLE;

            /* Generate STOP condition */
            SERCOM4_REGS->I2CM.SERCOM_CTRLB |= SERCOM_I2CM_CTRLB_CMD(3UL);

            /* Wait for synchronization */
            while((SERCOM4_REGS->I2CM.SERCOM_SYNCBUSY) != 0U)
            {
                /* Do nothing */
            }


            SERCOM4_REGS->I2CM.SERCOM_INTFLAG = (uint8_t)SERCOM_I2CM_INTFLAG_Msk;

            if (sercom4I2CObj.callback != NULL)
            {
                sercom4I2CObj.callback(context);
            }
        }
        /* Transfer Complete */
        else if(sercom4I2CObj.state == SERCOM_I2C_STATE_TRANSFER_DONE)
        {
            /* Reset the PLib objects and interrupts */
            sercom4I2CObj.state = SERCOM_I2C_STATE_IDLE;
            sercom4I2CObj.error = SERCOM_I2C_ERROR_NONE;

            SERCOM4_REGS->I2CM.SERCOM_INTFLAG = (uint8_t)SERCOM_I2CM_INTFLAG_Msk;

            /* Wait for the NAK and STOP bit to be transmitted out and I2C state machine to rest in IDLE state */
            while((SERCOM4_REGS->I2CM.SERCOM_STATUS & SERCOM_I2CM_STATUS_BUSSTATE_Msk) != SERCOM_I2CM_STATUS_BUSSTATE(0x01U))
            {
                /* Do nothing */
            }

            if(sercom4I2CObj.callback != NULL)
            {
                sercom4I2CObj.callback(context);
            }

        }
        else
        {
            /* Do nothing */
        }
    }

    return;
}