#include <stdint.h>
#include <stdio.h>

#include "stm32u5xx_hal.h"

#define DEMO_UART_BAUD_RATE 921600U

static UART_HandleTypeDef console_uart;

void HAL_UART_MspInit(UART_HandleTypeDef *uart)
{
    GPIO_InitTypeDef gpio = {0};
    RCC_PeriphCLKInitTypeDef clock = {0};

    if (uart->Instance != USART1) {
        return;
    }

    clock.PeriphClockSelection = RCC_PERIPHCLK_USART1;
    clock.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
    (void)HAL_RCCEx_PeriphCLKConfig(&clock);
    __HAL_RCC_USART1_CLK_ENABLE();
    __HAL_RCC_GPIOA_CLK_ENABLE();

    gpio.Pin = GPIO_PIN_9 | GPIO_PIN_10;
    gpio.Mode = GPIO_MODE_AF_PP;
    gpio.Pull = GPIO_NOPULL;
    gpio.Speed = GPIO_SPEED_FREQ_HIGH;
    gpio.Alternate = GPIO_AF7_USART1;
    HAL_GPIO_Init(GPIOA, &gpio);
}

void stdio_uart_init(void)
{
    console_uart.Instance = USART1;
    console_uart.Init.BaudRate = DEMO_UART_BAUD_RATE;
    console_uart.Init.WordLength = UART_WORDLENGTH_8B;
    console_uart.Init.StopBits = UART_STOPBITS_1;
    console_uart.Init.Parity = UART_PARITY_NONE;
    console_uart.Init.Mode = UART_MODE_TX_RX;
    console_uart.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    console_uart.Init.OverSampling = UART_OVERSAMPLING_16;
    console_uart.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
    console_uart.Init.ClockPrescaler = UART_PRESCALER_DIV1;
    console_uart.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;

    if ((HAL_UART_Init(&console_uart) != HAL_OK) ||
        (HAL_UARTEx_DisableFifoMode(&console_uart) != HAL_OK)) {
        for (;;) { }
    }
}

static void uart_put_character(char character)
{
    uint8_t byte = (uint8_t)character;
    (void)HAL_UART_Transmit(&console_uart, &byte, 1U, HAL_MAX_DELAY);
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
