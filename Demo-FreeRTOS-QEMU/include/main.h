#ifndef DEMO_MAIN_H
#define DEMO_MAIN_H

#include <stdio.h>
#include "trcRecorder.h"

#ifndef LNBR
#define LNBR "\n"
#endif

#define DEMO_PRINTF(format_, ...)                                      \
    do {                                                               \
        (void)xTraceConsoleChannelPrintF((format_), ##__VA_ARGS__);     \
        (void)printf((format_), ##__VA_ARGS__);                         \
        (void)printf(LNBR);                                             \
        (void)fflush(stdout);                                           \
    } while (0)

#endif /* DEMO_MAIN_H */
