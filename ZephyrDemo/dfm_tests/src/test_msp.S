/* Run one C trap site in privileged Thread mode using MSP, then restore PSP. */

	.syntax unified
	.thumb
	.text
	.align 2
	.global dfm_test_t16_run_on_msp
	.type dfm_test_t16_run_on_msp, %function
	.thumb_func
dfm_test_t16_run_on_msp:
	/* Save the caller context on PSP before changing CONTROL.SPSEL. */
	push {r4-r7, lr}
	mrs r4, control
	mrs r5, msp
#if defined(CONFIG_CPU_CORTEX_M_HAS_SPLIM)
	/* Armv8-M guards Zephyr's interrupt stack with MSPLIM. Re-target the
	 * guard before selecting the isolated test stack, otherwise the first
	 * push in the trap site raises STKOF before DFM is reached.
	 */
	mrs r6, msplim
	msr msplim, r1
	isb
#endif
	msr msp, r0
	bic r7, r4, #2
	msr control, r7
	isb

	bl dfm_test_t16_trap_site

	/* Selecting PSP changes the active stack before the final pop. */
	msr control, r4
	isb
	msr msp, r5
#if defined(CONFIG_CPU_CORTEX_M_HAS_SPLIM)
	msr msplim, r6
	isb
#endif
	pop {r4-r7, pc}
	.size dfm_test_t16_run_on_msp, .-dfm_test_t16_run_on_msp
