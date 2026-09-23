#include "test_internal.h"

#include <dfm.h>

#include <cmsis_core.h>
#include <zephyr/init.h>
#include <zephyr/irq_offload.h>

static int dfm_test_t10_pre_kernel(void)
{
	struct dfm_test_state_snapshot state;
	uint32_t ipsr;
	uint32_t control;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_ARMED) ||
	    (state.armed_test != 1010U)) {
		return 0;
	}

	dfm_test_state_mark_startup_running(1010U);
	ipsr = __get_IPSR();
	control = __get_CONTROL();
	DFM_TRAP(1010, "Test 1010", 1);
	dfm_test_state_mark_startup_done(1010U, ipsr, control);
	return 0;
}

SYS_INIT(dfm_test_t10_pre_kernel, PRE_KERNEL_1, 0);

static int dfm_test_t05_application(void)
{
	struct dfm_test_state_snapshot state;
	uint32_t ipsr;
	uint32_t control;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_ARMED) ||
	    (state.armed_test != 1005U)) {
		return 0;
	}

	dfm_test_state_mark_startup_running(1005U);
	ipsr = __get_IPSR();
	control = __get_CONTROL();
	printk("DFMT:STARTUP_ENTER:1005:ipsr=%u:control=0x%x\n", ipsr,
		control);
	DFM_TRAP(1005, "Test 1005", 0);
	dfm_test_state_mark_startup_done(1005U, ipsr, control);
	return 0;
}

SYS_INIT(dfm_test_t05_application, APPLICATION, 1);

static volatile uint32_t t06_ipsr;
static volatile bool t06_returned;

static void dfm_t06_isr(const void *parameter)
{
	ARG_UNUSED(parameter);
	t06_ipsr = __get_IPSR();
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1006A CTX Handler IPSR=%u", (TraceUnsignedBaseType_t)t06_ipsr);
	DFM_TRAP(1006, "Test 1006A", 0);
	t06_returned = true;
}

int dfm_test_run_t06(const char *test_id)
{
	ARG_UNUSED(test_id);
	t06_ipsr = 0U;
	t06_returned = false;
	irq_offload(dfm_t06_isr, NULL);
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

int dfm_test_run_t27(const char *test_id)
{
	ARG_UNUSED(test_id);
	(void)xTracePrint(dfm_test_trace_channel(), "T1027 RETAIN BEGIN");
	DFM_TRAP(1027, "Test 1027A", 0);
	(void)xTracePrint(dfm_test_trace_channel(), "T1027 RETAIN END");
	DFM_TRAP(1027, "Test 1027B", 1);
	return -1;
}

K_SEM_DEFINE(t09_done, 0, 1);
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
static void dfm_t09_app_work_handler(struct k_work *work)
{
	ARG_UNUSED(work);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1009 PATH app_work_handler -> service");
	dfm_t09_service(UINT32_C(9));
	k_sem_give(&t09_done);
}

K_WORK_DEFINE(t09_work, dfm_t09_app_work_handler);

int dfm_test_run_t09(const char *test_id)
{
	int submit_result;
	int wait_result;

	ARG_UNUSED(test_id);
	t09_returned = false;
	k_sem_reset(&t09_done);
	submit_result = k_work_submit(&t09_work);
	wait_result = k_sem_take(&t09_done, K_SECONDS(10));
	dfm_test_check("1009", submit_result >= 0, "WORK_SUBMITTED");
	dfm_test_check("1009", wait_result == 0, "WORK_COMPLETED");
	dfm_test_check("1009", t09_returned, "TRAP_RETURNED");
	return (submit_result >= 0) && (wait_result == 0) && t09_returned ? 0 : -1;
}

int dfm_test_run_t15(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1015, "Test 1015", 0);
	return 0;
}

#define T16_MSP_WORDS 512
static uint32_t t16_msp_stack[T16_MSP_WORDS] __aligned(8);
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
	dfm_test_t16_run_on_msp(&t16_msp_stack[T16_MSP_WORDS],
		&t16_msp_stack[0]);
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

#define T21_STACK_SIZE 1024
K_THREAD_STACK_DEFINE(t21_stack, T21_STACK_SIZE);
static struct k_thread t21_thread;
K_SEM_DEFINE(t21_done, 0, 1);
static volatile bool t21_high_thread_ran;

static void dfm_t21_high_thread(void *arg0, void *arg1, void *arg2)
{
	ARG_UNUSED(arg0);
	ARG_UNUSED(arg1);
	ARG_UNUSED(arg2);
	t21_high_thread_ran = true;
	k_sem_give(&t21_done);
}

int dfm_test_run_t21(const char *test_id)
{
	k_tid_t current = k_current_get();
	int original_priority = k_thread_priority_get(current);
	bool stayed_blocked;
	int wait_result;

	ARG_UNUSED(test_id);
	t21_high_thread_ran = false;
	k_sem_reset(&t21_done);

	k_sched_lock();
	k_thread_priority_set(current, K_PRIO_PREEMPT(5));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021 DATA current_prio=%d",
		(TraceBaseType_t)K_PRIO_PREEMPT(5));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021 DATA high_prio=%d",
		(TraceBaseType_t)K_PRIO_PREEMPT(0));
	(void)k_thread_create(&t21_thread, t21_stack,
		K_THREAD_STACK_SIZEOF(t21_stack), dfm_t21_high_thread,
		NULL, NULL, NULL, K_PRIO_PREEMPT(0), 0, K_NO_WAIT);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1021A STATE high thread ready; scheduler locked");
	DFM_TRAP(1021, "Test 1021A", 0);
	stayed_blocked = !t21_high_thread_ran;
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021A RETURN high_ran=%u",
		(TraceUnsignedBaseType_t)t21_high_thread_ran);
	k_sched_unlock();

	wait_result = k_sem_take(&t21_done, K_SECONDS(5));
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021B POST high_ran=%u",
		(TraceUnsignedBaseType_t)t21_high_thread_ran);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1021B POST wait=%d",
		(TraceBaseType_t)wait_result);
	k_thread_priority_set(current, original_priority);
	dfm_test_check("1021", stayed_blocked, "OUTER_LOCK_PRESERVED");
	dfm_test_check("1021", wait_result == 0 && t21_high_thread_ran,
		"HIGH_THREAD_RAN_AFTER_UNLOCK");
	DFM_TRAP(1021, "Test 1021B", 0);
	return stayed_blocked && (wait_result == 0) && t21_high_thread_ran ? 0 : -1;
}
