# DFM_TRAP on Arm Cortex-M: Test Space

Status: implemented Cortex-M3/GCC scope  
Primary environment: Zephyr and `qemu_cortex_m3`  
Separate qualification: implemented Armv8-M/M33 firmware; hardware evidence pending

This document defines what varies and why. The authoritative case-by-case
descriptions and review oracles are in [DFM test cases](dfm_test_cases.md).
Implementation reasoning is retained in the
[white-box appendix](dfm_trap_cortex_m_white_box_appendix.md), while execution
and artifacts are covered by the
[test plan](dfm_trap_cortex_m_test_plan.md).

## 1. Scope and Main Decisions

The objective is risk-based system verification of `DFM_TRAP()` without
creating an impractical manual-review burden. The selected scope is 25 tests
on Cortex-M3/GCC plus two separately reported Armv8-M tests.

- An initialized Zephyr thread in Thread mode using PSP is the primary full
  coredump path.
- Handler mode and Thread mode using MSP must use alert-only behavior and must
  not enter the SVC coredump path.
- PSP alone is not evidence that DFM and required kernel services are ready.
  A call before DFM initialization must return without an alert, dump, reboot,
  fatal error, or hang.
- `restart=0` must return; exactly `restart=1` must complete the alert before a
  cold reboot.
- An initially active trace must resume after a returning trap. An initially
  stopped trace must remain stopped.
- `-O0` and `-Os` are mandatory. One reference fixture is also built at `-Og`
  to isolate optimization effects on GDB unwinding.
- Compatible tests run sequentially. Only compile-time configuration changes
  require another build.
- SMP, nested traps, user mode, invalid pointers, and transport matrices are
  outside the current scope.

## 2. Behavioral Contexts

- **Initialized Thread/PSP:** Create an alert and `trap.zpr`, add a trace when
  tracing was active, then return or reboot according to `restart`.
- **Initialized workqueue Thread/PSP:** Use the same full path, but preserve a
  realistic Zephyr callback root in the coredump.
- **Initialized `SYS_INIT(APPLICATION, >0)`:** Use the full path before
  `main()` after DFM's priority-zero initialization.
- **Handler/MSP:** Create an alert without a coredump and return to the
  interrupted context.
- **Thread/MSP:** Create an alert without entering the SVC coredump path, then
  restore PSP and continue.
- **Before DFM initialization:** Ignore the call safely. An early diagnostic
  is optional because output facilities may not be ready.

## 3. Test Dimensions

The suite samples representative high-risk combinations rather than taking a
Cartesian product.

- **Compiled path:** Full coredump support, the separately compiled
  no-coredump fallback, and coredump builds with trace attachment compiled
  both in and out. This covers both trap macro implementations and the
  independent `ENABLE_COREDUMPS`/`ADD_TRACE` choices.
- **Lifecycle:** Before initialization, initialized startup, and runtime. This
  tests the assumption that required services exist.
- **CPU context:** Thread/PSP, Handler/MSP, and Thread/MSP. These values select
  the full or alert-only path.
- **Execution source:** Ordinary thread, workqueue callback, ISR, and
  `SYS_INIT`. These create materially different call roots.
- **Call-chain form:** Straight noinline chain, mixed inline/noinline chain,
  two paths into one handler, workqueue callback, and indirect callback. These
  stress different GDB unwind and compiler decisions.
- **Call depth:** Two through five application frames. This gives shallow,
  typical, and deeper unwind coverage.
- **Arguments:** Zero through six arguments, including 32-bit scalar, enum,
  pointer, structure pointer, and aligned 64-bit value. This covers register-
  and stack-passed ABI data.
- **Trap position:** First statement, middle of a function with live state,
  and final statement before return. This samples prologue, ordinary frame,
  and epilogue boundaries.
- **Optimization:** `-O0`, `-Og`, and `-Os`. Inlining, register lifetime,
  frame layout, and debug information differ.
- **Restart and sequence:** Returning calls, a harness-requested startup
  reboot, a DFM-requested reboot, retained progress, and suite completion.
