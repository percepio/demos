#include "test_internal.h"
#include "platform.h"

#include <dfm.h>

void dfm_test_run_pre_init_startup(void)
{
	struct dfm_test_state_snapshot state;
	uint32_t ipsr;
	uint32_t control;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_ARMED) ||
	    (state.armed_test != 1010U)) {
		return;
	}

	dfm_test_state_mark_startup_running(1010U);
	ipsr = __get_IPSR();
	control = __get_CONTROL();
	DFM_TRAP(1010, "Test 1010", 1);
	dfm_test_state_mark_startup_done(1010U, ipsr, control);
}

void dfm_test_run_post_init_startup(void)
{
	struct dfm_test_state_snapshot state;
	uint32_t ipsr;
	uint32_t control;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_ARMED) ||
	    (state.armed_test != 1005U)) {
		return;
	}

	dfm_test_state_mark_startup_running(1005U);
	ipsr = __get_IPSR();
	control = __get_CONTROL();
	printk("DFMT:STARTUP_ENTER:1005:ipsr=%u:control=0x%x\n",
		(unsigned int)ipsr, (unsigned int)control);
	DFM_TRAP(1005, "Test 1005", 0);
	dfm_test_state_mark_startup_done(1005U, ipsr, control);
}

static volatile uint32_t t06_ipsr;
static volatile bool t06_returned;

void DFM_Test_IRQHandler(void)
{
	t06_ipsr = __get_IPSR();
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1006A CTX Handler IPSR=%u",
		(TraceUnsignedBaseType_t)t06_ipsr);
	DFM_TRAP(1006, "Test 1006A", 0);
	t06_returned = true;
}

int dfm_test_run_t06(const char *test_id)
{
	TickType_t deadline;

	ARG_UNUSED(test_id);
	t06_ipsr = 0U;
	t06_returned = false;
	platform_test_interrupt_trigger();
	deadline = xTaskGetTickCount() + pdMS_TO_TICKS(1000U);
	while (!t06_returned && (xTaskGetTickCount() < deadline)) {
		taskYIELD();
	}
	platform_test_interrupt_cleanup();

	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1006B RETURN first trap; IPSR=%u",
		(TraceUnsignedBaseType_t)t06_ipsr);
	dfm_test_check("1006", t06_ipsr != 0U, "HANDLER_MODE");
	dfm_test_check("1006", t06_returned, "ISR_RETURNED");
	DFM_TRAP(1006, "Test 1006B", 0);
	return (t06_ipsr != 0U) && t06_returned ? 0 : -1;
}

int dfm_test_run_t08(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1008, "Test 1008", 1);
	return -1;
}

static StaticSemaphore_t t09_done_storage;
static SemaphoreHandle_t t09_done;
static volatile bool t09_returned;

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t09_trap_site(uint32_t value)
{
	volatile uint32_t trap_value = value;

	DFM_TRAP(1009, "Test 1009", 0);
	t09_returned = trap_value == UINT32_C(9);
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t09_service(uint32_t value)
{
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1009 DATA value=%u", (TraceUnsignedBaseType_t)value);
	dfm_t09_trap_site(value);
	t09_returned = t09_returned && true;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t09_app_work_handler(void *argument, uint32_t value)
{
	ARG_UNUSED(argument);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1009 PATH timer-daemon -> service");
	dfm_t09_service(value);
	(void)xSemaphoreGive(t09_done);
}

int dfm_test_run_t09(const char *test_id)
{
	BaseType_t submit_result;
	BaseType_t wait_result;

	ARG_UNUSED(test_id);
	if (t09_done == NULL) {
		t09_done = xSemaphoreCreateBinaryStatic(&t09_done_storage);
	}
	(void)xSemaphoreTake(t09_done, 0U);
	t09_returned = false;
	submit_result = xTimerPendFunctionCall(dfm_t09_app_work_handler, NULL,
		UINT32_C(9), pdMS_TO_TICKS(1000U));
	wait_result = xSemaphoreTake(t09_done, pdMS_TO_TICKS(10000U));
	dfm_test_check("1009", submit_result == pdPASS, "WORK_SUBMITTED");
	dfm_test_check("1009", wait_result == pdTRUE, "WORK_COMPLETED");
	dfm_test_check("1009", t09_returned, "TRAP_RETURNED");
	return (submit_result == pdPASS) && (wait_result == pdTRUE) &&
		t09_returned ? 0 : -1;
}

int dfm_test_run_t15(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1015, "Test 1015", 0);
	return 0;
}

#define T16_MSP_WORDS 512U
static uint32_t t16_msp_stack[T16_MSP_WORDS] __attribute__((aligned(8)));
static volatile uint32_t t16_ipsr_at_trap;
static volatile uint32_t t16_control_at_trap;
static volatile bool t16_returned;

void dfm_test_t16_trap_site(void)
{
	t16_ipsr_at_trap = __get_IPSR();
	t16_control_at_trap = __get_CONTROL();
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1016A CTX IPSR=%u",
		(TraceUnsignedBaseType_t)t16_ipsr_at_trap);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1016A CTX CONTROL=%08X",
		(TraceUnsignedBaseType_t)t16_control_at_trap);
	DFM_TRAP(1016, "Test 1016A", 0);
	t16_returned = true;
}

