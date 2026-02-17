/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#include "osal.h"

/* Not sure which are needed */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Important */
#ifndef LNBR
#define LNBR "\n"
#endif

#define DEMO_PRINTF(fmt, ...)                     \
  do {                                                \
    xTraceConsoleChannelPrintF((fmt), ##__VA_ARGS__); \
	printk((fmt), ##__VA_ARGS__);                     \
  } while (0)

#endif /* __MAIN_H */
