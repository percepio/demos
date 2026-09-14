#include "test_internal.h"

#include <dfm.h>
#include <trcRecorder.h>

static volatile uint32_t call_chain_sink;

#if DFM_TEST_VARIANT_ID == 1
#define DFM_REFERENCE_TRACE_ID "T1001"
#elif DFM_TEST_VARIANT_ID == 2
#define DFM_REFERENCE_TRACE_ID "T1013"
#elif DFM_TEST_VARIANT_ID == 6
#define DFM_REFERENCE_TRACE_ID "T1024"
#else
#define DFM_REFERENCE_TRACE_ID "T1014"
#endif

DFM_TEST_NOINLINE DFM_TEST_USED
uint32_t dfm_t01_trap_site(uint32_t arg0, uint32_t arg1, uint32_t arg2,
	uint32_t arg3, uint32_t arg4, uint32_t arg5)
{
	volatile uint32_t local_sum = arg0 + arg1 + arg2 + arg3 + arg4 + arg5;
	volatile uint32_t local_xor = arg0 ^ arg2 ^ arg4;

#if DFM_TEST_VARIANT_ID == 1
	DFM_TRAP(1001, "Test 1001: Expected: GDB bt trap_site, service, public_api", 0);
#elif DFM_TEST_VARIANT_ID == 2
	DFM_TRAP(1013, "Test 1013: Expected: GDB bt call chain in -Og build", 0);
#elif DFM_TEST_VARIANT_ID == 6
	DFM_TRAP(1024, "Test 1024: Expected: GDB bt omits test_thread; stack limit 128", 0);
#else
	DFM_TRAP(1014, "Test 1014: Expected: GDB bt call chain in -Os build", 0);
#endif
	call_chain_sink = local_sum ^ local_xor;
	return call_chain_sink;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t01_service(uint32_t arg0, uint32_t arg1, uint32_t arg2,
	uint32_t arg3, uint32_t arg4, uint32_t arg5)
{
	volatile uint32_t service_sentinel = UINT32_C(0x51a7e001);
	(void)xTracePrint(dfm_test_trace_channel(),
		DFM_REFERENCE_TRACE_ID " PATH service -> trap_site");
	uint32_t result = dfm_t01_trap_site(arg0, arg1, arg2, arg3, arg4, arg5);

	call_chain_sink ^= service_sentinel;
	return result + service_sentinel;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t01_public_api(uint32_t arg0, uint32_t arg1,
	uint32_t arg2, uint32_t arg3, uint32_t arg4, uint32_t arg5)
{
	volatile uint32_t api_sentinel = UINT32_C(0xa91c0002);
	(void)xTracePrint(dfm_test_trace_channel(),
		DFM_REFERENCE_TRACE_ID " PATH public_api -> service");
	uint32_t result = dfm_t01_service(arg0, arg1, arg2, arg3, arg4, arg5);

	call_chain_sink += api_sentinel;
	return result ^ api_sentinel;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t01_test_thread(void)
{
	(void)xTracePrintF(dfm_test_trace_channel(),
		DFM_REFERENCE_TRACE_ID " ARGS a0=%08X a5=%08X",
		(TraceUnsignedBaseType_t)UINT32_C(0x11111111),
		(TraceUnsignedBaseType_t)UINT32_C(0x66666666));
	uint32_t result = dfm_t01_public_api(
		UINT32_C(0x11111111), UINT32_C(0x22222222),
		UINT32_C(0x33333333), UINT32_C(0x44444444),
		UINT32_C(0x55555555), UINT32_C(0x66666666));

	call_chain_sink ^= result;
	return result;
}

int dfm_test_run_reference(const char *test_id)
{
	ARG_UNUSED(test_id);
	(void)dfm_t01_test_thread();
	return 0;
}

enum t02_mode {
	T02_MODE_FAULT = 7,
};

struct t02_payload {
	uint32_t tag;
	uint16_t count;
	uint8_t enabled;
};

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t02_trap_leaf(enum t02_mode mode, uint32_t scalar,
	const char *name, const struct t02_payload *payload)
{
	volatile uint32_t leaf_sentinel = UINT32_C(0x02ea7001);

	DFM_TRAP(1002, "Test 1002: Expected: GDB bt trap_leaf and public_api", 0);
	call_chain_sink = scalar ^ payload->tag ^ (uint32_t)mode ^
		(uint32_t)(unsigned char)name[0] ^ leaf_sentinel;
	return call_chain_sink;
}

static inline __attribute__((always_inline))
uint32_t dfm_t02_inline_wrapper(enum t02_mode mode, uint32_t scalar,
	const char *name, const struct t02_payload *payload)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 PATH inline_wrapper -> trap_leaf");
	return dfm_t02_trap_leaf(mode, scalar, name, payload);
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t02_public_api(enum t02_mode mode, uint32_t scalar,
	const char *name, const struct t02_payload *payload)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 PATH public_api -> inline_wrapper");
	uint32_t result = dfm_t02_inline_wrapper(mode, scalar, name, payload);

	call_chain_sink += result;
	return result;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t02_test_thread(void)
{
	static const struct t02_payload payload = {
		.tag = UINT32_C(0x02c0ffee),
		.count = UINT16_C(0x2233),
		.enabled = 1U,
	};
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1002 ARGS mode=%u scalar=%08X",
		(TraceUnsignedBaseType_t)T02_MODE_FAULT,
		(TraceUnsignedBaseType_t)UINT32_C(0x02020202));
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 DATA name=t02-name tag=02C0FFEE");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 DATA count=2233 enabled=1");
	uint32_t result = dfm_t02_public_api(T02_MODE_FAULT,
		UINT32_C(0x02020202), "t02-name", &payload);

	call_chain_sink ^= result;
	return result;
}

int dfm_test_run_t02(const char *test_id)
{
	ARG_UNUSED(test_id);
	(void)dfm_t02_test_thread();
	return 0;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t03_trap_at_entry(uint32_t r0_value, uint32_t r1_value,
	uint32_t r2_value, uint32_t r3_value)
{
	DFM_TRAP(1003, "Test 1003: Expected: GDB regs r0-r3; bt trap_at_entry", 0);
	call_chain_sink = r0_value ^ r1_value ^ r2_value ^ r3_value;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t03_test_thread(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r0=03030300 r1=03030301");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r2=03030302 r3=03030303");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 PATH test_thread -> trap_at_entry");
	dfm_t03_trap_at_entry(UINT32_C(0x03030300), UINT32_C(0x03030301),
		UINT32_C(0x03030302), UINT32_C(0x03030303));
	call_chain_sink++;
}

int dfm_test_run_t03(const char *test_id)
{
	ARG_UNUSED(test_id);
	dfm_t03_test_thread();
	return 0;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static int dfm_t04_trap_before_return(int value)
{
	volatile int return_value = value + 404;

	DFM_TRAP(1004, "Test 1004: Expected: GDB bt trap_before_return and caller", 0);
	return return_value;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static int dfm_t04_caller(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1004 DATA input=4000 expected_return=4404");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1004 PATH caller -> trap_before_return");
	int result = dfm_t04_trap_before_return(4000);

	call_chain_sink = (uint32_t)result;
	return result;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static int dfm_t04_test_thread(void)
{
	int result = dfm_t04_caller();

	call_chain_sink ^= (uint32_t)result;
	return result;
}

int dfm_test_run_t04(const char *test_id)
{
	int result;

	ARG_UNUSED(test_id);
	result = dfm_t04_test_thread();
	dfm_test_check("1004", result == 4404, "CALLER_CONTINUED_ONCE");
	return result == 4404 ? 0 : -1;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t07_shared_error_handler(const char *message,
	uint32_t path_sentinel)
{
	volatile uint32_t handler_sentinel = path_sentinel;

	DFM_TRAP(1007, message, 0);
	call_chain_sink ^= handler_sentinel;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t07_left_path(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1007A PATH left_path -> shared_error_handler");
	dfm_t07_shared_error_handler(
		"Test 1007A: Expected: GDB bt left path; trace T1007A",
		UINT32_C(0x07aaa001));
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t07_right_inner(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1007B PATH right_inner -> shared_error_handler");
	dfm_t07_shared_error_handler(
		"Test 1007B: Expected: GDB bt right path; trace T1007B",
		UINT32_C(0x07bbb002));
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t07_right_path(void)
{
	dfm_t07_right_inner();
	call_chain_sink++;
}

int dfm_test_run_t07(const char *test_id)
{
	ARG_UNUSED(test_id);
	dfm_t07_left_path();
	dfm_test_check("1007A", xTraceIsRecorderEnabled(), "TRACE_RESUMED");
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1007A returned trace_enabled=%u",
		(TraceUnsignedBaseType_t)xTraceIsRecorderEnabled());
	dfm_t07_right_path();
	dfm_test_check("1007B", xTraceIsRecorderEnabled(), "TRACE_RESUMED");
	return 0;
}

typedef void (*t11_callback_t)(uint32_t value);
static t11_callback_t volatile t11_runtime_callback;

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t11_trap_site(uint32_t value)
{
	DFM_TRAP(1011, "Test 1011: Expected: GDB bt callback path to trap_site", 0);
	call_chain_sink = value;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t11_callback_handler(uint32_t value)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1011 PATH callback_handler -> trap_site");
	dfm_t11_trap_site(value);
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t11_dispatcher(uint32_t value)
{
	t11_callback_t callback = t11_runtime_callback;

	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1011 DATA callback value=%08X",
		(TraceUnsignedBaseType_t)value);
	callback(value);
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t11_test_thread(void)
{
	t11_runtime_callback = dfm_t11_callback_handler;
	dfm_t11_dispatcher(UINT32_C(0x1111cafe));
	call_chain_sink++;
}

int dfm_test_run_t11(const char *test_id)
{
	ARG_UNUSED(test_id);
	dfm_t11_test_thread();
	return 0;
}

struct t12_record {
	uint32_t tag;
	uint32_t values[3];
};

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_trap_site(uint32_t scalar, uint64_t wide,
	const struct t12_record *record, const char *text, uint16_t small,
	const uint32_t *pointer)
{
	volatile uint32_t trap_sentinel = UINT32_C(0x12feed01);

	DFM_TRAP(1012, "Test 1012: Expected: GDB bt six_args and frame chain", 0);
	call_chain_sink = scalar ^ (uint32_t)wide ^ (uint32_t)(wide >> 32) ^
		record->tag ^ (uint32_t)(unsigned char)text[0] ^ small ^ *pointer ^
		trap_sentinel;
	return call_chain_sink;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_six_args(uint32_t scalar, uint64_t wide,
	const struct t12_record *record, const char *text, uint16_t small,
	const uint32_t *pointer)
{
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1012 ARGS scalar=%08X small=%04X",
		(TraceUnsignedBaseType_t)scalar,
		(TraceUnsignedBaseType_t)small);
	uint32_t result = dfm_t12_trap_site(scalar, wide, record, text, small,
		pointer);

	call_chain_sink ^= result;
	return result;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_large_frame(const struct t12_record *record,
	const uint32_t *pointer)
{
	volatile uint32_t large_frame[24];

	large_frame[0] = UINT32_C(0x12000000);
	large_frame[23] = UINT32_C(0x12000017);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1012 DATA wide=1234567887654321");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1012 PATH large_frame -> six_args");
	return dfm_t12_six_args(UINT32_C(0x12121212),
		UINT64_C(0x1234567887654321), record, "t12-text",
		UINT16_C(0x12ab), pointer) + large_frame[0] + large_frame[23];
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_small_frame(const struct t12_record *record,
	const uint32_t *pointer)
{
	volatile uint32_t small_sentinel = UINT32_C(0x12abc002);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1012 PATH small_frame -> large_frame");
	uint32_t result = dfm_t12_large_frame(record, pointer);

	call_chain_sink ^= small_sentinel;
	return result + small_sentinel;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_test_thread(void)
{
	static const struct t12_record record = {
		.tag = UINT32_C(0x12c0ffee),
		.values = { UINT32_C(0x1201), UINT32_C(0x1202), UINT32_C(0x1203) },
	};
	static const uint32_t pointed_value = UINT32_C(0x12d00d12);
	uint32_t result = dfm_t12_small_frame(&record, &pointed_value);

	call_chain_sink += result;
	return result;
}

int dfm_test_run_t12(const char *test_id)
{
	ARG_UNUSED(test_id);
	(void)dfm_t12_test_thread();
	return 0;
}
