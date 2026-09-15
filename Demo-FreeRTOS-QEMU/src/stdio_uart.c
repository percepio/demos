/* UART retargeting adapted from FreeRTOS CORTEX_MPS2_QEMU_IAR_GCC.
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.
 * SPDX-License-Identifier: MIT
 */

#include <stdint.h>
#include <stdio.h>

#define UART0_ADDRESS  0x40004000UL
#define UART0_DATA     (*(volatile uint32_t *)(UART0_ADDRESS + 0UL))
#define UART0_STATE    (*(volatile uint32_t *)(UART0_ADDRESS + 4UL))
#define UART0_CTRL     (*(volatile uint32_t *)(UART0_ADDRESS + 8UL))
#define UART0_BAUDDIV  (*(volatile uint32_t *)(UART0_ADDRESS + 16UL))
#define UART_TX_FULL   1UL

static void uart_put_character(char character)
{
    while ((UART0_STATE & UART_TX_FULL) != 0U) { }
    UART0_DATA = (uint32_t)(uint8_t)character;
}

void stdio_uart_init(void)
{
    UART0_BAUDDIV = 16U;
    UART0_CTRL = 1U;
}

void vMainUARTPrintString(char *string)
{
    if (string != NULL) {
        while (*string != '\0') {
            uart_put_character(*string++);
        }
    }
}

#ifdef __PICOLIBC__
static int uart_putchar(char character, FILE *file)
{
    (void)file;
    uart_put_character(character);
    return (unsigned char)character;
}

static FILE uart_stdout =
    FDEV_SETUP_STREAM(uart_putchar, NULL, NULL, _FDEV_SETUP_WRITE);
__attribute__((used)) FILE *const stdout = &uart_stdout;
#else
int __write(int file, char *string, int length)
{
    int index;
    (void)file;

    for (index = 0; index < length; ++index) {
        uart_put_character(string[index]);
    }
    return length;
}
#endif
