#ifndef CMSIS_COMPAT_H
#define CMSIS_COMPAT_H

/* --------------------------------------------------------------------
 * Compatibility stubs for older CMSIS versions that lack
 * PSPLIM / MSPLIM register access functions.
 *
 * These are inert: they compile on cores without the registers
 * and do nothing / return 0.
 * ------------------------------------------------------------------ */

#ifndef __set_PSPLIM
#define __set_PSPLIM(x)  ((void)(x))
#endif

#ifndef __get_PSPLIM
#define __get_PSPLIM()   (0U)
#endif

#ifndef __set_MSPLIM
#define __set_MSPLIM(x)  ((void)(x))
#endif

#ifndef __get_MSPLIM
#define __get_MSPLIM()   (0U)
#endif

#endif /* CMSIS_COMPAT_H */

