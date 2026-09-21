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
	DFM_TRAP(1001, "Test 1001: GDB bt trap_site, service, public_api", 0);
#elif DFM_TEST_VARIANT_ID == 2
	DFM_TRAP(1013, "Test 1013: GDB bt call chain in -Og build", 0);
#elif DFM_TEST_VARIANT_ID == 6
	DFM_TRAP(1024, "Test 1024: GDB bt call chain; stack limit 128", 0);
#else
	DFM_TRAP(1014, "Test 1014: GDB bt call chain in -Os build", 0);
#endif
	call_chain_sink = local_sum ^ local_xor;
	return call_chain_sink;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t01_service(uint32_t arg0, uint32_t arg1, uint32_t arg2,
	uint32_t arg3, uint32_t arg4, uint32_t arg5)
{
	volatile uint32_t service_sentinel = UINT32_C(10);
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
	volatile uint32_t api_sentinel = UINT32_C(100);
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
		DFM_REFERENCE_TRACE_ID " ARGS a0=%u",
		(TraceUnsignedBaseType_t)UINT32_C(1));
	(void)xTracePrintF(dfm_test_trace_channel(),
		DFM_REFERENCE_TRACE_ID " ARGS a5=%u",
		(TraceUnsignedBaseType_t)UINT32_C(6));
	uint32_t result = dfm_t01_public_api(
		UINT32_C(1), UINT32_C(2), UINT32_C(3),
		UINT32_C(4), UINT32_C(5), UINT32_C(6));

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
	volatile uint32_t leaf_sentinel = UINT32_C(100);

	DFM_TRAP(1002, "Test 1002: GDB bt trap_leaf and public_api", 0);
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
		.tag = UINT32_C(10),
		.count = UINT16_C(20),
		.enabled = 1U,
	};
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1002 ARGS mode=%u",
		(TraceUnsignedBaseType_t)T02_MODE_FAULT);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1002 ARGS scalar=%u",
		(TraceUnsignedBaseType_t)UINT32_C(30));
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 DATA name=t02-name");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1002 DATA tag=10");
	(void)xTracePrint(dfm_test_trace_channel(), "T1002 DATA count=20");
	(void)xTracePrint(dfm_test_trace_channel(), "T1002 DATA enabled=1");
	uint32_t result = dfm_t02_public_api(T02_MODE_FAULT,
		UINT32_C(30), "t02-name", &payload);

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
	DFM_TRAP(1003, "Test 1003: GDB r0-r3; bt trap_at_entry", 0);
	call_chain_sink = r0_value ^ r1_value ^ r2_value ^ r3_value;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t03_test_thread(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r0=10");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r1=20");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r2=30");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 ARGS r3=40");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1003 PATH test_thread -> trap_at_entry");
	dfm_t03_trap_at_entry(UINT32_C(10), UINT32_C(20), UINT32_C(30),
		UINT32_C(40));
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

	DFM_TRAP(1004, "Test 1004: GDB bt trap_before_return, caller", 0);
	return return_value;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static int dfm_t04_caller(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1004 DATA input=4000");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1004 DATA expected_return=4404");
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
		"Test 1007A: GDB bt left path",
		UINT32_C(70));
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t07_right_inner(void)
{
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1007B PATH right_inner -> shared_error_handler");
	dfm_t07_shared_error_handler(
		"Test 1007B: GDB bt right path",
		UINT32_C(71));
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
	DFM_TRAP(1011, "Test 1011: GDB bt callback to trap_site", 0);
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
		"T1011 DATA callback value=%u",
		(TraceUnsignedBaseType_t)value);
	callback(value);
	call_chain_sink++;
}

DFM_TEST_NOINLINE DFM_TEST_USED
static void dfm_t11_test_thread(void)
{
	t11_runtime_callback = dfm_t11_callback_handler;
	dfm_t11_dispatcher(UINT32_C(11));
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
	volatile uint32_t trap_sentinel = UINT32_C(100);

	DFM_TRAP(1012, "Test 1012: GDB bt six_args frame chain", 0);
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
		"T1012 ARGS scalar=%u",
		(TraceUnsignedBaseType_t)scalar);
	(void)xTracePrintF(dfm_test_trace_channel(),
		"T1012 ARGS small=%u",
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

	large_frame[0] = UINT32_C(1);
	large_frame[23] = UINT32_C(24);
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1012 DATA wide=5000000000");
	(void)xTracePrint(dfm_test_trace_channel(),
		"T1012 PATH large_frame -> six_args");
	return dfm_t12_six_args(UINT32_C(10), UINT64_C(5000000000), record,
		"t12-text", UINT16_C(20), pointer) + large_frame[0] +
		large_frame[23];
}

DFM_TEST_NOINLINE DFM_TEST_USED
static uint32_t dfm_t12_small_frame(const struct t12_record *record,
	const uint32_t *pointer)
{
	volatile uint32_t small_sentinel = UINT32_C(200);
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
		.tag = UINT32_C(30),
		.values = { UINT32_C(1), UINT32_C(2), UINT32_C(3) },
	};
	static const uint32_t pointed_value = UINT32_C(40);
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
