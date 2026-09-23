# FreeRTOS DFM Test Cases

This is the payload-review oracle for the QEMU/Cortex-M3 FreeRTOS suite. The
host harness validates build completion, target markers, alert multiplicity,
description length, and CRC16. A payload PASS additionally requires the
evidence below.

## Common environment

All current cases run on QEMU `mps2-an385` with the GCC ARM Cortex-M3 port,
FreeRTOS, DFM, CrashCatcher, and TraceRecorder 4.11.0 with the RingBuffer
stream port. `DFM_TRAP()` coredumps are named `trap.dmp`; dumps emitted from
`DFM_Fault_Handler` are named `fault.dmp`. Unless a case explicitly disables
one, an alert must contain its named CrashCatcher dump and a TraceRecorder
payload, must use the build revision recorded below, and execution must either
return normally or perform the stated reset.

Each emitted test alert message is exactly `Test <test-id>` or, for a
multi-alert case, `Test <test-id><suffix>`. DFM appends
` at <source-file>:<line>`. The resulting metadata description and `[ALERT]`
event must match and contain fewer than 50 characters; neither may be
truncated. Test behavior belongs in this oracle and in `[DFM Tests]` events,
not in the alert message.

For every event-log artifact, inventory every `[DFM Tests]` row, not only the
`[ALERT]` row. Against the allowlisted source and the test section below,
verify all current-test rows that should exist at that alert's capture point,
including complete formatted values, multiplicity, and order. For a two-alert
case, treat the event logs as cumulative snapshots. Account for earlier test
IDs as retained ring-buffer history before the current test window; they may
not replace current-test evidence or contradict its ordering.

The build profiles are:

- `Build-M3-O0`: `m3_o0`, whole image `-O0`.
- `Build-M3-Og`: `m3_og`, whole image `-Og`.
- `Build-M3-Os`: `m3_os`, whole image `-Os`.
- `Build-M3-NoCD`: `m3_no_coredump`, `-Os`, coredumps disabled.
- `Build-M3-SmallCD`: `m3_small_coredump`, `-Os`, 128-byte dump buffer.
- `Build-M3-Stack128`: `m3_stack128`, `-O0`, 128-byte captured stack range.

### Test 1001 — Unoptimized reference chain

- Build: `Build-M3-O0`; one type-1001 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, normal return, and a usable unwind through
  `dfm_t01_trap_site`, `dfm_t01_service`, `dfm_t01_public_api`, and
  `dfm_t01_test_thread`.
- Confirm the six arguments `1` through `6`, `local_sum=21`, and
  `local_xor=7`.

### Test 1002 — Optimized inline and noinline chain

- Build: `Build-M3-Os`; one type-1002 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, and normal return. The unwind must retain
  `dfm_t02_trap_leaf` and `dfm_t02_public_api`; the always-inline wrapper need
  not be a physical frame.
- Confirm mode 7, scalar `30`, name `t02-name`, tag `10`, count `20`, and
  enabled 1 from dump or trace evidence.

### Test 1003 — Trap at function entry

- Build: `Build-M3-O0`; one type-1003 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, normal return, a frame for
  `dfm_t03_trap_at_entry`, and entry arguments r0-r3 equal to
  `10`, `20`, `30`, and `40`.

### Test 1004 — Trap before return

- Build: `Build-M3-Os`; one type-1004 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, an unwind through
  `dfm_t04_trap_before_return` and its caller, and target proof that the caller
  continued once with return value 4404.

### Test 1005 — main/Thread mode using MSP

- Build: `Build-M3-Os`; one type-1005 alert produced after DFM and tracing are
  initialized but before the FreeRTOS scheduler starts.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, and an unwind through
  `dfm_test_run_post_init_startup` to `run_tests`. A separate `main` frame is
  not required: the `-Os` build may tail-call `run_tests` from `main`, and the
  unwind may then stop normally at the initial MSP stack boundary. Also require
  target proof `IPSR=0`, `CONTROL.SPSEL=0`, return from the trap, and suite
  continuation after the intentional startup reset.

### Test 1006 — Interrupt/Handler mode using MSP

- Build: `Build-M3-Os`; two type-1006 alerts.
- **Expected payloads:** Each alert contains exactly `trap.dmp` and
  `dfm_trace.psfs`; no other payloads are allowed.
- The first alert must contain `trap.dmp` captured in `DFM_Test_IRQHandler`
  with nonzero IPSR and Handler/MSP context. The second is the post-interrupt
  witness and must prove the ISR and first trap returned.
