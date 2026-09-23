# DFM_TRAP on Arm Cortex-M: White-Box Appendix

This appendix accompanies the
[test specification](dfm_trap_cortex_m_test_space.md). It preserves details
needed for test generation and troubleshooting without obscuring the selected
test suite.

The practical execution process is described in the
[test plan](dfm_trap_cortex_m_test_plan.md). Exact test inputs and review
oracles are maintained in [DFM test cases](dfm_test_cases.md).

## 1. Code Paths

The full macro and coredump path is compiled only when all three symbols are
defined:

```text
CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS
&& CONFIG_IRQ_OFFLOAD
&& CONFIG_CPU_CORTEX_M
```

If any build condition is false, the macro calls the alert-only
implementation.

On Cortex-M, the runtime check selects alert-only when:

```text
IPSR != 0 || CONTROL.SPSEL == 0
```

These conditions represent Handler mode/ISR and Thread mode using MSP,
respectively. Thread mode using PSP proceeds through scheduler locking,
SVC/IRQ offload, and the Zephyr coredump backend.

## 2. Registers and Unwinding

- The macro captures r0–r3 and r12 before evaluating the metadata arguments.
- The capture function is `naked` and uses balanced push/pop operations.
- The SVC shim saves r4–r11 and MSP. The Cortex-M exception frame on PSP
  contains r0–r3, r12, LR, PC, and xPSR.
- `CONFIG_EXTRA_EXCEPTION_INFO` is required for complete callee-saved
  register and stack information. r7 is particularly important for
  `-O0` unwinding.
- The SVC integration reads `EXC_RETURN` from Zephyr's saved-MSP layout and
  is therefore sensitive to Zephyr-version changes.
- Active floating-point state can create an extended exception frame and
  motivates Armv8-M test Test 1022.
- Near the stack limit, space is needed for capture, the exception frame, and
  ordinary C and coredump stack usage.

## 3. Startup and Initialization

Zephyr on Cortex-M normally switches to PSP before ordinary C startup code.
Early `PRE_KERNEL` calls can therefore use PSP while kernel and DFM APIs are
still unsafe. PSP is necessary but not sufficient for the full coredump path.

In the current port, DFM is initialized by
`SYS_INIT(..., APPLICATION, 0)`. A successful startup test can therefore run
at a later `APPLICATION` priority. The test harness must not additionally
initialize DFM manually.

`k_busy_wait()` cannot be assumed to work before system-timer
initialization. On QEMU M3, SysTick is initialized during `PRE_KERNEL_2`.
A pre-initialization guard must therefore return before alert processing and
any restart delay. The Zephyr port implements this as a silent
`ulDfmIsInitialized()` guard in both the coredump and no-coredump paths. In the
coredump path, the guard is deliberately evaluated after `DFM_TRAP` has saved
the caller-saved registers, so the initialization check cannot corrupt an
initialized trap's register snapshot. No early diagnostic is printed: logging
is not guaranteed to be ready, and a pre-initialization call should not create
a user-visible side effect.

Test 1005 and Test 1010 require one-shot `SYS_INIT` hooks. The runtime runner must arm the
appropriate hook in validated `.noinit` state and request a cold reboot. Each
hook remains inert on every other boot. Test 1010 may only use raw startup-safe state
access before the kernel is initialized; `run_tests()` interprets and logs the
result later from `main()`.

## 4. Alert, Trace, and Restart

- A Zephyr coredump with reason `K_ERR_DFM_TRAP` must produce a payload named
  `trap.zpr`.
- A Zephyr fatal coredump must produce `fault.zpr`. With
  `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n`, neither path may attach
  `dfm_trace.psfs` even while TraceRecorder itself remains enabled.
- The alert description combines the message, filename, and line number in
  the shared `cDfmPrintBuffer[128]`, leaving at most 127 visible characters
  plus the terminating NUL.
- The suite configures `DFM_CFG_DESCRIPTION_MAX_LEN` to 96. The macro in
  `dfm.h` adds termination space and 64-bit alignment, producing a 104-byte
  stored field. This fits the `uint8_t ucDescriptionSize` format field and the
  entry buffer validated by `xDfmEntryInitialize()`.
- A configured value of 256 is not supported by the present representation:
  its aligned stored field would exceed 255 and trigger the compile-time guard
  in `dfmAlert.h`.
- The serialized size tells host tools how much description data follows, so
  the Receiver and Client must tolerate the 104-byte field, including its NUL
  termination and alignment padding. The actual description text remains
  within the configured 96-character budget and Detect's 100-character
  database limit.
- Tracing is paused while its payload is captured. If the trap returns, a
  previously active recorder session must resume; an already stopped recorder
  must remain stopped.
- Resumption preserves the same ring-buffer session. A trace event recorded
  after one returning trap is therefore expected in a later trap's trace
  payload until overwritten. Tests 1006, 1007, 1016, 1019, 1020, and 1021 use
  this as a payload-visible witness of return or a later postcondition.
- Only `restart == 1` requests a cold reboot when `CONFIG_REBOOT` is enabled.
- The restart path uses `k_busy_wait(1000)` to allow final UART output to
  drain.
