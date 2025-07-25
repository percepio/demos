/*
 * Trace Recorder for Tracealyzer v989.878.767
 * Copyright 2025 Percepio AB
 * www.percepio.com
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Some common defines for the trace recorder.
 */

#ifndef TRC_DEFINES_H
#define TRC_DEFINES_H

#define TRC_SUCCESS ((traceResult)0)
#define TRC_FAIL ((traceResult)1)

#define TRC_FREE_RUNNING_32BIT_INCR 1
#define TRC_FREE_RUNNING_32BIT_DECR 2
#define TRC_OS_TIMER_INCR 3
#define TRC_OS_TIMER_DECR 4
#define TRC_CUSTOM_TIMER_INCR 5
#define TRC_CUSTOM_TIMER_DECR 6

#define TRC_STATE_IN_STARTUP 0
#define TRC_STATE_IN_TASKSWITCH 1
#define TRC_STATE_IN_APPLICATION 2

/* Start options for vTraceEnable. */
#define TRC_START_FROM_HOST		0UL
#define TRC_START				1UL
#define TRC_START_AWAIT_HOST	2UL

#define TRC_ACKNOWLEDGED (0xABC99123)

/* Command codes for TzCtrl task */
#define CMD_SET_ACTIVE      1 /* Start (param1 = 1) or Stop (param1 = 0) */

/* The final command code, used to validate commands. */
#define CMD_LAST_COMMAND 1

#define TRC_RECORDER_BUFFER_ALLOCATION_STATIC   (0x00UL)
#define TRC_RECORDER_BUFFER_ALLOCATION_DYNAMIC  (0x01UL)
#define TRC_RECORDER_BUFFER_ALLOCATION_CUSTOM   (0x02UL)

#define TRC_OPTION_BIT_SHIFT_IRQ_ORDER 0
#define TRC_OPTION_BIT_SHIFT_BASE_SIZE 8

/******************************************************************************/
/*** ERROR AND WARNING CODES (check using xTraceErrorGetLast) *****************/
/******************************************************************************/

#define TRC_ERROR_NONE								0x00UL

#define TRC_ERROR_ASSERT							0x01UL
#define TRC_ERROR_EVENT_CODE_TOO_LARGE				0x02UL
#define TRC_ERROR_ISR_NESTING_OVERFLOW				0x03UL
#define TRC_ERROR_DWT_NOT_SUPPORTED					0x04UL
#define TRC_ERROR_DWT_CYCCNT_NOT_SUPPORTED			0x05UL
#define TRC_ERROR_TZCTRLTASK_NOT_CREATED			0x06UL
#define TRC_ERROR_STREAM_PORT_WRITE					0x07UL

#define TRC_WARNING_ENTRY_TABLE_SLOTS				0x08UL
#define TRC_WARNING_ENTRY_SYMBOL_MAX_LENGTH			0x09UL
#define TRC_WARNING_EVENT_SIZE_TRUNCATED			0x0AUL
#define TRC_WARNING_STREAM_PORT_READ				0x0BUL
#define TRC_WARNING_STREAM_PORT_WRITE				0x0CUL
#define TRC_WARNING_STREAM_PORT_INITIAL_BLOCKING	0x0DUL
#define TRC_WARNING_STACKMON_NO_SLOTS				0x0EUL

/* Entry Option definitions */
#define TRC_ENTRY_OPTION_EXCLUDED				0x00000001UL
#define TRC_ENTRY_OPTION_HEAP					0x80000000UL
#define TRC_ENTRY_OPTION_EXTENSION				0x40000000UL
#define TRC_ENTRY_OPTION_STATE_MACHINE			0x20000000UL
#define TRC_ENTRY_OPTION_STATE_MACHINE_STATE	0x10000000UL
#define TRC_ENTRY_OPTION_INTERVAL_CHANNEL		0x08000000UL
#define TRC_ENTRY_OPTION_COUNTER				0x04000000UL
#define TRC_ENTRY_OPTION_INTERVAL_CHANNEL_SET	0x02000000UL
#define TRC_ENTRY_OPTION_IDLE_NAME				0x01000000UL
#define TRC_ENTRY_OPTION_RUNNABLE				0x00800000UL
#define TRC_ENTRY_OPTION_DEPENDENCY				0x00400000UL

