#include "test_internal.h"

#include <dfm.h>
#include <trcRecorder.h>

int dfm_test_run_t26(const char *test_id)
{
	bool recorder_enabled_before;
	bool recorder_enabled_after;

	ARG_UNUSED(test_id);
	recorder_enabled_before = xTraceIsRecorderEnabled();
	DFM_TRAP(1026, "Test 1026", 0);
	recorder_enabled_after = xTraceIsRecorderEnabled();
	dfm_test_check("1026", recorder_enabled_before,
		"RECORDER_ENABLED_BEFORE");
	dfm_test_check("1026", recorder_enabled_after,
		"RECORDER_ENABLED_AFTER");
	return recorder_enabled_before && recorder_enabled_after ? 0 : -1;
}

static DFM_TEST_NOINLINE DFM_TEST_USED void
dfm_t25_undefined_instruction(void)
{
	/* UDF #0 is guaranteed to be undefined on Cortex-M and enters the real
	 * Zephyr fault path rather than calling a fatal handler directly.
	 */
	__asm__ volatile(".short 0xde00");
	CODE_UNREACHABLE;
}

int dfm_test_run_t25(const char *test_id)
{
	ARG_UNUSED(test_id);
	printk("DFMT:OBS:1025:fault=undefined_instruction\n");
	dfm_t25_undefined_instruction();
	return -1;
}