- Before Test 1008 calls the restart path, the harness must persist the next registry
  index and an `EXPECT_DFM_REBOOT` phase. A successful reboot therefore resumes
  at Test 1009 instead of executing Test 1008 repeatedly.
- Before Test 1025 executes `UDF #0`, the harness persists the following index
  and `EXPECT_FAULT_REBOOT`. The fatal callback records the architecture reason,
  and the next boot requires `K_ERR_ARM_USAGE_UNDEFINED_INSTRUCTION` before
  completing the variant.

## 5. Shared State and Boundaries

- Trap metadata, the register snapshot, and coredump state are global. The
  implementation is not intended for concurrent SMP use or nested traps.
- The coredump is assembled in a buffer sized by
  `CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE`. Capacity failure must not copy
  data beyond the buffer.
- The backend stores at most `MAX_COREDUMP_PARTS` parts. Zephyr is expected
  to use significantly fewer, so this boundary is not in the main suite.
- `message` and `__FILE__` must remain readable, null-terminated strings
  throughout the synchronous call. `NULL` is outside the valid contract.
- The full PSP path locks and unlocks the scheduler. An existing scheduler
  lock must be preserved through correct nesting.

## 6. Harness Persistence Conditions

- The test runner uses a dedicated `.noinit` structure containing magic,
  format version, firmware-variant cookie, run ID, registry index, armed
  test, phase, reboot count, and a consistency field.
- Random RAM or state from another image must fail validation and start a new
  sequence at index zero.
- The consistency field is written last. A partially updated state must never
  be accepted as permission to skip a test.
- State is committed before DFM or the harness can reboot. Normal returning
  cases advance only after their observations and cleanup are complete.
- `COMPLETE` is persistent, so a later reboot remains idle rather than starting
  the suite again.
- `.noinit` retention across the actual QEMU cold-reboot path is a harness
  assumption that must be verified before the product suite is accepted.
- A stopped and restarted QEMU process is a new run; RAM retention across host
  process lifetime is not required.

Sequence markers and registry progress establish harness control flow only.
They do not replace manual inspection of alert, coredump, GDB, or trace output.
Likewise, a trace event captured by an alert proves only that execution reached
the event before that alert; this is why post-return events are inspected in a
subsequent witness alert rather than in the alert generated by the call being
tested.

## 7. White-Box Conditions and Coverage

- **Coredump build flags:** Test 1001 covers the full path; Test 1015 covers the
  compile-time fallback; Tests 1025 and 1026 cover coredumps with trace
  attachment compiled out.
- **Handler mode:** Test 1006 covers `IPSR != 0` and alert-only behavior.
- **Thread mode using MSP:** Test 1016 covers `IPSR == 0` with `SPSEL == 0`.
- **Thread mode using PSP:** Test 1001 and the other full-path tests cover
  `IPSR == 0` with `SPSEL == 1`.
- **DFM lifecycle:** Test 1005 covers initialized startup; Test 1010 covers safe handling
  before initialization.
- **Trace state:** Test 1007 covers active trace, preserved ring-buffer history,
  and resume; Test 1017 covers trace already stopped; Tests 1025 and 1026 cover
  `ADD_TRACE=n` for fault and trap paths. Selective witness alerts make
  post-return behavior payload-visible without adding logical test IDs.
- **Fault path:** Test 1025 executes a real undefined instruction and verifies
  fatal coredump creation, architecture-reason capture, and expected reboot.
- **Restart:** Test 1001 covers return with zero; Test 1008 covers cold reboot with exactly
  one.
- **Stack headroom:** Test 1001 covers normal headroom; Test 1018 covers a small valid
  margin.
- **Message length:** Test 1001 covers a short message; Test 1019 covers bounded handling
  of a long message.
- **Coredump capacity:** Test 1001 covers a fitting payload; Test 1020 covers the safe
  capacity-failure path.
- **Captured stack extent:** Test 1001 covers an unlimited live-stack interval;
  Test 1024 covers deliberate truncation at 128 bytes using the same `-O0`
  reference chain.
- **Scheduler state:** Test 1001 covers normal locking; Test 1021 covers an existing lock.
- **Exception frame:** Test 1001 covers the basic M3 frame; Test 1022 verifies
  that coredump creation and unwind remain correct with active M33F state.
  Zephyr does not export FP registers in this release, so FP-register display
  is outside the test oracle.
- **Stack-limit protection:** Test 1018 covers M3 guard behavior; Test 1023 covers PSPLIM
  on M33.

The following analyzed branches are intentionally omitted: invalid
`EXC_RETURN`, more than `MAX_COREDUMP_PARTS`, interrupts disabled,
NMI handlers, concurrency, and invalid pointers. They require internal
fault injection, are unlikely in the current configuration, or are explicitly
outside the supported scope.

## 8. Analyzed Sources

- `modules-staging/modules/debug/percepio/DFM/kernelports/Zephyr/include/dfmKernelPort.h`
- `modules-staging/modules/debug/percepio/DFM/kernelports/Zephyr/dfmKernelPort.c`
- `modules-staging/modules/debug/percepio/DFM/include/dfmUtility.h`
- Zephyr Cortex-M startup code, SVC handling, scheduler APIs, and coredump APIs.
