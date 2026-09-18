#include "dfm_tests.h"
#include "test_internal.h"

#include <dfm.h>
#include <trcRecorder.h>

#include <cmsis_core.h>
#include <zephyr/sys/reboot.h>

#define DFM_TEST_INTER_CASE_DELAY_MS 300

static TraceStringHandle_t test_trace_channel;

#if DFM_TEST_VARIANT_ID == 1
static const struct dfm_test_case test_registry[] = {
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1001
	{ "1001", 1001U, DFM_TEST_KIND_RUNTIME, dfm_test_run_reference },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1003
	{ "1003", 1003U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t03 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1012
	{ "1012", 1012U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t12 },
#endif
};
#elif DFM_TEST_VARIANT_ID == 2
static const struct dfm_test_case test_registry[] = {
	{ "1013", 1013U, DFM_TEST_KIND_RUNTIME, dfm_test_run_reference },
};
#elif DFM_TEST_VARIANT_ID == 3
static const struct dfm_test_case test_registry[] = {
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1002
	{ "1002", 1002U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t02 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1004
	{ "1004", 1004U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t04 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1005
	{ "1005", 1005U, DFM_TEST_KIND_STARTUP, NULL },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1006
	{ "1006", 1006U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t06 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1007
	{ "1007", 1007U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t07 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1008
	{ "1008", 1008U, DFM_TEST_KIND_DFM_REBOOT, dfm_test_run_t08 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1009
	{ "1009", 1009U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t09 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1011
	{ "1011", 1011U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t11 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1014
	{ "1014", 1014U, DFM_TEST_KIND_RUNTIME, dfm_test_run_reference },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1016
	{ "1016", 1016U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t16 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1017
	{ "1017", 1017U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t17 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1018
	{ "1018", 1018U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t18 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1019
	{ "1019", 1019U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t19 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1021
	{ "1021", 1021U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t21 },
#endif
	/* Keep the pre-initialization robustness test last so a future regression
	 * cannot hide the evidence from the ordinary -Os cases.
	 */
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1010
	{ "1010", 1010U, DFM_TEST_KIND_STARTUP, NULL },
#endif
};
#elif DFM_TEST_VARIANT_ID == 4
static const struct dfm_test_case test_registry[] = {
	{ "1015", 1015U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t15 },
};
#elif DFM_TEST_VARIANT_ID == 5
static const struct dfm_test_case test_registry[] = {
	{ "1020", 1020U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t20 },
};
#elif DFM_TEST_VARIANT_ID == 6
static const struct dfm_test_case test_registry[] = {
	{ "1024", 1024U, DFM_TEST_KIND_RUNTIME, dfm_test_run_reference },
};
#elif DFM_TEST_VARIANT_ID == 7
static const struct dfm_test_case test_registry[] = {
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1022
	{ "1022", 1022U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t22 },
#endif
#if DFM_TEST_CASE_ID == 0 || DFM_TEST_CASE_ID == 1023
	{ "1023", 1023U, DFM_TEST_KIND_RUNTIME, dfm_test_run_t23 },
#endif
};
#else
#error "Unsupported DFM test variant"
#endif

#define DFM_TEST_CASE_COUNT ARRAY_SIZE(test_registry)

static uint32_t new_run_id(void)
{
	uint32_t run_id = k_cycle_get_32();

	return run_id != 0U ? run_id : 1U;
}

static void prepare_trace_recorder(void)
{
	if (!xTraceIsRecorderInitialized()) {
		traceResult result = xTraceInitialize();

		dfm_test_check("HARNESS", result == TRC_SUCCESS,
			"TRACE_INITIALIZED");
	}

	if (!xTraceIsRecorderEnabled()) {
		traceResult result = xTraceEnable(TRC_START);

		dfm_test_check("HARNESS", result == TRC_SUCCESS,
			"TRACE_STARTED");
	}

	{
		traceResult result = xTraceStringRegister("DFM Tests",
			&test_trace_channel);

		dfm_test_check("HARNESS", result == TRC_SUCCESS,
			"TRACE_CHANNEL_REGISTERED");
	}
}

TraceStringHandle_t dfm_test_trace_channel(void)
{
	return test_trace_channel;
}

static void advance_after_interrupted_case(struct dfm_test_state_snapshot *state)
{
	const char *test_id = "UNKNOWN";
	uint32_t previous_phase = state->observation_b;

	if (state->next_index < DFM_TEST_CASE_COUNT) {
		test_id = test_registry[state->next_index].id;
	}

	printk("DFMT:HARNESS_FAIL:%s:INTERRUPTED:phase=%u:reason=%u\n",
		test_id, previous_phase, state->observation_a);

	/* EXPECT_DFM_REBOOT already points at the following case. */
	if ((previous_phase != DFM_TEST_PHASE_EXPECT_DFM_REBOOT) &&
	    (state->next_index < DFM_TEST_CASE_COUNT)) {
		state->next_index++;
	}

	state->armed_test = 0U;
	state->phase = DFM_TEST_PHASE_READY;
	state->observation_a = 0U;
	state->observation_b = 0U;
	dfm_test_state_commit(state);
}

static void recover_previous_boot(struct dfm_test_state_snapshot *state)
{
	const char *next_id = state->next_index < DFM_TEST_CASE_COUNT ?
		test_registry[state->next_index].id : "END";

	switch (state->phase) {
	case DFM_TEST_PHASE_EXPECT_DFM_REBOOT:
		printk("DFMT:RESUMED:%u:%s\n", state->armed_test,
			next_id);
		state->armed_test = 0U;
		state->phase = DFM_TEST_PHASE_READY;
		dfm_test_state_commit(state);
		break;

	case DFM_TEST_PHASE_STARTUP_DONE:
		if ((state->next_index < DFM_TEST_CASE_COUNT) &&
		    (test_registry[state->next_index].numeric_id == state->armed_test)) {
			const struct dfm_test_case *test = &test_registry[state->next_index];
			uint32_t completed_id = state->armed_test;

			printk("DFMT:RETURNED:%s:startup:ipsr=%u:control=0x%x\n",
				test->id, state->observation_a, state->observation_b);
			dfm_test_check(test->id, state->observation_a == 0U,
				"THREAD_MODE");
			dfm_test_check(test->id,
				(state->observation_b & CONTROL_SPSEL_Msk) != 0U,
				"PSP_SELECTED");
			state->next_index++;
			next_id = state->next_index < DFM_TEST_CASE_COUNT ?
				test_registry[state->next_index].id : "END";
			printk("DFMT:RESUMED:%u:%s\n", completed_id,
				next_id);
		}
		state->armed_test = 0U;
		state->phase = DFM_TEST_PHASE_READY;
		state->observation_a = 0U;
		state->observation_b = 0U;
		dfm_test_state_commit(state);
		break;

	case DFM_TEST_PHASE_STARTUP_RUNNING:
		/* The startup trap did not return before an unexpected reset. */
		state->observation_a = UINT32_MAX;
		state->observation_b = DFM_TEST_PHASE_STARTUP_RUNNING;
		advance_after_interrupted_case(state);
		break;

	case DFM_TEST_PHASE_RUNNING:
		state->observation_a = UINT32_MAX;
		state->observation_b = DFM_TEST_PHASE_RUNNING;
		advance_after_interrupted_case(state);
		break;

	case DFM_TEST_PHASE_UNEXPECTED_FATAL:
		advance_after_interrupted_case(state);
		break;

	default:
		break;
	}
}

static void arm_startup_case(struct dfm_test_state_snapshot *state,
	const struct dfm_test_case *test)
{
	state->armed_test = test->numeric_id;
	state->phase = DFM_TEST_PHASE_STARTUP_ARMED;
	state->reboot_count++;
	state->observation_a = 0U;
	state->observation_b = 0U;
	dfm_test_state_commit(state);

	printk("DFMT:REBOOT_EXPECTED:%s:startup\n", test->id);
	k_busy_wait(1000);
	sys_reboot(SYS_REBOOT_COLD);
	CODE_UNREACHABLE;
}

int run_tests(void)
{
	struct dfm_test_state_snapshot state;

	if (!dfm_test_state_load(&state)) {
		dfm_test_state_initialize(new_run_id());
		(void)dfm_test_state_load(&state);
		printk("DFMT:SUITE_BEGIN:%s:%08x\n", DFM_TEST_VARIANT_NAME,
			state.run_id);
	} else if (state.next_index > DFM_TEST_CASE_COUNT) {
		printk("DFMT:HARNESS_FAIL:STATE:INDEX_OUT_OF_RANGE:%u\n",
			state.next_index);
		dfm_test_state_initialize(new_run_id());
		(void)dfm_test_state_load(&state);
		printk("DFMT:SUITE_BEGIN:%s:%08x\n", DFM_TEST_VARIANT_NAME,
			state.run_id);
	} else {
		printk("DFMT:BOOT:%s:%08x:phase=%u:index=%u:reboots=%u\n",
			DFM_TEST_VARIANT_NAME, state.run_id, state.phase,
			state.next_index, state.reboot_count);
	}

	if (state.phase == DFM_TEST_PHASE_COMPLETE) {
		printk("DFMT:SUITE_COMPLETE:%s:%08x\n", DFM_TEST_VARIANT_NAME,
			state.run_id);
		return 0;
	}

	recover_previous_boot(&state);
	prepare_trace_recorder();

	while (state.next_index < DFM_TEST_CASE_COUNT) {
		const struct dfm_test_case *test = &test_registry[state.next_index];
		int result;

		printk("DFMT:BEGIN:%s:%u\n", test->id, state.next_index);

		if (test->kind == DFM_TEST_KIND_STARTUP) {
			arm_startup_case(&state, test);
		}

		/* This event is a trace-payload oracle, not proof that execution
		 * returned after DFM_TRAP().
		 */
		(void)xTracePrintF(dfm_test_trace_channel(), "T%u BEGIN",
			(TraceUnsignedBaseType_t)test->numeric_id);

		state.armed_test = test->numeric_id;
		state.observation_a = 0U;
		state.observation_b = 0U;

		if (test->kind == DFM_TEST_KIND_DFM_REBOOT) {
			state.next_index++;
			state.phase = DFM_TEST_PHASE_EXPECT_DFM_REBOOT;
			state.reboot_count++;
			dfm_test_state_commit(&state);
			printk("DFMT:REBOOT_EXPECTED:%s:dfm\n", test->id);
			result = test->function(test->id);
			printk("DFMT:HARNESS_FAIL:%s:DFM_RESTART_RETURNED:%d\n",
				test->id, result);
		} else {
			state.phase = DFM_TEST_PHASE_RUNNING;
			dfm_test_state_commit(&state);
			result = test->function(test->id);
			printk("DFMT:RETURNED:%s:%d\n", test->id, result);
			state.next_index++;
		}

		state.armed_test = 0U;
		state.phase = DFM_TEST_PHASE_READY;
		state.observation_a = 0U;
		state.observation_b = 0U;
		dfm_test_state_commit(&state);
		k_msleep(DFM_TEST_INTER_CASE_DELAY_MS);
	}

	state.phase = DFM_TEST_PHASE_COMPLETE;
	state.armed_test = 0U;
	dfm_test_state_commit(&state);
	printk("DFMT:SUITE_COMPLETE:%s:%08x\n", DFM_TEST_VARIANT_NAME,
		state.run_id);
	return 0;
}

void dfm_tests_record_fatal(unsigned int reason)
{
	struct dfm_test_state_snapshot state;

	if (!dfm_test_state_load(&state) ||
	    (state.phase == DFM_TEST_PHASE_COMPLETE)) {
		return;
	}

	state.observation_a = reason;
	state.observation_b = state.phase;
	state.phase = DFM_TEST_PHASE_UNEXPECTED_FATAL;
	dfm_test_state_commit(&state);
}
