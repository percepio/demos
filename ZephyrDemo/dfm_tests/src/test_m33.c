#include "test_internal.h"

#if DFM_TEST_VARIANT_ID == 7

#include <string.h>

#include <cmsis_core.h>
#include <dfm.h>
#include <trcRecorder.h>
#include <zephyr/sys/util.h>

BUILD_ASSERT(IS_ENABLED(CONFIG_ARMV8_M_MAINLINE),
	"m33_qual requires Armv8-M Mainline");
BUILD_ASSERT(IS_ENABLED(CONFIG_CPU_CORTEX_M_HAS_SPLIM),
	"m33_qual requires PSPLIM/MSPLIM");
BUILD_ASSERT(IS_ENABLED(CONFIG_FPU), "m33_qual requires an FPU");
BUILD_ASSERT(IS_ENABLED(CONFIG_FPU_SHARING),
	"m33_qual requires shared FP contexts");
BUILD_ASSERT(IS_ENABLED(CONFIG_BUILTIN_STACK_GUARD),
	"m33_qual requires the Armv8-M built-in stack guard");

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

	/* S16 is callee-saved by the Arm hard-float ABI. Writing it makes the
	 * thread's floating-point context active without letting the compiler
	 * constant-fold the operation away.
	 */
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
		fpccr, control_before, control_after, restored_s16);
	dfm_test_check("1022",
		(fpccr & (FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk)) ==
		(FPU_FPCCR_ASPEN_Msk | FPU_FPCCR_LSPEN_Msk),
		"LAZY_FP_STACKING_ENABLED");
	dfm_test_check("1022",
		(control_before & CONTROL_FPCA_Msk) != 0U,
		"FP_CONTEXT_ACTIVE");
	dfm_test_check("1022", restored_s16 == T22_FP_SENTINEL,
		"FP_REGISTER_RESTORED");
	dfm_test_check("1022",
		(control_after & CONTROL_FPCA_Msk) != 0U,
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

#define T23_STACK_SIZE 2048
#define T23_PRESSURE_WORDS 256
#define T23_MIN_HEADROOM 128U
#define T23_MAX_HEADROOM 1152U

K_THREAD_STACK_DEFINE(t23_stack, T23_STACK_SIZE);
static struct k_thread t23_thread;
K_SEM_DEFINE(t23_done, 0, 1);

struct t23_observations {
	uint32_t psplim_before;
	uint32_t psplim_after;
	uint32_t psp_before;
	uint32_t psp_after;
	size_t unused_before;
	size_t unused_after;
	uint32_t checksum_before;
	uint32_t checksum_after;
	int stack_measure_before;
	int stack_measure_after;
	bool returned;
};

static volatile struct t23_observations t23_observations;

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t23_protected_stack_thread(void *arg0, void *arg1, void *arg2)
{
	volatile uint32_t pressure[T23_PRESSURE_WORDS];
	size_t unused_before = 0U;
	size_t unused_after = 0U;
	uint32_t checksum = 0U;
	uint32_t i;

	ARG_UNUSED(arg0);
	ARG_UNUSED(arg1);
	ARG_UNUSED(arg2);

	for (i = 0U; i < ARRAY_SIZE(pressure); i++) {
		pressure[i] = UINT32_C(1000) + i;
		checksum = (checksum << 5) ^ (checksum >> 2) ^ pressure[i];
	}
	t23_observations.checksum_before = checksum;
	t23_observations.stack_measure_before = k_thread_stack_space_get(
		k_current_get(), &unused_before);
	t23_observations.unused_before = unused_before;
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
	t23_observations.stack_measure_after = k_thread_stack_space_get(
		k_current_get(), &unused_after);
	t23_observations.unused_after = unused_after;

	checksum = 0U;
	for (i = 0U; i < ARRAY_SIZE(pressure); i++) {
		checksum = (checksum << 5) ^ (checksum >> 2) ^ pressure[i];
	}
	t23_observations.checksum_after = checksum;
	k_sem_give(&t23_done);
}

int dfm_test_run_t23(const char *test_id)
{
	uint32_t headroom_before;
	int wait_result;
	bool passed;

	ARG_UNUSED(test_id);
	memset((void *)&t23_observations, 0, sizeof(t23_observations));
	k_sem_reset(&t23_done);
	(void)k_thread_create(&t23_thread, t23_stack,
		K_THREAD_STACK_SIZEOF(t23_stack), dfm_t23_protected_stack_thread,
		NULL, NULL, NULL, K_PRIO_PREEMPT(1), 0, K_NO_WAIT);
	wait_result = k_sem_take(&t23_done, K_SECONDS(10));
	headroom_before = t23_observations.psp_before -
		t23_observations.psplim_before;

	printk("DFMT:OBS:1023:psplim_before=0x%08x:psplim_after=0x%08x:"
		"psp_before=0x%08x:psp_after=0x%08x:headroom=%u:"
		"unused_before=%u:unused_after=%u\n",
		t23_observations.psplim_before, t23_observations.psplim_after,
		t23_observations.psp_before, t23_observations.psp_after,
		headroom_before, (unsigned int)t23_observations.unused_before,
		(unsigned int)t23_observations.unused_after);
	dfm_test_check("1023", wait_result == 0, "THREAD_COMPLETED");
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
	dfm_test_check("1023",
		(t23_observations.stack_measure_before == 0) &&
		(t23_observations.stack_measure_after == 0) &&
		(t23_observations.unused_after > 0U),
		"STACK_GUARD_INTACT");
	dfm_test_check("1023",
		t23_observations.checksum_after == t23_observations.checksum_before,
		"LIVE_STACK_DATA_INTACT");

	passed = (wait_result == 0) && t23_observations.returned &&
		(t23_observations.psplim_before != 0U) &&
		(t23_observations.psplim_after == t23_observations.psplim_before) &&
		(t23_observations.psp_before > t23_observations.psplim_before) &&
		(headroom_before >= T23_MIN_HEADROOM) &&
		(headroom_before <= T23_MAX_HEADROOM) &&
		(t23_observations.stack_measure_before == 0) &&
		(t23_observations.stack_measure_after == 0) &&
		(t23_observations.unused_after > 0U) &&
		(t23_observations.checksum_after ==
		 t23_observations.checksum_before);
	return passed ? 0 : -1;
}

#endif /* DFM_TEST_VARIANT_ID == 7 */
