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
	DFM_TRAP(1017, "Test 1017", 0);
	stopped_after = !xTraceIsRecorderEnabled();
	dfm_test_check("1017", stopped_before, "TRACE_STOPPED_BEFORE");
	dfm_test_check("1017", stopped_after, "TRACE_STILL_STOPPED");

	/* Cleanup occurs only after the state required by the oracle was sampled. */
	(void)xTraceEnable(TRC_START);
	return stopped_before && stopped_after ? 0 : -1;
}

#define T18_STACK_SIZE 1536U
#define T18_STACK_WORDS (T18_STACK_SIZE / sizeof(StackType_t))
static StackType_t t18_stack[T18_STACK_WORDS];
static StaticTask_t t18_tcb;
static StaticSemaphore_t t18_done_storage;
static SemaphoreHandle_t t18_done;
static volatile int t18_space_before_result;
static volatile int t18_space_after_result;
static volatile size_t t18_unused_before;
static volatile size_t t18_unused_after;
static volatile bool t18_returned;

static void dfm_t18_small_stack_thread(void *argument)
{
	ARG_UNUSED(argument);
	DFM_STACK_MARKER();
	t18_space_before_result = 0;
	t18_unused_before =
		(size_t)uxTaskGetStackHighWaterMark(NULL) * sizeof(StackType_t);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1018 STACK size=%u",
		(TraceUnsignedBaseType_t)T18_STACK_SIZE);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1018 STACK unused=%u",
		(TraceUnsignedBaseType_t)t18_unused_before);
	DFM_TRAP(1018, "Test 1018", 0);
	t18_returned = true;
	t18_space_after_result = 0;
	t18_unused_after =
		(size_t)uxTaskGetStackHighWaterMark(NULL) * sizeof(StackType_t);
	(void)xSemaphoreGive(t18_done);
	vTaskDelete(NULL);
}

int dfm_test_run_t18(const char *test_id)
{
	BaseType_t wait_result;
	TaskHandle_t task;

	ARG_UNUSED(test_id);
	t18_space_before_result = -1;
	t18_space_after_result = -1;
	t18_unused_before = 0U;
	t18_unused_after = 0U;
	t18_returned = false;
	if (t18_done == NULL) {
		t18_done = xSemaphoreCreateBinaryStatic(&t18_done_storage);
	}
	(void)xSemaphoreTake(t18_done, 0U);
	task = xTaskCreateStatic(dfm_t18_small_stack_thread, "T1018Small",
		T18_STACK_WORDS, NULL, 4U, t18_stack, &t18_tcb);
	wait_result = xSemaphoreTake(t18_done, pdMS_TO_TICKS(10000U));
	printk("DFMT:OBS:1018:stack_size=%u:unused_before=%u:unused_after=%u\n",
		(unsigned int)T18_STACK_SIZE, (unsigned int)t18_unused_before,
		(unsigned int)t18_unused_after);
	dfm_test_check("1018", task != NULL, "THREAD_CREATED");
	dfm_test_check("1018", wait_result == pdTRUE, "THREAD_COMPLETED");
	dfm_test_check("1018", t18_returned, "TRAP_RETURNED");
	dfm_test_check("1018",
		(t18_space_before_result == 0) && (t18_space_after_result == 0),
		"STACK_SPACE_MEASURED");
	dfm_test_check("1018", t18_unused_after > 0U, "STACK_HEADROOM_REMAINS");
	return (task != NULL) && (wait_result == pdTRUE) && t18_returned &&
		(t18_space_before_result == 0) && (t18_space_after_result == 0) &&
		(t18_unused_after > 0U) ? 0 : -1;
}

/* Keep the ID in a named object so its input length remains observable. */
static const char t19_message[] =
	"Test 1019A";

int dfm_test_run_t19(const char *test_id)
{
	ARG_UNUSED(test_id);
	printk("DFMT:OBS:1019:input_bytes=%u\n",
		(unsigned int)(sizeof(t19_message) - 1U));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1019A MSG chars=%u formatted_max=49",
		(TraceUnsignedBaseType_t)(sizeof(t19_message) - 1U));
	DFM_TRAP(1019, t19_message, 0);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1019B RETURN first trap completed");
	DFM_TRAP(1019, "Test 1019B", 0);
	return 0;
}

int dfm_test_run_t20(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1020, "Test 1020A", 0);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1020B RETURN first trap completed");
	DFM_TRAP(1020, "Test 1020B", 0);
	return 0;
}