- Require intact payloads and ordered trace/target evidence for both alerts.

### Test 1007 — Two caller paths and trace resumption

- Build: `Build-M3-Os`; two type-1007 alerts, suffixes A and B.
- **Expected payloads:** Each alert contains exactly `trap.dmp` and
  `dfm_trace.psfs`; no other payloads are allowed.
- Require two valid `trap.dmp` payloads, distinct left and right call chains,
  trace data for both paths, and proof that tracing resumed after each trap.

### Test 1008 — DFM-requested reboot

- Build: `Build-M3-Os`; one type-1008 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require a complete `trap.dmp` and trace payload before reset, a call chain
  through the test function, exactly one expected reset/resume transition, and
  no return from the original `DFM_TRAP(..., restart=1)` call.

### Test 1009 — FreeRTOS timer-daemon chain

- Build: `Build-M3-Os`; one type-1009 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, successful return, and an unwind through
  `dfm_t09_trap_site`, `dfm_t09_service`, and
  `dfm_t09_app_work_handler`, with a valid FreeRTOS timer-daemon root.
- Confirm value `9` and target proof that submission and completion
  both succeeded.

### Test 1010 — Invocation before DFM initialization

- Build: `Build-M3-Os`; zero alerts.
- **Expected payloads:** None; emitting an alert or payload fails this case.
- The pre-initialization `DFM_TRAP` must be a silent no-op. Require target proof
  that it ran in Thread/MSP context, returned, resumed after the startup reset,
  and allowed the suite to complete. Any payload or alert fails the case.

### Test 1011 — Indirect callback chain

- Build: `Build-M3-Os`; one type-1011 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, normal return, and an unwind through
  `dfm_t11_dispatcher`, the runtime callback, and `dfm_t11_trap_site`.
- Confirm callback value `11`.

### Test 1012 — Deep mixed-frame ABI chain

- Build: `Build-M3-O0`; one type-1012 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, normal return, and a usable chain through
  trap site, six-argument function, large frame, small frame, and test entry.
- Confirm scalar `10`, wide value `5000000000`, small value `20`, record/tag
  data, text, and pointed value where exported.

### Test 1013 — Reference chain at debug optimization

- Build: `Build-M3-Og`; one type-1013 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Apply the Test 1001 call-chain, argument, `trap.dmp`, trace, and return oracle
  while allowing normal `-Og` frame/variable optimization.

### Test 1014 — Reference chain at size optimization

- Build: `Build-M3-Os`; one type-1014 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Apply the Test 1001 call-chain, argument, `trap.dmp`, trace, and return oracle
  while allowing normal `-Os` inlining and unavailable optimized locals.

### Test 1015 — Compile-time no-coredump fallback

- Build: `Build-M3-NoCD`; one type-1015 alert.
- **Expected payloads:** Exactly `dfm_trace.psfs`, with no `trap.dmp` or
  `fault.dmp`; no other payloads are allowed.
- Require valid alert metadata, a trace payload, and normal return. No
  `trap.dmp` or other coredump payload may be present.

### Test 1016 — Thread mode temporarily using a dedicated MSP

- Build: `Build-M3-Os`; two type-1016 alerts.
- **Expected payloads:** Each alert contains exactly `trap.dmp` and
  `dfm_trace.psfs`; no other payloads are allowed.
- The first must contain `trap.dmp` captured with `IPSR=0` and
  `CONTROL.SPSEL=0` on the dedicated MSP and must return safely.
- The second witness must contain `trap.dmp` and prove PSP restoration
  (`CONTROL.SPSEL=1`), with trace/target checks confirming both transitions.

### Test 1017 — Trace initially stopped

- Build: `Build-M3-Os`; one type-1017 alert.
- **Expected payloads:** Exactly `trap.dmp`, with no `dfm_trace.psfs`; no
  other payloads are allowed. `DFM_CFG_CRASH_ADD_TRACE` remains enabled; the
  trace is absent because the recorder is stopped at runtime.
- Require a valid `trap.dmp`, no TraceRecorder payload for this alert, normal
  return, and target proof that tracing was stopped both before and after the
  trap. The later cleanup restart is not evidence for this alert.

### Test 1018 — Small valid task stack

- Build: `Build-M3-Os`; one type-1018 alert from a static 1536-byte FreeRTOS
  task stack.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, normal task completion, a usable unwind
  including `dfm_t18_small_stack_thread`, and target observations showing
  nonzero stack headroom after return.

