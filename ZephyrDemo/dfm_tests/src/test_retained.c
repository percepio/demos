#include "dfm_tests.h"
#include "test_internal.h"

#include <dfm.h>

#if defined(CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY)
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/drivers/retained_mem.h>

#define DFM_TEST_RETENTION_NODE DT_NODELABEL(retention0)
#define DFM_TEST_RETAINED_MEMORY_NODE DT_PARENT(DFM_TEST_RETENTION_NODE)
#define DFM_TEST_RETENTION_DATA_OFFSET \
	(DT_PROP_BY_IDX(DFM_TEST_RETENTION_NODE, reg, 0) + \
	 DT_PROP_LEN(DFM_TEST_RETENTION_NODE, prefix))

static const struct device *retained_memory =
	DEVICE_DT_GET(DFM_TEST_RETAINED_MEMORY_NODE);
#endif

uint32_t dfm_tests_prepare_retained_boot(void)
{
#if defined(CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY)
	struct dfm_test_state_snapshot state;
	uint8_t byte;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_EXPECT_DFM_REBOOT)) {
		return 0U;
	}

	if (state.armed_test == 1028U) {
		/* Corrupt alert data, not the prefix, so HasData() must reject the
		 * retained alert because its SUM32 no longer matches.
		 */
		bool changed = device_is_ready(retained_memory) &&
			(retained_mem_read(retained_memory,
				DFM_TEST_RETENTION_DATA_OFFSET,
				&byte, sizeof(byte)) == 0);

		if (changed) {
			byte ^= UINT8_C(0x80);
			changed = retained_mem_write(retained_memory,
				DFM_TEST_RETENTION_DATA_OFFSET,
				&byte, sizeof(byte)) == 0;
		}
		dfm_test_check("1028", changed, "CORRUPTION_INJECTED");
		return 1028U;
	}

	if (state.armed_test == 1029U) {
		return 1029U;
	}
#endif

	return 0U;
}

int dfm_test_run_t28(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1028, "Test 1028", 1);
	return -1;
}

int dfm_test_run_t29(const char *test_id)
{
	ARG_UNUSED(test_id);
	DFM_TRAP(1029, "Test 1029", 1);
	return -1;
}

int dfm_test_run_t30(const char *test_id)
{
	traceResult result;

	ARG_UNUSED(test_id);
	result = xTraceDisable();
	dfm_test_check("1030", result == TRC_SUCCESS, "TRACE_DISABLED");
	DFM_TRAP(1030, "Test 1030", 1);
	return -1;
}
