/*
 * Work around the qemu_cortex_m3 software-reboot path when building with
 * -O0/-Og and CONFIG_INIT_STACKS=y.
 *
 * The LM3S6965 QEMU model cannot reset through SYSRESETREQ. Zephyr therefore
 * leaves Handler mode through a synthetic exception frame and enters the
 * reset code with PSP temporarily located inside z_interrupt_stacks. The
 * default weak arch_early_memset() gets a stack frame at -O0/-Og; clearing
 * z_interrupt_stacks then overwrites that frame and returns to 0xAAAAAAAA.
 *
 * This strong, stackless implementation replaces the weak default only for
 * the affected QEMU target and debug optimization modes.
 */

#include <stddef.h>

#if defined(CONFIG_SOC_TI_LM3S6965_QEMU) && \
	(defined(CONFIG_NO_OPTIMIZATIONS) || defined(CONFIG_DEBUG_OPTIMIZATIONS))

__attribute__((naked, no_stack_protector))
void arch_early_memset(void *dst __attribute__((unused)),
		       int value __attribute__((unused)),
		       size_t size __attribute__((unused)))
{
	__asm__ volatile(
		"cmp r2, #0\n"
		"beq 2f\n"
		"1:\n"
		"strb r1, [r0]\n"
		"adds r0, r0, #1\n"
		"subs r2, r2, #1\n"
		"bne 1b\n"
		"2:\n"
		"bx lr\n");
}

#endif
