#include "test_internal.h"

#if DFM_TEST_VARIANT_ID == 7

#include <string.h>

#if !defined(DEMO_PLATFORM_STM32U585)
#error "m33_qual requires the STM32U585 target"
#endif

#define T22_FP_SENTINEL UINT32_C(100)

DFM_TEST_NOINLINE DFM_TEST_USED
static int dfm_t22_active_fp_trap(void)
{
	uint32_t fpccr = FPU->FPCCR;
	uint32_t control_before;
	uint32_t control_after;
	uint32_t restored_s16;
	bool returned = false;

	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1022 FPCCR=%08X", (TraceUnsignedBaseType_t)fpccr);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1022 sentinel=%u",
		(TraceUnsignedBaseType_t)T22_FP_SENTINEL);
	__asm__ volatile("vmov s16, %0" : : "r"(T22_FP_SENTINEL) : "s16", "memory");
	__DSB();
	__ISB();
	control_before = __get_CONTROL();

	DFM_TRAP(1022, "Test 1022: active FP coredump and unwind", 0);
	returned = true;
	control_after = __get_CONTROL();
	__asm__ volatile("vmov %0, s16" : "=r"(restored_s16) : : "memory");

	printk("DFMT:OBS:1022:fpccr=0x%08x:control_before=0x%08x:"
		"control_after=0x%08x:s16=%u\n",
		(unsigned int)fpccr, (unsigned int)control_before,
		(unsigned int)control_after, (unsigned int)restored_s16);
	dfm_test_check("1022",
		(fpccr & (FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk)) ==
		(FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk),
		"LAZY_FP_STACKING_ENABLED");
	dfm_test_check("1022", (control_before & CONTROL_FPCA_Msk) != 0U,
		"FP_CONTEXT_ACTIVE");
	dfm_test_check("1022", restored_s16 == T22_FP_SENTINEL,
		"FP_REGISTER_RESTORED");
	dfm_test_check("1022", (control_after & CONTROL_FPCA_Msk) != 0U,
		"FP_CONTEXT_STILL_ACTIVE");
	dfm_test_check("1022", returned, "TRAP_RETURNED");

	return (((fpccr & (FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk)) ==
		 (FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk)) &&
		((control_before & CONTROL_FPCA_Msk) != 0U) &&
		(restored_s16 == T22_FP_SENTINEL) &&
		((control_after & CONTROL_FPCA_Msk) != 0U) && returned) ? 0 : -1;
}

int dfm_test_run_t22(const char *test_id)
{
	ARG_UNUSED(test_id);
	return dfm_t22_active_fp_trap();
}

#define T23_STACK_WORDS 512U
#define T23_PRESSURE_WORDS 256U
#define T23_MIN_HEADROOM 128U
#define T23_MAX_HEADROOM 1152U

static StaticTask_t t23_tcb;
static StackType_t t23_stack[T23_STACK_WORDS];
static StaticSemaphore_t t23_done_storage;
static SemaphoreHandle_t t23_done;

struct t23_observations {
	uint32_t psplim_before;
	uint32_t psplim_after;
	uint32_t psp_before;
	uint32_t psp_after;
	size_t unused_before;
	size_t unused_after;
	uint32_t checksum_before;
	uint32_t checksum_after;
	bool returned;
};

