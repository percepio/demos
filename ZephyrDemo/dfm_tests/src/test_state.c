#include "test_internal.h"

#include <zephyr/irq.h>
#include <zephyr/linker/section_tags.h>

#define DFM_TEST_STATE_MAGIC UINT32_C(0x4454464d) /* "DTFM" */
#define DFM_TEST_STATE_VERSION UINT32_C(4)
#define DFM_TEST_STATE_SALT UINT32_C(0xa93c71e5)
#define DFM_TEST_BUILD_COOKIE \
	(DFM_TEST_STATE_MAGIC ^ ((uint32_t)DFM_TEST_VARIANT_ID << 16) ^ \
	 ((uint32_t)DFM_TEST_CASE_ID << 1) ^ DFM_TEST_STATE_VERSION ^ \
	 (uint32_t)DFM_TEST_RUN_COOKIE)

struct dfm_test_persistent_state {
	uint32_t magic;
	uint32_t version;
	uint32_t build_cookie;
	uint32_t run_id;
	uint32_t next_index;
	uint32_t armed_test;
	uint32_t phase;
	uint32_t reboot_count;
	uint32_t observation_a;
	uint32_t observation_b;
	uint32_t checksum;
};

static __noinit volatile struct dfm_test_persistent_state persistent_state;

static uint32_t state_checksum(const struct dfm_test_persistent_state *state)
{
	return DFM_TEST_STATE_SALT ^ state->magic ^ state->version ^
		state->build_cookie ^ state->run_id ^ state->next_index ^
		state->armed_test ^ state->phase ^ state->reboot_count ^
		state->observation_a ^ state->observation_b;
}

static void copy_from_volatile(struct dfm_test_persistent_state *destination)
{
	destination->magic = persistent_state.magic;
	destination->version = persistent_state.version;
	destination->build_cookie = persistent_state.build_cookie;
	destination->run_id = persistent_state.run_id;
	destination->next_index = persistent_state.next_index;
	destination->armed_test = persistent_state.armed_test;
	destination->phase = persistent_state.phase;
	destination->reboot_count = persistent_state.reboot_count;
	destination->observation_a = persistent_state.observation_a;
	destination->observation_b = persistent_state.observation_b;
	destination->checksum = persistent_state.checksum;
}

static bool raw_state_is_valid(const struct dfm_test_persistent_state *state)
{
	if ((state->magic != DFM_TEST_STATE_MAGIC) ||
	    (state->version != DFM_TEST_STATE_VERSION) ||
	    (state->build_cookie != DFM_TEST_BUILD_COOKIE)) {
		return false;
	}

	if ((state->phase < DFM_TEST_PHASE_READY) ||
	    (state->phase > DFM_TEST_PHASE_COMPLETE)) {
		return false;
	}

	return state->checksum == state_checksum(state);
}

bool dfm_test_state_load(struct dfm_test_state_snapshot *snapshot)
{
	struct dfm_test_persistent_state state;

	copy_from_volatile(&state);
	if (!raw_state_is_valid(&state)) {
		return false;
	}

	snapshot->run_id = state.run_id;
	snapshot->next_index = state.next_index;
	snapshot->armed_test = state.armed_test;
	snapshot->phase = state.phase;
	snapshot->reboot_count = state.reboot_count;
	snapshot->observation_a = state.observation_a;
	snapshot->observation_b = state.observation_b;
	return true;
}

void dfm_test_state_commit(const struct dfm_test_state_snapshot *snapshot)
{
	struct dfm_test_persistent_state next = {
		.magic = DFM_TEST_STATE_MAGIC,
		.version = DFM_TEST_STATE_VERSION,
		.build_cookie = DFM_TEST_BUILD_COOKIE,
		.run_id = snapshot->run_id,
		.next_index = snapshot->next_index,
		.armed_test = snapshot->armed_test,
		.phase = snapshot->phase,
		.reboot_count = snapshot->reboot_count,
		.observation_a = snapshot->observation_a,
		.observation_b = snapshot->observation_b,
	};
	unsigned int key;

	next.checksum = state_checksum(&next);
	key = irq_lock();
	/* Invalidate first. The checksum is the commit marker and is written last. */
	persistent_state.checksum = 0U;
	persistent_state.magic = next.magic;
	persistent_state.version = next.version;
	persistent_state.build_cookie = next.build_cookie;
	persistent_state.run_id = next.run_id;
	persistent_state.next_index = next.next_index;
	persistent_state.armed_test = next.armed_test;
	persistent_state.phase = next.phase;
	persistent_state.reboot_count = next.reboot_count;
	persistent_state.observation_a = next.observation_a;
	persistent_state.observation_b = next.observation_b;
	__asm__ volatile("" ::: "memory");
	persistent_state.checksum = next.checksum;
	irq_unlock(key);
}

void dfm_test_state_initialize(uint32_t run_id)
{
	const struct dfm_test_state_snapshot initial = {
		.run_id = run_id,
		.next_index = 0U,
		.phase = DFM_TEST_PHASE_READY,
	};

	dfm_test_state_commit(&initial);
}

void dfm_test_state_mark_startup_running(uint32_t numeric_id)
{
	struct dfm_test_state_snapshot state;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_ARMED) ||
	    (state.armed_test != numeric_id)) {
		return;
	}

	state.phase = DFM_TEST_PHASE_STARTUP_RUNNING;
	dfm_test_state_commit(&state);
}

void dfm_test_state_mark_startup_done(uint32_t numeric_id,
	uint32_t observation_a, uint32_t observation_b)
{
	struct dfm_test_state_snapshot state;

	if (!dfm_test_state_load(&state) ||
	    (state.phase != DFM_TEST_PHASE_STARTUP_RUNNING) ||
	    (state.armed_test != numeric_id)) {
		return;
	}

	state.observation_a = observation_a;
	state.observation_b = observation_b;
	state.phase = DFM_TEST_PHASE_STARTUP_DONE;
	dfm_test_state_commit(&state);
}
