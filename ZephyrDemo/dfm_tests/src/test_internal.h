#ifndef DFM_TEST_INTERNAL_H
#define DFM_TEST_INTERNAL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <trcRecorder.h>

#ifndef DFM_TEST_VARIANT_ID
#error "DFM_TEST_VARIANT_ID must be provided by dfm_tests/CMakeLists.txt"
#endif

#ifndef DFM_TEST_VARIANT_NAME
#error "DFM_TEST_VARIANT_NAME must be provided by dfm_tests/CMakeLists.txt"
#endif

#ifndef DFM_TEST_CASE_ID
#error "DFM_TEST_CASE_ID must be provided by dfm_tests/CMakeLists.txt"
#endif

#define DFM_TEST_NOINLINE __attribute__((noinline))
#define DFM_TEST_USED __attribute__((used))

enum dfm_test_phase {
	DFM_TEST_PHASE_READY = 1,
	DFM_TEST_PHASE_RUNNING,
	DFM_TEST_PHASE_STARTUP_ARMED,
	DFM_TEST_PHASE_STARTUP_RUNNING,
	DFM_TEST_PHASE_STARTUP_DONE,
	DFM_TEST_PHASE_EXPECT_DFM_REBOOT,
	DFM_TEST_PHASE_UNEXPECTED_FATAL,
	DFM_TEST_PHASE_EXPECT_FAULT_REBOOT,
	DFM_TEST_PHASE_COMPLETE,
};

struct dfm_test_state_snapshot {
	uint32_t run_id;
	uint32_t next_index;
	uint32_t armed_test;
	uint32_t phase;
	uint32_t reboot_count;
	uint32_t observation_a;
	uint32_t observation_b;
};

typedef int (*dfm_test_function_t)(const char *test_id);

enum dfm_test_kind {
	DFM_TEST_KIND_RUNTIME,
	DFM_TEST_KIND_STARTUP,
	DFM_TEST_KIND_DFM_REBOOT,
	DFM_TEST_KIND_FAULT_REBOOT,
};

struct dfm_test_case {
	const char *id;
	uint32_t numeric_id;
	enum dfm_test_kind kind;
	dfm_test_function_t function;
};

bool dfm_test_state_load(struct dfm_test_state_snapshot *snapshot);
void dfm_test_state_initialize(uint32_t run_id);
void dfm_test_state_commit(const struct dfm_test_state_snapshot *snapshot);
void dfm_test_state_mark_startup_running(uint32_t numeric_id);
void dfm_test_state_mark_startup_done(uint32_t numeric_id,
	uint32_t observation_a, uint32_t observation_b);
TraceStringHandle_t dfm_test_trace_channel(void);

int dfm_test_run_reference(const char *test_id);
int dfm_test_run_t02(const char *test_id);
int dfm_test_run_t03(const char *test_id);
int dfm_test_run_t04(const char *test_id);
int dfm_test_run_t07(const char *test_id);
int dfm_test_run_t11(const char *test_id);
int dfm_test_run_t12(const char *test_id);

int dfm_test_run_t06(const char *test_id);
int dfm_test_run_t08(const char *test_id);
int dfm_test_run_t09(const char *test_id);
int dfm_test_run_t15(const char *test_id);
int dfm_test_run_t16(const char *test_id);
int dfm_test_run_t21(const char *test_id);

int dfm_test_run_t17(const char *test_id);
int dfm_test_run_t18(const char *test_id);
int dfm_test_run_t19(const char *test_id);
int dfm_test_run_t20(const char *test_id);
int dfm_test_run_t22(const char *test_id);
int dfm_test_run_t23(const char *test_id);
int dfm_test_run_t25(const char *test_id);
int dfm_test_run_t26(const char *test_id);
int dfm_test_run_t27(const char *test_id);

void dfm_test_t16_run_on_msp(uint32_t *msp_top, uint32_t *msp_limit);
void dfm_test_t16_trap_site(void);

static inline void dfm_test_check(const char *test_id, bool passed,
	const char *condition)
{
	printk("DFMT:CHECK:%s:%s:%s\n", test_id,
		passed ? "PASS" : "FAIL", condition);
}

#endif /* DFM_TEST_INTERNAL_H */
