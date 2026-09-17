/*
 * Percepio DFM v2.1.0
 * Copyright 2023 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * DFM serial port Cloud port
 */

#include <stddef.h>
#include <dfmCloudPort.h>
#include <dfmCloudPortConfig.h>
#include <dfm.h>
#include <string.h>
#include <stdio.h>

#if (defined(DFM_CFG_ENABLED) && ((DFM_CFG_ENABLED) >= 1))

/* Prototype for the print function */
extern void vMainUARTPrintString( char * pcString );

static DfmCloudPortData_t *pxCloudPortData = (void*)0;

static uint16_t prvCrc16Ccitt(uint16_t seed, const uint8_t* data, uint32_t size);
static uint16_t prvPrintDataAsHex(uint16_t seed, uint8_t* data, int size);
static DfmResult_t prvSerialPortUploadEntry(DfmEntryHandle_t xEntryHandle);

static uint16_t prvCrc16Ccitt(uint16_t seed, const uint8_t* data, uint32_t size)
{
	uint16_t crc = seed;
	uint32_t i;

	for (i = 0U; i < size; i++)
	{
		/* This is Zephyr's software crc16_ccitt() formulation. */
		uint16_t e = (uint16_t)((crc ^ data[i]) & UINT16_C(0x00FF));
		uint16_t f = (uint16_t)((e ^ (uint16_t)(e << 4)) & UINT16_C(0x00FF));

		crc = (uint16_t)((crc >> 8) ^ (uint16_t)(f << 8) ^
			(uint16_t)(f << 3) ^ (f >> 4));
	}

	return crc;
}

static uint16_t prvPrintDataAsHex(uint16_t seed, uint8_t* data, int size)
{
	uint16_t checksum = prvCrc16Ccitt(seed, data, (uint32_t)size);
	int i;
	char buf[10];

    for (i = 0; i < size; i++)
    {
    	uint8_t byte = data[i];
        snprintf(buf, sizeof(buf), " %02X", (unsigned int)byte);

        if (i % 20 == 0)
        {
            DFM_CFG_LOCK_SERIAL();
            DFM_PRINT_ALERT_DATA(("[[ DATA:"));
        }

        DFM_PRINT_ALERT_DATA(buf);

        if ( (i+1) % 20 == 0)
        {
            DFM_PRINT_ALERT_DATA((" ]]" LNBR));
            DFM_CFG_UNLOCK_SERIAL();            
        }
    }

    if (i % 20 != 0)
    {
        DFM_PRINT_ALERT_DATA((" ]]" LNBR));
        DFM_CFG_UNLOCK_SERIAL();
    }

    return checksum;
}

static DfmResult_t prvSerialPortUploadEntry(DfmEntryHandle_t xEntryHandle)
{
	uint16_t checksum;
	uint32_t datalen;

	if (pxCloudPortData == (void*)0)
	{
		return DFM_FAIL;
	}

	if (xEntryHandle == 0)
	{
		return DFM_FAIL;
	}

	if (xDfmEntryGetSize(xEntryHandle, &datalen) == DFM_FAIL)
	{
		return DFM_FAIL;
	}

	if (datalen > 0xFFFF)
	{
		return DFM_FAIL;
	}

	DFM_CFG_LOCK_SERIAL();
	DFM_PRINT_ALERT_DATA(LNBR "[[ DevAlert Data Begins ]]" LNBR);
	DFM_CFG_UNLOCK_SERIAL();

	checksum = prvPrintDataAsHex(0U, (uint8_t*)xEntryHandle, (int)datalen);

	snprintf(pxCloudPortData->buf, sizeof(pxCloudPortData->buf),
		"[[ DevAlert Data Ended. Checksum: %d ]]" LNBR,
		(unsigned int)checksum);

	DFM_CFG_LOCK_SERIAL();
	DFM_PRINT_ALERT_DATA(pxCloudPortData->buf);
	DFM_CFG_UNLOCK_SERIAL();
                
	return DFM_SUCCESS;
}

DfmResult_t xDfmCloudPortInitialize(DfmCloudPortData_t* pxBuffer)
{
	pxCloudPortData = pxBuffer;

	return DFM_SUCCESS;
}

DfmResult_t xDfmCloudPortSendAlert(DfmEntryHandle_t xEntryHandle)
{
	return prvSerialPortUploadEntry(xEntryHandle);
}

DfmResult_t xDfmCloudPortSendPayloadChunk(DfmEntryHandle_t xEntryHandle)
{
	return prvSerialPortUploadEntry(xEntryHandle);
}

#endif