- **Retained alert lifecycle:** Store an alert and its payloads in a dedicated
  retained-memory region, reboot, send it from `main()`, and clear the region.
  Two traps also expose the current single-alert replacement behavior.
- **Trace state:** Active, stopped at runtime, disabled at compile time, and
  two consecutive alerts. This covers payload capture and suppression, resume
  behavior, stale state, and use of a later alert's trace as evidence that an
  earlier non-restarting trap returned.
- **Fault source:** A real undefined-instruction fault covers the Zephyr fatal
  path and `fault.zpr` independently of the controlled `DFM_TRAP` path.
- **Scheduler state:** Normal and already locked. DFM must preserve an outer
  scheduler lock.
- **Stack margin:** Normal and small but valid. Capture, exception entry, and
  coredump processing all consume stack.
- **Buffers:** Short alert text that remains below the 50-character trace
  budget after callsite formatting, plus an undersized coredump buffer. These
  exercise host compatibility and safe coredump failure.
- **Architecture:** Armv7-M/M3 plus separate M33F floating-point-frame and M33
  PSPLIM coverage.

## 4. GDB Fixture Rules

Depth counts application frames from the trap function through the fixture
root. DFM, SVC, and Zephyr internal frames are not counted.

- Required physical frames are marked `noinline`.
- Caller results remain observable after a call to prevent accidental sibling
  or tail-call removal, except in the deliberate return-boundary fixture.
- An indirect callback is loaded through a volatile runtime function pointer.
- Distinctive argument values and selected volatile sentinels make captured
  state recognizable.
- Short `xTracePrint()`/`xTracePrintF()` events identify important calls and
  preconditions. They stay outside register-capture leaves when logging could
  perturb caller-saved register values.
- At `-O0`, specified arguments and locals are strict oracles.
- At `-Og` and `-Os`, required physical frames and the source callsite remain
  mandatory, but nonessential values may be optimized out.
- Review checks an ordered subsequence of application symbols, not fixed GDB
  frame numbers or an exact set of Zephyr frames.

## 5. Selected Suite

The detailed definitions, exact build profile, alert text, expected payloads,
GDB values, and manual checks are maintained only in
[DFM test cases](dfm_test_cases.md).

The implemented M3 suite consists of:

- Tests 1001-1004, 1007, 1009, and 1011-1014 for call-chain, ABI, placement,
  callback, depth, and optimization coverage;
- Tests 1005, 1006, 1008, 1010, 1015, 1016, and 1021 for lifecycle, context,
  restart, compile-time fallback, and scheduler behavior; and
- Tests 1017-1020 and 1024-1027 for trace, stack headroom, message,
  coredump-buffer, captured-stack-extent, no-trace coredumps, and the real
  fault path, plus retained-memory timing and reboot delivery.

Tests 1022 and 1023 form the M33 qualification for active floating-point state
and PSPLIM respectively. They are implemented in the hardware-only
`m33_qual` variant and are excluded from QEMU runs. The variant has been build
validated for `b_u585i_iot02a`; physical execution and evidence review remain.

This selection is intentionally small enough for manual review while covering
every implementation branch and the most likely unwind failures. New tests
should be added for confirmed defects or a real production configuration, not
merely to multiply equivalent combinations.

## 6. Deferred Coverage

Add these only when required by a supported product configuration or a found
defect:

- `-O2`, `-O3`, and LTO;
- Cortex-M0+/M23 and M4F/M7F targets;
- Clang or IAR;
- TrustZone Secure/Non-secure and MVE;
- calls with interrupts disabled;
- empty, invalid, or `NULL` message pointers;
- more than `MAX_COREDUMP_PARTS`;
- explicit `DFM_TRAP` calls from NMI/fault handlers, SMP, nested traps, and
  user mode; and
- other cloud, storage, and transport combinations beyond the focused retained
  memory case.

Every confirmed DFM defect receives a focused regression case even if the
suite consequently grows beyond the current count.
