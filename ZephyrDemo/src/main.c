#include "zephyr/linker/section_tags.h"
#include <zephyr/kernel.h>
#include <zephyr/sys/__assert.h>
#include <zephyr/fatal.h>
#include <zephyr/sys/reboot.h>

#if defined(CONFIG_STDOUT_CONSOLE)
#include <stdio.h>
#else
#include <zephyr/sys/printk.h>
#endif

#include "demo_app.h"

/* NOTE: This demo application of Percepio Detect for Zephyr is a work-in-progress,
  and assumes updated versions of the Percepio modules TraceRecorder and DFM found in "modules-staging".*/  

int main(void){

#if CONFIG_TIMESLICING
	k_sched_time_slice_set(5000, 0);
#endif

	demo_app();

	return 0;
}


__noinit unsigned int next_demo_counter = 0;

unsigned int selectNextDemo(void)
{	
	if (next_demo_counter >= NUMBER_OF_DEMOS) 
	{
		next_demo_counter = 0;	
		return next_demo_counter;
	}
	
	next_demo_counter = (next_demo_counter + 1) % NUMBER_OF_DEMOS;

	return next_demo_counter;
}


/* Called by Zephyr as the final step in the fault handling, after DFM has
  stored its' alert with TraceRecorder diagnostics etc. In this demo we just
  restart at this point, but you may use this to add custom fault handling
  actions that execute after DFM. */

void k_sys_fatal_error_handler(unsigned int reason, const struct arch_esf *esf)
{	
    ARG_UNUSED(reason);
    ARG_UNUSED(esf);

    printk("Fatal error, rebooting...\n");
    k_busy_wait(1000);   /* Let final UART chars drain before rebooting. */

    sys_reboot(SYS_REBOOT_COLD);

    CODE_UNREACHABLE;
}