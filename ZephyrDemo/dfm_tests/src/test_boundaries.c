#include "test_internal.h"

#include <dfm.h>
#include <trcRecorder.h>

int dfm_test_run_t17(const char *test_id)
{
	bool stopped_before;
	bool stopped_after;

	ARG_UNUSED(test_id);
	(void)xTraceDisable();
	stopped_before = !xTraceIsRecorderEnabled();
	DFM_TRAP(1017, "Test 1017: trap dump only; trace disabled", 0);
	stopped_after = !xTraceIsRecorderEnabled();
	dfm_test_check("1017", stopped_before, "TRACE_STOPPED_BEFORE");
	dfm_test_check("1017", stopped_after, "TRACE_STILL_STOPPED");

	/* Cleanup occurs only after the state required by the oracle was sampled. */
	(void)xTraceEnable(TRC_START);
	return stopped_before && stopped_after ? 0 : -1;
}

#define T18_STACK_SIZE 1536
K_THREAD_STACK_DEFINE(t18_stack, T18_STACK_SIZE);
static struct k_thread t18_thread;
K_SEM_DEFINE(t18_done, 0, 1);
static volatile int t18_space_before_result;
static volatile int t18_space_after_result;
static volatile size_t t18_unused_before;
static volatile size_t t18_unused_after;
static volatile bool t18_returned;

static void dfm_t18_small_stack_thread(void *arg0, void *arg1, void *arg2)
{
	size_t unused_before = 0U;
	size_t unused_after = 0U;

	ARG_UNUSED(arg0);
	ARG_UNUSED(arg1);
	ARG_UNUSED(arg2);
	t18_space_before_result = k_thread_stack_space_get(k_current_get(),
		&unused_before);
	t18_unused_before = unused_before;
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1018 STACK size=%u",
		(TraceUnsignedBaseType_t)T18_STACK_SIZE);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1018 STACK unused=%u",
		(TraceUnsignedBaseType_t)t18_unused_before);
	DFM_TRAP(1018, "Test 1018: GDB bt small_stack_thread", 0);
	t18_returned = true;
	t18_space_after_result = k_thread_stack_space_get(k_current_get(),
		&unused_after);
	t18_unused_after = unused_after;
	k_sem_give(&t18_done);
}

int dfm_test_run_t18(const char *test_id)
{
	int wait_result;

	ARG_UNUSED(test_id);
	t18_space_before_result = -1;
	t18_space_after_result = -1;
	t18_unused_before = 0U;
	t18_unused_after = 0U;
	t18_returned = false;
	k_sem_reset(&t18_done);
	(void)k_thread_create(&t18_thread, t18_stack,
		K_THREAD_STACK_SIZEOF(t18_stack), dfm_t18_small_stack_thread,
		NULL, NULL, NULL, K_PRIO_PREEMPT(1), 0, K_NO_WAIT);
	wait_result = k_sem_take(&t18_done, K_SECONDS(10));
	printk("DFMT:OBS:1018:stack_size=%u:unused_before=%u:unused_after=%u\n",
		(unsigned int)T18_STACK_SIZE, (unsigned int)t18_unused_before,
		(unsigned int)t18_unused_after);
	dfm_test_check("1018", wait_result == 0, "THREAD_COMPLETED");
	dfm_test_check("1018", t18_returned, "TRAP_RETURNED");
	dfm_test_check("1018",
		(t18_space_before_result == 0) && (t18_space_after_result == 0),
		"STACK_SPACE_MEASURED");
	dfm_test_check("1018", t18_unused_after > 0U, "STACK_HEADROOM_REMAINS");
	return (wait_result == 0) && t18_returned &&
		(t18_space_before_result == 0) && (t18_space_after_result == 0) &&
		(t18_unused_after > 0U) ? 0 : -1;
}

/* Deliberately exceeds one TraceRecorder user-event blob for the limit test. */
static const char t19_near_limit_message[] =
	"Test 1019A: Expected: near-limit description accepted; trace T1019A";

int dfm_test_run_t19(const char *test_id)
{
	ARG_UNUSED(test_id);
	printk("DFMT:OBS:1019:input_bytes=%u\n",
		(unsigned int)(sizeof(t19_near_limit_message) - 1U));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1019A LIMIT input_chars=%u host_limit=100",
		(TraceUnsignedBaseType_t)(sizeof(t19_near_limit_message) - 1U));
	DFM_TRAP(1019, t19_near_limit_message, 0);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1019B RETURN first trap completed");
	DFM_TRAP(1019, "Test 1019B: first trap returned", 0);
	return 0;
}

int dfm_test_run_t20(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1020, "Test 1020A: no dump; buffer too small", 0);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1020B RETURN first trap completed");
	DFM_TRAP(1020, "Test 1020B: no dump; first trap returned", 0);
	return 0;
}
