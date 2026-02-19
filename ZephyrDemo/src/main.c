
#include "dfmStopwatch.h"
#include "zephyr/linker/section_tags.h"
#include <zephyr/kernel.h>

#if defined(CONFIG_STDOUT_CONSOLE)
#include <stdio.h>
#else
#include <zephyr/sys/printk.h>
#endif

#include <zephyr/sys/__assert.h>

#include "dfm.h"

#include "demo_app.h"

/* NOTE: This demo application of Percepio Detect for Zephyr is a work-in-progress,
  and assumes updated versions of the Percepio modules TraceRecorder and DFM found in "modules-staging".*/  

int main(void)
{

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