#define TRC_DEPENDENCY_TYPE_ELF					0x00000001UL

#define TRC_RECORDER_COMPONENT_CORE						0x00000001UL
#define TRC_RECORDER_COMPONENT_ASSERT					0x00000002UL
#define TRC_RECORDER_COMPONENT_BLOB						0x00000004UL
#define TRC_RECORDER_COMPONENT_DIAGNOSTICS				0x00000008UL
#define TRC_RECORDER_COMPONENT_ENTRY					0x00000010UL
#define TRC_RECORDER_COMPONENT_ERROR					0x00000020UL
#define TRC_RECORDER_COMPONENT_EVENT					0x00000040UL
#define TRC_RECORDER_COMPONENT_EVENT_BUFFER				0x00000080UL
#define TRC_RECORDER_COMPONENT_EXTENSION				0x00000100UL
#define TRC_RECORDER_COMPONENT_HEAP						0x00000200UL
#define TRC_RECORDER_COMPONENT_INTERNAL_EVENT_BUFFER	0x00000400UL
#define TRC_RECORDER_COMPONENT_INTERVAL					0x00000800UL
#define TRC_RECORDER_COMPONENT_ISR						0x00001000UL
#define TRC_RECORDER_COMPONENT_MULTI_CORE_EVENT_BUFFER	0x00002000UL
#define TRC_RECORDER_COMPONENT_OBJECT					0x00004000UL
#define TRC_RECORDER_COMPONENT_PRINT					0x00008000UL
#define TRC_RECORDER_COMPONENT_STACK_MONITOR			0x00010000UL
#define TRC_RECORDER_COMPONENT_STATE_MACHINE			0x00020000UL
#define TRC_RECORDER_COMPONENT_STATIC_BUFFER			0x00040000UL
#define TRC_RECORDER_COMPONENT_STRING					0x00080000UL
#define TRC_RECORDER_COMPONENT_TASK						0x00100000UL
#define TRC_RECORDER_COMPONENT_TIMESTAMP				0x00200000UL
#define TRC_RECORDER_COMPONENT_COUNTER					0x00400000UL
#define TRC_RECORDER_COMPONENT_TASK_MONITOR				0x00800000UL

/**
 *
 */
#define TRC_INTERNAL_EVENT_BUFFER_OPTION_WRITE_MODE_COPY		(0U)
#define TRC_INTERNAL_EVENT_BUFFER_OPTION_WRITE_MODE_DIRECT		(1U)

/**
 *
 */
#define TRC_INTERNAL_EVENT_BUFFER_OPTION_TRANSFER_MODE_ALL		(0U)
#define TRC_INTERNAL_EVENT_BUFFER_OPTION_TRANSFER_MODE_CHUNKED	(1U)

/******************************************************************************
 * Supported ports
 *
 * TRC_HARDWARE_PORT_HWIndependent
 * A hardware independent fallback option for event timestamping. Provides low
 * resolution timestamps based on the OS tick.
 * This may be used on the Win32 port, but may also be used on embedded hardware
 * platforms. All time durations will be truncated to the OS tick frequency,
 * typically 1 KHz. This means that a task or ISR that executes in less than
 * 1 ms get an execution time of zero.
 *
 * TRC_HARDWARE_PORT_APPLICATION_DEFINED
 * Allows for defining the port macros in other source code files.
 *
 * TRC_HARDWARE_PORT_Win32
 * "Accurate" timestamping based on the Windows performance counter for Win32
 * builds. Note that this gives the host machine time, not the kernel time.
 *
 * Hardware specific ports
 * To get accurate timestamping, a hardware timer is necessary. Below are the
 * available ports. Some of these are "unofficial", meaning that
 * they have not yet been verified by Percepio but have been contributed by
 * external developers. They should work, otherwise let us know by emailing
 * support@percepio.com. Some work on any OS platform, while other are specific
 * to a certain operating system.
 *****************************************************************************/