static volatile struct t23_observations t23_observations;

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t23_protected_stack_task(void *argument)
{
	volatile uint32_t pressure[T23_PRESSURE_WORDS];
	uint32_t checksum = 0U;
	uint32_t i;

	ARG_UNUSED(argument);
	for (i = 0U; i < ARRAY_SIZE(pressure); i++) {
		pressure[i] = UINT32_C(1000) + i;
		checksum = (checksum << 5) ^ (checksum >> 2) ^ pressure[i];
	}
	t23_observations.checksum_before = checksum;
	t23_observations.unused_before =
		(size_t)uxTaskGetStackHighWaterMark2(NULL) * sizeof(StackType_t);
	t23_observations.psplim_before = __get_PSPLIM();
	t23_observations.psp_before = __get_PSP();

	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1023 PSP=%08X",
		(TraceUnsignedBaseType_t)t23_observations.psp_before);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1023 PSPLIM=%08X",
		(TraceUnsignedBaseType_t)t23_observations.psplim_before);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1023 STACK unused=%u",
		(TraceUnsignedBaseType_t)t23_observations.unused_before);
	DFM_TRAP(1023, "Test 1023: protected-stack unwind", 0);
	t23_observations.returned = true;
	t23_observations.psplim_after = __get_PSPLIM();
	t23_observations.psp_after = __get_PSP();
	t23_observations.unused_after =
		(size_t)uxTaskGetStackHighWaterMark2(NULL) * sizeof(StackType_t);

	checksum = 0U;
	for (i = 0U; i < ARRAY_SIZE(pressure); i++) {
		checksum = (checksum << 5) ^ (checksum >> 2) ^ pressure[i];
	}
	t23_observations.checksum_after = checksum;
	(void)xSemaphoreGive(t23_done);
	vTaskDelete(NULL);
}

int dfm_test_run_t23(const char *test_id)
{
	uint32_t headroom_before;
	BaseType_t wait_result;
	TaskHandle_t task;
	bool passed;

	ARG_UNUSED(test_id);
	memset((void *)&t23_observations, 0, sizeof(t23_observations));
	t23_done = xSemaphoreCreateBinaryStatic(&t23_done_storage);
	task = xTaskCreateStatic(dfm_t23_protected_stack_task, "dfm_t23",
		T23_STACK_WORDS, NULL, configMAX_PRIORITIES - 2U,
		t23_stack, &t23_tcb);
	wait_result = task != NULL
		? xSemaphoreTake(t23_done, pdMS_TO_TICKS(10000U)) : pdFALSE;
	headroom_before = t23_observations.psp_before -
		t23_observations.psplim_before;

	printk("DFMT:OBS:1023:psplim_before=0x%08x:psplim_after=0x%08x:"
		"psp_before=0x%08x:psp_after=0x%08x:headroom=%u:"
		"unused_before=%u:unused_after=%u\n",
		(unsigned int)t23_observations.psplim_before,
		(unsigned int)t23_observations.psplim_after,
		(unsigned int)t23_observations.psp_before,
		(unsigned int)t23_observations.psp_after,
		(unsigned int)headroom_before,
		(unsigned int)t23_observations.unused_before,
		(unsigned int)t23_observations.unused_after);
	dfm_test_check("1023", task != NULL, "TASK_CREATED");
	dfm_test_check("1023", wait_result == pdTRUE, "TASK_COMPLETED");
	dfm_test_check("1023", t23_observations.returned, "TRAP_RETURNED");
	dfm_test_check("1023", t23_observations.psplim_before != 0U,
		"PSPLIM_ENABLED");
	dfm_test_check("1023",
		t23_observations.psplim_after == t23_observations.psplim_before,
		"PSPLIM_RESTORED");
	dfm_test_check("1023",
		(t23_observations.psp_before > t23_observations.psplim_before) &&
		(headroom_before >= T23_MIN_HEADROOM) &&
		(headroom_before <= T23_MAX_HEADROOM),
		"VALID_LIMITED_HEADROOM");
	dfm_test_check("1023", t23_observations.unused_after > 0U,
		"STACK_GUARD_INTACT");
	dfm_test_check("1023",
		t23_observations.checksum_after == t23_observations.checksum_before,
		"LIVE_STACK_DATA_INTACT");

	passed = (task != NULL) && (wait_result == pdTRUE) &&
		t23_observations.returned &&
		(t23_observations.psplim_before != 0U) &&
		(t23_observations.psplim_after == t23_observations.psplim_before) &&
		(t23_observations.psp_before > t23_observations.psplim_before) &&
		(headroom_before >= T23_MIN_HEADROOM) &&
		(headroom_before <= T23_MAX_HEADROOM) &&
		(t23_observations.unused_after > 0U) &&
		(t23_observations.checksum_after ==
		 t23_observations.checksum_before);
	return passed ? 0 : -1;
}

#endif /* DFM_TEST_VARIANT_ID == 7 */
