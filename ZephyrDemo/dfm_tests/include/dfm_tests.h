#ifndef DFM_TESTS_H
#define DFM_TESTS_H

/* Run all tests compatible with the selected firmware variant. */
int run_tests(void);

/* Preserve unexpected-fatal evidence before the common handler reboots. */
void dfm_tests_record_fatal(unsigned int reason);

#endif /* DFM_TESTS_H */