### Test 1019 — Short description and recovery

- Build: `Build-M3-Os`; two type-1019 alerts, suffixes A and B.
- **Expected payloads:** Each alert contains exactly `trap.dmp` and
  `dfm_trace.psfs`; no other payloads are allowed.
- Require descriptions `Test 1019A at test_boundaries.c:<line>` and
  `Test 1019B at test_boundaries.c:<line>`, both intact `trap.dmp` and trace
  payloads, and evidence that the first trap returned before the witness alert
  was generated. Across the two event logs, require `T1019 BEGIN`,
  `T1019A MSG chars=10 formatted_max=49`, and then
  `T1019B RETURN first trap completed` in source order.

### Test 1020 — Undersized coredump buffer

- Build: `Build-M3-SmallCD`; two type-1020 alerts, suffixes A and B.
- **Expected payloads:** Each alert contains exactly `dfm_trace.psfs`, with no
  `trap.dmp` or `fault.dmp`; no other payloads are allowed.
- Both alerts must be structurally valid and may contain trace evidence, but no
  partial or complete `trap.dmp` may be emitted because 128 bytes is too small.
- Require proof that the first failure returned safely and the second alert was
  produced.

### Test 1021 — Existing scheduler lock

- Build: `Build-M3-Os`; two type-1021 alerts.
- **Expected payloads:** Each alert contains exactly `trap.dmp` and
  `dfm_trace.psfs`; no other payloads are allowed.
- Require valid `trap.dmp` and trace payloads. The first is taken while an outer
  `vTaskSuspendAll()` is active; the higher-priority task must remain blocked.
- The second witness and target checks must prove the outer lock survived DFM,
  was released by the caller, and the higher-priority task then ran.

### Test 1024 — Deliberate 128-byte stack-capture limit

- Build: `Build-M3-Stack128`; one type-1024 alert.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require a valid `trap.dmp`, trace evidence, and normal return. The dump must
  be limited to 128 stack bytes: inner reference-chain frames should unwind,
  while omission of the outer FreeRTOS test-runner frame is required rather
  than treated as corruption. The application call-chain frames are identical
  to the Zephyr build, but CrashCatcher reconstructs the captured context at
  `dfm_t01_trap_site`; Zephyr starts its coredump inside the DFM trap path.
  CrashCatcher's 128-byte window therefore excludes the internal DFM frames
  and can still contain `dfm_t01_test_thread`.

### Test 1025 — Deliberate HardFault through DFM_Fault_Handler

- Build: `Build-M3-Os`; one serialized DFM alert of numeric type 1025.
- **Expected payloads:** Exactly `fault.dmp` and `dfm_trace.psfs`, with no
  `trap.dmp`; no other payloads are allowed.
- The undefined instruction must enter the real HardFault vector and
  `DFM_Fault_Handler`. Require a complete CrashCatcher payload named
  `fault.dmp`, fault/core registers consistent with an undefined-instruction
  fault, a usable unwind to `dfm_test_run_t25`, and an expected reset/resume to
  the next test. A `trap.dmp` payload fails this case.

### Test 1022 — Active floating-point state

- Build: `Build-M33-Qual`, whole-image `-O0`; one type-1022 alert on
  STM32U585 hardware.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence and normal return. The Cortex-M33 FPU
  context must be active across `DFM_TRAP()`, `FPCCR.ASPEN/LSPEN` must remain
  enabled, and callee-saved `s16` must retain sentinel `100`.
- CrashCatcher must produce readable core registers and a usable unwind to
  `dfm_t22_active_fp_trap`. FP-register values are not guaranteed to be
  exposed by Detect/GDB and their absence does not fail the test; the
  target-side `s16` check is authoritative.

### Test 1023 — PSPLIM and protected task stack

- Build: `Build-M33-Qual`, whole-image `-O0`; one type-1023 alert from a
  static 2048-byte FreeRTOS task stack, with a 2048-byte maximum coredump.
- **Expected payloads:** Exactly `trap.dmp` and `dfm_trace.psfs`; no other
  payloads are allowed.
- Require `trap.dmp`, trace evidence, a usable unwind through
  `dfm_t23_protected_stack_task`, and normal task completion.
- PSPLIM must be nonzero and unchanged across the trap; measured PSP-to-PSPLIM
  headroom must be 128..1152 bytes, the stack high-water mark must remain
  nonzero, and the 1024-byte volatile live-data checksum must be unchanged.
