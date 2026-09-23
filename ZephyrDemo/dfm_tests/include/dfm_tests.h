#ifndef DFM_TESTS_H
#define DFM_TESTS_H

#include <stdint.h>

/* Run all tests compatible with the selected firmware variant. */
int run_tests(void);

/* Apply retained-memory test setup that must happen before main() checks it. */
uint32_t dfm_tests_prepare_retained_boot(void);

/* Preserve unexpected-fatal evidence before the common handler reboots. */
void dfm_tests_record_fatal(unsigned int reason);

#endif /* DFM_TESTS_H */