/****** Port Name ************************************* Code ** Official ** OS Platform *********/
#define TRC_HARDWARE_PORT_APPLICATION_DEFINED			98	/*	-			-					*/
#define TRC_HARDWARE_PORT_NOT_SET				99	/*	-			-					*/
#define TRC_HARDWARE_PORT_HWIndependent				0	/*	DEPRECATED							*/
#define TRC_HARDWARE_PORT_Win32					1	/*	Yes			FreeRTOS on Win32                       */
#define TRC_HARDWARE_PORT_Atmel_AT91SAM7		        2	/*	No			Any					*/
#define TRC_HARDWARE_PORT_Atmel_UC3A0				3	/*	No			Any					*/
#define TRC_HARDWARE_PORT_ARM_Cortex_M				4	/*	Yes			Any					*/
#define TRC_HARDWARE_PORT_Renesas_RX600				6	/*	Yes			Any					*/
#define TRC_HARDWARE_PORT_MICROCHIP_PIC24_PIC32			7	/*	Yes			Any					*/
#define TRC_HARDWARE_PORT_TEXAS_INSTRUMENTS_TMS570_RM48	        8       /*	Yes			Any					*/
#define TRC_HARDWARE_PORT_TEXAS_INSTRUMENTS_MSP430		9	/*	No			Any					*/
#define TRC_HARDWARE_PORT_XILINX_PPC405				11	/*	No			FreeRTOS                                */
#define TRC_HARDWARE_PORT_XILINX_PPC440				12	/*	No			FreeRTOS                                */
#define TRC_HARDWARE_PORT_XILINX_MICROBLAZE			13      /*	No			Any					*/
#define TRC_HARDWARE_PORT_XILINX_ZyncUltraScaleR5		14      /*      No			FreeRTOS                                */
#define TRC_HARDWARE_PORT_NXP_LPC210X				15      /*	No			Any					*/
#define TRC_HARDWARE_PORT_ARM_CORTEX_A9				16      /*	Yes			Any					*/
#define TRC_HARDWARE_PORT_POWERPC_Z4                            17      /*      No                      FreeRTOS                                */
#define TRC_HARDWARE_PORT_Altera_NiosII				18      /*      Yes                     Any (Tested with FreeRTOS)              */
#define TRC_HARDWARE_PORT_ZEPHYR                                19      /*      Yes                     Zephyr                                  */
#define TRC_HARDWARE_PORT_XTensa_LX6                            20      /*      Yes                     ESP-IDF FreeRTOS                        */
#define TRC_HARDWARE_PORT_XTensa_LX7                            21      /*      Yes                     ESP-IDF FreeRTOS                        */
#define TRC_HARDWARE_PORT_Win64				        22      /*	Yes			FreeRTOS on Win64	                */
#define TRC_HARDWARE_PORT_XMOS_XCOREAI                          23      /*      Yes                     FreeRTOS SMP                            */
#define TRC_HARDWARE_PORT_RISCV_RV32I			        24      /*	Yes			FreeRTOS			        */
#define TRC_HARDWARE_PORT_CYCLONE_V_HPS			        25      /*	Yes			FreeRTOS			        */
#define TRC_HARDWARE_PORT_ARM_Cortex_M_NRF_SD                   26      /*      Yes                     FreeRTOS                                */
#define TRC_HARDWARE_PORT_ARMv8AR_A32				27	/*	Yes			Any					*/
#define TRC_HARDWARE_PORT_ADSP_SC5XX_SHARC			28	/*	No			FreeRTOS                                */

#endif /* TRC_PORTDEFINES_H */
