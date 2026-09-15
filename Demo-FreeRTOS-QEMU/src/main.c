#include <stdio.h>

#include "FreeRTOS.h"
#include "demo_app.h"
#include "platform_mps2.h"
#include "trcRecorder.h"

int main(void)
{
    platform_initialize();
    stdio_uart_init();

    (void)printf("Booting Percepio FreeRTOS demo on QEMU mps2-an385\n");

    /* xTraceInitialize() is idempotent. Initialize before DEMO_PRINTF first
     * uses TraceRecorder; demo_app() intentionally calls it again. */
    (void)xTraceInitialize();

    demo_app();

    for (;;) {
        __asm volatile("wfi");
    }
}
