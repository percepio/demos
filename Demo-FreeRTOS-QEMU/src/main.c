#include <stdio.h>

#include "FreeRTOS.h"
#include "demo_app.h"
#include "platform.h"
#include "trcRecorder.h"

int main(void)
{
    platform_initialize();
    stdio_uart_init();
    /* Avoid libc buffering: UART output must survive deliberate crashes. */
    (void)setvbuf(stdout, NULL, _IONBF, 0);

    (void)printf("Booting Percepio FreeRTOS demo\n");

    /* xTraceInitialize() is idempotent. Initialize before DEMO_PRINTF first
     * uses TraceRecorder; demo_app() intentionally calls it again. */
    (void)xTraceInitialize();

    demo_app();

    for (;;) {
        __asm volatile("wfi");
    }
}