int dfm_test_run_t16(const char *test_id)
{
	uint32_t control_after;

	ARG_UNUSED(test_id);
	t16_ipsr_at_trap = UINT32_MAX;
	t16_control_at_trap = UINT32_MAX;
	t16_returned = false;
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1016A ACTION switch PSP -> MSP");
	taskENTER_CRITICAL();
	dfm_test_t16_run_on_msp(&t16_msp_stack[T16_MSP_WORDS],
		&t16_msp_stack[0]);
	taskEXIT_CRITICAL();
	control_after = __get_CONTROL();
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1016B RETURN trap_CTL=%08X",
		(TraceUnsignedBaseType_t)t16_control_at_trap);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1016B RETURN now_CTL=%08X",
		(TraceUnsignedBaseType_t)control_after);
	dfm_test_check("1016", t16_ipsr_at_trap == 0U, "THREAD_MODE");
	dfm_test_check("1016",
		(t16_control_at_trap & CONTROL_SPSEL_Msk) == 0U, "MSP_SELECTED");
	dfm_test_check("1016", (control_after & CONTROL_SPSEL_Msk) != 0U,
		"PSP_RESTORED");
	dfm_test_check("1016", t16_returned, "TRAP_RETURNED");
	DFM_TRAP(1016, "Test 1016B", 0);
	return (t16_ipsr_at_trap == 0U) &&
		((t16_control_at_trap & CONTROL_SPSEL_Msk) == 0U) &&
		((control_after & CONTROL_SPSEL_Msk) != 0U) && t16_returned ? 0 : -1;
}

#define T21_STACK_WORDS 256U
static StackType_t t21_stack[T21_STACK_WORDS];
static StaticTask_t t21_tcb;
static StaticSemaphore_t t21_done_storage;
static SemaphoreHandle_t t21_done;
static volatile bool t21_high_thread_ran;

static void dfm_t21_high_thread(void *argument)
{
	ARG_UNUSED(argument);
	t21_high_thread_ran = true;
	(void)xSemaphoreGive(t21_done);
	vTaskDelete(NULL);
}

int dfm_test_run_t21(const char *test_id)
{
	UBaseType_t original_priority = uxTaskPriorityGet(NULL);
	bool stayed_blocked;
	BaseType_t wait_result;
	TaskHandle_t high_task;

	ARG_UNUSED(test_id);
	if (t21_done == NULL) {
		t21_done = xSemaphoreCreateBinaryStatic(&t21_done_storage);
	}
	(void)xSemaphoreTake(t21_done, 0U);
	t21_high_thread_ran = false;

	vTaskPrioritySet(NULL, 2U);
	vTaskSuspendAll();
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021 DATA current_prio=%d", (TraceBaseType_t)2);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021 DATA high_prio=%d", (TraceBaseType_t)4);
	high_task = xTaskCreateStatic(dfm_t21_high_thread, "T1021High",
		T21_STACK_WORDS, NULL, 4U, t21_stack, &t21_tcb);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1021A STATE high thread ready; scheduler locked");
	DFM_TRAP(1021, "Test 1021A", 0);
	stayed_blocked = !t21_high_thread_ran;
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021A RETURN high_ran=%u",
		(TraceUnsignedBaseType_t)t21_high_thread_ran);
	(void)xTaskResumeAll();

	wait_result = xSemaphoreTake(t21_done, pdMS_TO_TICKS(5000U));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021B POST high_ran=%u",
		(TraceUnsignedBaseType_t)t21_high_thread_ran);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021B POST wait=%d",
		(TraceBaseType_t)wait_result);
	vTaskPrioritySet(NULL, original_priority);
	dfm_test_check("1021", high_task != NULL, "HIGH_THREAD_CREATED");
	dfm_test_check("1021", stayed_blocked, "OUTER_LOCK_PRESERVED");
	dfm_test_check("1021", wait_result == pdTRUE && t21_high_thread_ran,
		"HIGH_THREAD_RAN_AFTER_UNLOCK");
	DFM_TRAP(1021, "Test 1021B", 0);
	return (high_task != NULL) && stayed_blocked &&
		(wait_result == pdTRUE) && t21_high_thread_ran ? 0 : -1;
}

int dfm_test_run_t25(const char *test_id)
{
	ARG_UNUSED(test_id);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1025 FAULT deliberate undefined instruction");
	__asm volatile("udf #0");
	return -1;
}
