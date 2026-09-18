#include <stdio.h>

#include "FreeRTOS.h"
#include "demo_app.h"
#include "platform.h"
#include "trcRecorder.h"

#ifndef RUN_TESTS_ONLY
#define RUN_TESTS_ONLY 0
#endif

#if RUN_TESTS_ONLY
#include "dfm_tests.h"
#endif

int main(void)
{
    platform_initialize();
    stdio_uart_init();

#if RUN_TESTS_ONLY
    return run_tests();
#else
    (void)printf("Booting Percepio FreeRTOS demo\n");

    /* xTraceInitialize() is idempotent. Initialize before DEMO_PRINTF first
     * uses TraceRecorder; demo_app() intentionally calls it again. */
    (void)xTraceInitialize();

    demo_app();

    for (;;) {
        __asm volatile("wfi");
    }
#endif
}
