#ifndef DEMO_PLATFORM_H
#define DEMO_PLATFORM_H

#include <stdint.h>

void platform_initialize(void);
void stdio_uart_init(void);

void platform_trace_timer_initialize(void);
uint32_t platform_trace_timer_count(void);

#endif /* DEMO_PLATFORM_H */
