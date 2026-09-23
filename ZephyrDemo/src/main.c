#define RUN_TESTS_ONLY 1

#include "zephyr/linker/section_tags.h"
#include <zephyr/kernel.h>
#include <zephyr/sys/__assert.h>
#include <zephyr/fatal.h>
#include <zephyr/sys/reboot.h>

#if defined(CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY)
#include <dfm.h>
#endif

#if defined(CONFIG_STDOUT_CONSOLE)
#include <stdio.h>
#else
#include <zephyr/sys/printk.h>
#endif

#if RUN_TESTS_ONLY
#include "dfm_tests.h"
#else
#include "demo_app.h"
#endif

/*
  
  NOTE: This demo application of Percepio Detect for Zephyr is a work-in-progress,
  and assumes updated versions of the Percepio modules TraceRecorder and DFM found in "modules-staging".*/  

int main(void){

#if CONFIG_TIMESLICING
	k_sched_time_slice_set(5000, 0);
#endif

	/* Give the host time to reopen the USB/UART console after flashing or a
	 * target reset before emitting the identity marker and test output.
	 */
	k_sleep(K_SECONDS(1));

#if defined(CONFIG_PERCEPIO_DFM_CFG_RETAINED_MEMORY)
	uint32_t expected_invalid_test = 0U;
	uint32_t has_retained_data;

#if RUN_TESTS_ONLY
	expected_invalid_test = dfm_tests_prepare_retained_boot();
#endif
	has_retained_data = xDfmRetainedMemoryPortHasData();
	if (expected_invalid_test != 0U) {
		const char *condition = expected_invalid_test == 1028U ?
			"CORRUPTION_REJECTED" : "INCOMPLETE_ALERT_REJECTED";

		printk("DFMT:CHECK:%u:%s:%s\n", expected_invalid_test,
			has_retained_data == 0U ? "PASS" : "FAIL", condition);
		if ((has_retained_data != 0U) ||
		    (xDfmRetainedMemoryPortClear() != DFM_SUCCESS)) {
			return -1;
		}
	} else if (has_retained_data == 1U) {
		printk("DFMT:RETAINED_ALERT:FOUND\n");
		if (xDfmAlertSendAll() != DFM_SUCCESS) {
			printk("DFMT:HARNESS_FAIL:RETAINED:SEND_ALL\n");
			return -1;
		}
		if (xDfmRetainedMemoryPortHasData() != 0U) {
			printk("DFMT:HARNESS_FAIL:RETAINED:NOT_CLEARED\n");
			return -1;
		}
		printk("DFMT:RETAINED_ALERT:SENT\n");
	}
#endif

#if RUN_TESTS_ONLY
	printk("Starting Percepio Detect test\n");
	return run_tests();
#else
	printk("Starting Percepio Detect demo\n");
	demo_app();

	return 0;
#endif
}


#if !RUN_TESTS_ONLY
__noinit unsigned int last_demo_counter;

unsigned int selectNextDemo(void)
{	
  if (last_demo_counter >= NUMBER_OF_DEMOS) 
	{	
    last_demo_counter = 0;		
	}
	  	
	return last_demo_counter++;
}
#endif


/* Called by Zephyr as the final step in the fault handling, after DFM has
  stored its' alert with TraceRecorder diagnostics etc. In this demo we just
  restart at this point, but you may use this to add custom fault handling
  actions that execute after DFM. */

void k_sys_fatal_error_handler(unsigned int reason, const struct arch_esf *esf)
{	
    ARG_UNUSED(esf);

#if RUN_TESTS_ONLY
    dfm_tests_record_fatal(reason);
#else
    ARG_UNUSED(reason);
#endif

    printk("Fatal error, rebooting...\n");
    k_busy_wait(1000);   /* Let final UART chars drain before rebooting. */

    sys_reboot(SYS_REBOOT_COLD);

    CODE_UNREACHABLE;
}
