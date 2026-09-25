# DFM Test Cases

This is the practical lookup catalog for DFM system tests. Its scope is DFM as
a component, so future tests for other DFM APIs belong here as well. The
currently implemented cases exercise `DFM_TRAP()` and the Zephyr fault path on
Arm Cortex-M.

The numeric alert type is the official test ID. For `DFM_TRAP()` cases, the
supplied message is exactly `Test <test-id>` or, for a multi-alert case,
`Test <test-id><suffix>`. For example, type 1020 with message `Test 1020A`
maps to section Test 1020 below. Test 1025 instead uses DFM's Zephyr-generated
fault description. The filename and line number appended to trap descriptions
identify the callsite; they are not a test-specification reference.

Target-side `DFMT:CHECK:...:PASS` and `SUITE_COMPLETE` markers establish local
control flow only. A product PASS still requires the manual DFM, payload,
trace, and GDB checks specified here.

Text after the test ID names only evidence available in that alert: payload
presence, GDB commands run on `trap.zpr`, or named events in
`dfm_trace.psfs`. It does not claim that the current `DFM_TRAP()` returned.
Where return or a later postcondition matters, a subsequent alert suffixed
`B` captures a trace event written after the first call returned. The `B`
suffix distinguishes alerts but does not create another numeric test ID.

## 1. Common Environment

The implemented suite uses Zephyr, GCC, and `qemu_cortex_m3`. Unless a case
says otherwise, it runs after DFM initialization in privileged Thread mode on
PSP and calls:

```c
DFM_TRAP(<test-id>, "Test <test-id>", 0);
```

The normal full-path configuration includes:

- `CONFIG_PERCEPIO_DFM=y`;
- `CONFIG_PERCEPIO_DFM_CFG_DESCRIPTION_MAX_LEN=96`;
- `CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS=y`;
- `CONFIG_DEBUG_COREDUMP=y`;
- `CONFIG_EXTRA_EXCEPTION_INFO=y`;
- `CONFIG_DEBUG_COREDUMP_BACKEND_OTHER=y`;
- `CONFIG_DEBUG_COREDUMP_MEMORY_DUMP_MIN=y`;
- `CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP=y`;
- `CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=-1`, so capture starts at the
  live stack pointer and continues without an artificial byte limit;
- `CONFIG_PERCEPIO_DFM_CFG_COREDUMP_SEND=y`;
- `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=y` in the resolved configuration;
- `CONFIG_IRQ_OFFLOAD=y`; and
- `CONFIG_REBOOT=y`.

DFM appends the source filename and line to the supplied message in a
128-byte formatting buffer. Every resulting test description must contain
fewer than 50 characters so the metadata description and TraceRecorder
`[ALERT]` copy remain complete. Detect currently stores `alert_description` in
a 100-character database field, and the host harness retains its independent
absolute-limit check.

For a normal full-path case, expect one alert, a valid `trap.zpr`, a trace
payload when tracing was active, and normal return. The dump must open with the
exact ELF from the matching build directory. GDB must show the required
application-frame subsequence and the correct source callsite. Zephyr and DFM
internal frames may vary.

The DFM Trap viewer does not print a backtrace automatically. Run
`info registers` and `bt full` manually. Review TraceRecorder user events on
the `DFM Tests` channel. Every ordinary runtime case writes `T<test-id> BEGIN`;
selected `PATH`, `ARGS`/`DATA`, `CTX`, `RETURN`, and `POST` events provide
additional evidence. Events are deliberately split into short lines so they
remain legible in Tracealyzer's event list.

For every event-log artifact, inventory every `[DFM Tests]` row, not only the
`[ALERT]` row. Against the allowlisted source and the test section below,
verify all current-test rows that should exist at that alert's capture point,
including complete formatted values, multiplicity, and order. For a two-alert
case, treat the event logs as cumulative snapshots. Account for earlier test
IDs as retained ring-buffer history before the current test window; they may
not replace current-test evidence or contradict its ordering. Excluding the
exported bracketed channel label, all fixture `[DFM Tests]` and `[ALERT]` event
text is designed to fit below 50 characters and must not be truncated.
Tests 1006, 1007, 1016, 1019, 1020, and 1021 intentionally produce two alerts
so the second trace payload can witness behavior after the first call.

At `-O0`, specified arguments and locals are strict GDB oracles. At `-Og` and
`-Os`, required physical frames and the callsite must remain visible, but
nonessential variables may be reported as optimized out.

## 2. Build Profiles and Execution Order

### `m3_o0`

- Overlay: `dfm_tests/conf/o0.conf`.
- Optimization: `CONFIG_NO_OPTIMIZATIONS=y`, giving whole-image `-O0`.
- Cases: Test 1001, Test 1003, Test 1012.
- Build label and Revision: `Build-M3-O0`.
- Artifact directory: `dfm_test_artifacts/Build-M3-O0/`.

### `m3_og`

- Overlay: `dfm_tests/conf/og.conf`.
- Optimization: `CONFIG_DEBUG_OPTIMIZATIONS=y`, giving whole-image `-Og`.
- Case: Test 1013.
- Build label and Revision: `Build-M3-Og`.
- Artifact directory: `dfm_test_artifacts/Build-M3-Og/`.

### `m3_os`

- Overlay: `dfm_tests/conf/os.conf`.
- Optimization: `CONFIG_SIZE_OPTIMIZATIONS=y`, giving whole-image `-Os`.
- Additional instrumentation: `CONFIG_INIT_STACKS=y` and
  `CONFIG_THREAD_STACK_INFO=y`.
- Execution order: Test 1002, Test 1004, Test 1005, Test 1006, Test 1007,
  Test 1008, Test 1009, Test 1011, Test 1014, Test 1016, Test 1017, Test 1018,
  Test 1019, Test 1021, Test 1010.
- Test 1010 is deliberately last so a regression in the pre-initialization
  guard cannot hide the evidence from the other cases in the image.
- Build label and Revision: `Build-M3-Os`.
- Artifact directory: `dfm_test_artifacts/Build-M3-Os/`.

### `m3_no_coredump`

- Overlay: `dfm_tests/conf/no_coredump.conf`.
- Build label and Revision: `Build-M3-NoCD`.
- Artifact directory: `dfm_test_artifacts/Build-M3-NoCD/` after a successful
  build.
- Optimization: whole-image `-Os`.
- Coredumps, their Zephyr backend, memory-dump mode, thread-stack-top capture,
  and DFM coredump sending are disabled.
- `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=y`; trace capture remains enabled
  independently of coredump support.
- Case: Test 1015.

### `m3_small_coredump`

- Overlay: `dfm_tests/conf/small_coredump.conf`.
- Optimization: whole-image `-Os`.
- Special setting:
  `CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE=128`.
- Case: Test 1020.
- Build label and Revision: `Build-M3-SmallCD`.
- Artifact directory: `dfm_test_artifacts/Build-M3-SmallCD/`.

### `m3_stack128`

- Overlay: `dfm_tests/conf/stack128.conf`.
- Optimization: `CONFIG_NO_OPTIMIZATIONS=y`, giving whole-image `-O0` and the
  same reference fixture as Test 1001.
- Special setting: `CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=128`.
- Case: Test 1024.
- Build label and Revision: `Build-M3-Stack128`.
- Artifact directory: `dfm_test_artifacts/Build-M3-Stack128/`.

### `m3_no_trace`

- Overlay: `dfm_tests/conf/no_trace.conf`.
- Optimization: whole-image `-Os`.
- `CONFIG_PERCEPIO_DFM_CFG_ENABLE_COREDUMPS=y` and
  `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n` are both explicit.
- Execution order: Test 1026 (`DFM_TRAP`), then Test 1025 (fault and reboot).
- Build label and Revision: `Build-M3-NoTrace`.
- Artifact directory: `dfm_test_artifacts/Build-M3-NoTrace/`.

### `m3_retained`

- Overlay: `dfm_tests/conf/retained.conf`.
- Optimization: whole-image `-Os`.
- Coredumps, trace capture, and DFM retained memory are enabled; the coredump
  strategy is retain rather than send.
- Retention and retained-memory mutexes are disabled because DFM writes from
  exception context.
- Execution order: Tests 1027 and 1028.
- Build label and Revision: `Build-M3-Retained`.
- Artifact directory: `dfm_test_artifacts/Build-M3-Retained/`.

### `m3_retained_8k`

- Overlay: `dfm_tests/conf/retained_8k.conf`.
- Optimization: whole-image `-Os`.
- The DFM configuration matches `m3_retained`, but the dedicated retained
  region is intentionally limited to 8 KiB.
- Execution order: Test 1029, then Test 1030.
- Build label and Revision: `Build-M3-Ret8K`.
- Artifact directory: `dfm_test_artifacts/Build-M3-Ret8K/`.

## 3. Implemented Cortex-M3 Cases

### Test 1001 — Unoptimized reference chain

- **Alert:** Type 1001;
  `Test 1001`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Establish the strict reference for register capture, stack
  arguments, local variables, and four-frame application unwinding.
- **Build:** `m3_o0`, whole-image `-O0`, normal full-path configuration.
- **Stimulus:** Call `test_thread -> public_api -> service -> trap_site` with
  six distinct 32-bit arguments. The trap is in the middle of the leaf and
  locals remain live after it.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** Run `info registers` and `bt full` on `trap.zpr`, then
  verify the complete application subsequence
  `dfm_t01_trap_site <- dfm_t01_service <- dfm_t01_public_api <-
  dfm_t01_test_thread` and the trap callsite. In `trap_site`, expect
  `arg0` through `arg5` to be `1`, `2`, `3`, `4`, `5`, and `6`; expect
  `local_sum=21` and `local_xor=7`. Also verify the live
  service and API sentinels where GDB exposes them. In the trace, verify the
  `T1001 ARGS` and `T1001 PATH` events before the alert event.
- **Manual result, 2026-09-14:** `PASS`. GDB recovered the complete application
  chain `dfm_t01_trap_site <- dfm_t01_service <- dfm_t01_public_api <-
  dfm_t01_test_thread`, followed by the harness frames. All six arguments, the
  four register values, both trap-site locals, and both caller sentinels matched
  the oracle. The captured live-stack interval was 312 bytes
  (`0x20003ac8..0x20003c00`), so the formerly missing thread-start frame is no
  longer truncated. See the consolidated
  [consolidated DFM test report](test-reports/dfm_test_report.md#test-1001--unoptimized-reference-chain).

### Test 1002 — Optimized inline and noinline chain

- **Alert:** Type 1002;
  `Test 1002`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise production-like optimized unwinding around a forced
  inline wrapper and physical noinline frames.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Use a logical four-level chain with three physical frames and
  enum, scalar, string-pointer, and structure-pointer arguments.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's backtrace, verify `mode=7`, `scalar=30`,
  `name="t02-name"`, and a payload with `tag=10`, `count=20`, and `enabled=1`
  where optimization permits.
  Verify the physical noinline frames and correct callsite. The inline wrapper
  may appear only as DWARF inline information. Verify the `T1002 ARGS`,
  `T1002 DATA`, and `T1002 PATH` events before the alert.

### Test 1003 — Trap at function entry

- **Alert:** Type 1003;
  `Test 1003`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise a minimal leaf frame before ordinary function-body
  work has changed the argument registers.
- **Build:** `m3_o0`, whole-image `-O0`, normal full-path configuration.
- **Stimulus:** Call a depth-two chain. The trap is the first statement and
  receives `10`, `20`, `30`, and `40`.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's backtrace, verify caller and leaf, the entry
  callsite, and arguments `10`, `20`, `30`, and `40`. Verify those four
  captured values with `info registers`; use disassembly to explain any
  entry-prologue representation. Verify all four `T1003 ARGS` events and the
  `T1003 PATH` event.

### Test 1004 — Trap at return boundary

- **Alert:** Type 1004;
  `Test 1004`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise unwinding close to an optimized function epilogue.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Call `test_thread -> caller -> trap_before_return`; the trap is
  the last statement before returning the computed value 4404.
- **Expected:** One alert, valid `trap.zpr`, trace payload, normal return, and
  `DFMT:CHECK:1004:PASS:CALLER_CONTINUED_ONCE`.
- **Manual review:** Run `bt full` and verify the three application frames,
  epilogue callsite, `value=4000`, and `return_value=4404`. The target marker
  independently verifies continuation; it is not asserted by the alert text.
  The trace records the input, expected return value, and call path before the
  alert.

### Test 1005 — Startup after DFM initialization

- **Alert:** Type 1005;
  `Test 1005`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Establish the supported startup boundary before `main()` but
  after DFM initialization.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Arm a one-shot `.noinit` state, reboot, and call from
  `SYS_INIT(..., APPLICATION, 1)` after DFM's priority-zero initializer.
- **Expected:** `IPSR=0`, PSP selected, one alert, valid `trap.zpr`, trace
  payload, return from the hook, and resume at Test 1006 without repeating Test 1005.
- **Manual review:** Run `info registers` and `bt full`; verify Thread mode in
  `xpsr`, the `dfm_test_t05_application` startup-hook frame, payloads, and
  callsite. A `main` frame is neither expected nor required because this
  `SYS_INIT` hook runs before `main`; optimized Zephyr initialization frames
  may also be absent and the unwind may stop at the captured stack boundary.
  Use startup markers to verify PSP, return, and exactly one execution.

### Test 1006 — Handler-mode invocation

- **Alerts:** Both use type 1006: `Test 1006A` and `Test 1006B`.
- **Expected payloads:** 1006A: exactly `dfm_trace.psfs`, with no `trap.zpr`;
  1006B: exactly `trap.zpr` and `dfm_trace.psfs`. No other payloads are
  allowed.
- **Purpose:** Exercise the Handler/MSP branch where the SVC coredump path is
  unsupported.
- **Build:** `m3_os`, whole-image `-Os`, normal DFM configuration.
- **Stimulus:** Invoke the trap from a controlled `irq_offload()` handler after
  initialization with `restart=0`.
- **Expected:** `IPSR != 0`, alert-only processing, no `trap.zpr`, return from
  the handler, and continued system execution.
- **Manual review:** The first alert must have no `trap.zpr`; its trace must
  show a nonzero `T1006A CTX Handler IPSR`. The 1006B trace must contain
  `T1006B RETURN first trap; IPSR=<nonzero>`, proving the first trap returned.
  The witness alert itself must have a valid `trap.zpr`.

### Test 1007 — Two caller paths and trace resumption

- **Alerts:** Both use type 1007: `Test 1007A` and `Test 1007B`.
- **Expected payloads:** Each alert contains exactly `trap.zpr` and
  `dfm_trace.psfs`; no other payloads are allowed.
- **Purpose:** Detect stale global state and verify that DFM itself resumes an
  initially active recorder after each returning trap.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Reach one shared error handler through separate depth-three and
  depth-four left/right paths, without manually restarting tracing between
  calls.
- **Expected:** Two distinct alerts, two valid dumps, two trace payloads,
  normal returns, and `TRACE_RESUMED` after each call.
- **Manual review:** Verify that each dump contains only its own caller path
  and that no metadata, frames, or trace content is stale from the other call.
  The shared handler's `path_sentinel` is `70` for 1007A and `71` for 1007B.
  The 1007B trace must contain
  `T1007A returned trace_enabled=1`, proving both return and DFM trace
  resumption after 1007A.

### Test 1008 — DFM-requested reboot

- **Alert:** Type 1008;
  `Test 1008`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Verify alert completion and sequential-suite recovery when
  exactly `restart=1` requests a cold reboot.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Persist Test 1009 as the next case, then invoke from normal PSP
  context with `restart=1`.
- **Expected:** A complete alert and valid payloads are emitted before reboot;
  the call does not return; the next boot reports
  `DFMT:RESUMED:1008:1009`; Test 1008 is not repeated.
- **Manual review:** Verify alert/payload completeness, one reboot, ordered
  resume markers, and absence of a reboot loop. The reboot/resume behavior is
  verified from target markers because no later payload can span a reboot.

### Test 1009 — System-workqueue chain

- **Alert:** Type 1009;
  `Test 1009`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise a realistic kernel callback root and its unwind chain.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Submit work that calls
  `app_work_handler -> service -> trap_site` on the system workqueue.
- **Expected:** One alert, valid `trap.zpr`, trace payload, successful work
  submission/completion, and normal return from the trap.
- **Manual review:** In GDB's backtrace, verify argument `9`, the three
  application frames plus the appropriate Zephyr workqueue root, the callsite,
  and all Test 1009 checks. Verify the `T1009 PATH` and `T1009 DATA` events in
  the trace.

### Test 1010 — Invocation before DFM initialization

- **Alert identity if incorrectly emitted:** Type 1010;
  `Test 1010`.
- **Expected payloads:** None; emitting an alert or payload fails this case.
- **Purpose:** Verify that PSP alone is not treated as proof that DFM and the
  kernel services needed by the full path are ready.
- **Build:** `m3_os`, whole-image `-Os`; this is the final case in the image.
- **Stimulus:** Arm a one-shot `.noinit` state, reboot, and invoke from
  `SYS_INIT(..., PRE_KERNEL_1, 0)` before DFM and timer initialization. Pass
  `restart=1` to prove that an ignored call cannot reach the restart path.
- **Expected:** The call is ignored and returns without alert, dump, reboot,
  fatal error, hang, or user-visible diagnostic output.
- **Manual review:** Verify the startup/recovery markers and absence of any DFM
  alert. Failure to return or a second reboot is a product failure.
- **Manual result, 2026-09-14:** PASS. The rebuilt `m3_os` image reported
  `DFMT:RETURNED:1010:startup:ipsr=0:control=0x2`, passed both the thread-mode
  and PSP checks, reached `DFMT:SUITE_COMPLETE:m3_os`, and emitted no Type 1010
  alert description. No DFM-requested second reboot occurred.

### Test 1011 — Indirect callback chain

- **Alert:** Type 1011;
  `Test 1011`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise GDB unwinding through a runtime-selected function
  pointer.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Store the callback in a volatile function pointer and call
  `test_thread -> dispatcher -> callback_handler -> trap_site`; the trap is
  the first statement in the leaf.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's backtrace, verify argument `11`, the
  actual callback target, dispatcher, handler, trap site, source line, and
  indirect callsite. Verify the `T1011 DATA callback value=11`
  and `T1011 PATH` events in the trace.

### Test 1012 — Deep mixed-frame ABI chain

- **Alert:** Type 1012;
  `Test 1012`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise five-frame unwinding, a large frame, register/stack
  argument placement, alignment, and mixed ABI values.
- **Build:** `m3_o0`, whole-image `-O0`, normal full-path configuration.
- **Stimulus:** Call
  `test_thread -> small_frame -> large_frame -> six_args -> trap_site` with a
  32-bit scalar, `uint64_t`, structure pointer, string pointer, `uint16_t`, and
  data pointer. The large frame contains 24 volatile words.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's `bt full`, verify all five application frames,
  `scalar=10`, `wide=5000000000`, `text="t12-text"`, `small=20`,
  `record->tag=30`, `record->values={1, 2, 3}`, and `*pointer=40`. Check the
  wide-value alignment, `trap_sentinel=100`, and the large frame's first and
  last values `1` and `24`. Verify the `T1012 ARGS`, `T1012 DATA`, and
  `T1012 PATH` events in the trace.

### Test 1013 — Reference chain at debug optimization

- **Alert:** Type 1013;
  `Test 1013`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Isolate the effect of `-Og` on the Test 1001 reference fixture.
- **Build:** `m3_og`, whole-image `-Og`, normal full-path configuration.
- **Stimulus:** Run the same chain and six 32-bit values as Test 1001.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's backtrace, verify the same four physical frames,
  argument values, and callsite as Test 1001; accept nonessential
  optimized-out variables. The `T1013` trace records the first and last
  argument even if GDB reports optimized-out values.

### Test 1014 — Reference chain at size optimization

- **Alert:** Type 1014;
  `Test 1014`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Isolate the effect of production-like `-Os` on the Test 1001
  reference fixture.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Run the same chain and six 32-bit values as Test 1001.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
- **Manual review:** In GDB's backtrace, verify the same four noinline frames,
  argument values, and callsite as Test 1001; accept nonessential
  optimized-out variables. The `T1014` trace records the first and last
  argument even if GDB reports optimized-out values.

### Test 1015 — Compile-time no-coredump fallback

- **Alert:** Type 1015;
  `Test 1015`.
- **Expected payloads:** Exactly `dfm_trace.psfs`, with no `trap.zpr`; no
  other payloads are allowed.
- **Purpose:** Exercise the separately compiled DFM fallback when coredump
  support is disabled.
- **Build:** `m3_no_coredump`, whole-image `-Os`, with all coredump settings
  listed in that profile disabled.
- **Stimulus:** Invoke from a normal initialized thread with `restart=0`.
- **Expected:** The image builds, one alert is created with `dfm_trace.psfs`
  but without `trap.zpr`, and the call returns normally.
- **Manual review:** Treat a compile failure as FAIL. Otherwise verify alert
  metadata, absence of a coredump payload, trace order
  `T1015 BEGIN -> ALERT`, and normal continuation.

### Test 1016 — Thread mode using MSP

- **Alerts:** Both use type 1016: `Test 1016A` and `Test 1016B`.
- **Expected payloads:** 1016A: exactly `dfm_trace.psfs`, with no `trap.zpr`;
  1016B: exactly `trap.zpr` and `dfm_trace.psfs`. No other payloads are
  allowed.
- **Purpose:** Test the MSP condition independently of Handler mode.
- **Build:** `m3_os`, whole-image `-Os`, normal DFM configuration.
- **Stimulus:** In privileged Thread mode, switch to an isolated 512-word MSP
  stack, confirm `IPSR=0` and `CONTROL.SPSEL=0`, invoke with `restart=0`, then
  restore PSP. On Armv8-M targets using the built-in stack guard, the fixture
  saves `MSPLIM`, points it at the isolated stack's bottom before selecting
  MSP, and restores the original MSP and `MSPLIM` after returning to PSP.
- **Expected:** Alert-only processing, no SVC coredump and no `trap.zpr`,
  normal return, and restored PSP.
- **Manual review:** The first alert must have no `trap.zpr`. Its trace must
  contain `T1016A ACTION switch PSP -> MSP`, `T1016A CTX IPSR=0`, and
  `T1016A CTX CONTROL=00000000`. The 1016B trace must contain separate
  `T1016B RETURN trap_CTL=00000000` and
  `T1016B RETURN now_CTL=<SPSEL-set>` events, proving return to PSP.
  The witness alert must have a valid `trap.zpr`. Also verify all four target
  checks.

### Test 1017 — Trace initially stopped

- **Alert:** Type 1017;
  `Test 1017`.
- **Expected payloads:** Exactly `trap.zpr`, with no `dfm_trace.psfs`; no
  other payloads are allowed. `ADD_TRACE` remains enabled by default; the
  trace is absent because the recorder is stopped at runtime.
- **Purpose:** Verify that DFM preserves an initially stopped trace state.
- **Build:** `m3_os`, whole-image `-Os`, normal coredump configuration.
- **Stimulus:** Disable TraceRecorder, invoke a normal PSP trap with
  `restart=0`, and inspect recorder state before harness cleanup.
- **Expected:** One alert and valid `trap.zpr`, no trace payload, normal return,
  and the recorder remains stopped. The harness restarts it only after the
  observation.
- **Manual review:** Verify payload absence and both Test 1017 stopped-state checks.

### Test 1018 — Small valid stack margin

- **Alert:** Type 1018;
  `Test 1018`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Exercise the hidden stack cost of register capture, SVC entry,
  DFM, and Zephyr coredump processing.
- **Build:** `m3_os`, whole-image `-Os`, stack initialization/information,
  strong stack canaries, and stack sentinel enabled.
- **Stimulus:** Run the full path in a dedicated 1536-byte thread stack and
  measure unused stack before and after the call.
- **Expected:** One alert, valid `trap.zpr`, trace payload, normal thread
  completion, successful measurements, remaining headroom, and no stack fault.
- **Manual review:** Verify Test 1018 checks and record `stack_size`,
  `unused_before`, and `unused_after` from the observation marker. In the
  trace, verify the separate `T1018 STACK size=<value>` and
  `T1018 STACK unused=<value>` events agree with the marker.

### Test 1019 — Short description and recovery

- **Alerts:** Both use type 1019: `Test 1019A` and `Test 1019B`.
- **Expected payloads:** Each alert contains exactly `trap.zpr` and
  `dfm_trace.psfs`; no other payloads are allowed.
- **Purpose:** Verify short suffixed alert identities and that a subsequent
  trap is unaffected.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Invoke once with the Test 1019A message, then immediately
  invoke again with the Test 1019B message.
- **Expected:** Both descriptions contain fewer than 50 characters after DFM
  appends the callsite; both alerts and payloads remain independent; no crash,
  hang, truncation, or stale state occurs.
- **Manual review:** Verify both alerts and their payload integrity. The 1019A
  event log must contain `T1019 BEGIN` followed by
  `T1019A MSG chars=10 formatted_max=49`. The 1019B snapshot must additionally
  contain `T1019B RETURN first trap completed` before its `[ALERT]`, proving
  completion of the first call.

### Test 1020 — Undersized coredump buffer

- **Alerts:** Both use type 1020: `Test 1020A` and `Test 1020B`.
- **Expected payloads:** Each alert contains exactly `dfm_trace.psfs`, with no
  `trap.zpr`; no other payloads are allowed.
- **Purpose:** Verify safe, deterministic failure when the configured coredump
  buffer cannot hold a normal dump.
- **Build:** `m3_small_coredump`, whole-image `-Os`, with
  `CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE=128`.
- **Stimulus:** Invoke the normal PSP path twice with `restart=0`, writing
  `T1020B RETURN first trap completed` between the calls.
- **Expected:** No buffer overrun, hang, reboot, or malformed/partial
  `trap.zpr`; the alert path ends deterministically and the call returns.
- **Manual review:** Both alerts must omit `trap.zpr`. The 1020B trace must
  contain `T1020B RETURN first trap completed`, proving deterministic
  completion of the first capacity failure. Also verify
  `DFMT:RETURNED:1020:0` and suite
  completion.

### Test 1021 — Existing scheduler lock

- **Alerts:** Both use type 1021: `Test 1021A` and `Test 1021B`.
- **Expected payloads:** Each alert contains exactly `trap.zpr` and
  `dfm_trace.psfs`; no other payloads are allowed.
- **Purpose:** Verify that DFM's internal scheduler lock/unlock preserves an
  existing outer scheduler lock.
- **Build:** `m3_os`, whole-image `-Os`, normal full-path configuration.
- **Stimulus:** Lock the scheduler, lower the current thread priority, make a
  higher-priority thread ready, invoke the trap, inspect state before the outer
  unlock, then unlock and wait for the high-priority thread.
- **Expected:** Two alerts with valid `trap.zpr` and trace payloads.
  The high-priority thread stays blocked during the outer lock and runs after
  the outer unlock.
- **Manual review:** In the 1021B trace verify, in order,
  `T1021A RETURN high_ran=0` and
  the separate `T1021B POST high_ran=1` and `T1021B POST wait=0` events. This
  proves both preservation of the outer lock and execution after unlock. The
  preceding `DATA` and `STATE`
  events record priorities and the lock precondition. Verify `bt full` for
  each alert and both target checks without fixed Zephyr-internal frame
  numbers.

### Test 1024 — Deliberate 128-byte stack-capture limit

- **Alert:** Type 1024;
  `Test 1024`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Preserve the former 128-byte stack-capture behavior as an
  explicit boundary test without truncating the general test builds.
- **Build:** `m3_stack128`, whole-image `-O0`, using the Test 1001 reference
  fixture with `CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=128`.
- **Stimulus:** Run the same four-function call chain and six distinct 32-bit
  values as Test 1001.
- **Expected:** One alert, valid `trap.zpr`, trace payload, and normal return.
  The dump remains valid but contains only the first 128 bytes of the current
  thread's live stack interval.
- **Manual review:** Run `info registers` and `bt full` with the matching
  `Build-M3-Stack128` ELF. Verify the inner application frames
  `dfm_t01_trap_site <- dfm_t01_service <- dfm_t01_public_api`, verify that
  the outer `dfm_t01_test_thread` frame cannot be recovered, and confirm from
  the mapped stack interval that capture stops 128 bytes above the saved stack
  pointer. Verify the `T1024 ARGS` and `T1024 PATH` trace events and
  `DFMT:RETURNED:1024:0`.
- **Manual result, 2026-09-14:** `PASS`. The mapped live-stack interval was
  exactly 128 bytes (`0x20003ac8..0x20003b48`). GDB recovered `trap_site`,
  `service`, and `public_api`, then stopped at `0x20003b4c`; it could not
  recover `dfm_t01_test_thread`, as required by this boundary test.

### Test 1025 — Fault without trace payload

- **Alert:** Type 1025; DFM's Zephyr fault description contains architecture
  reason code 36 (`K_ERR_ARM_USAGE_UNDEFINED_INSTRUCTION`).
- **Expected payloads:** Exactly `fault.zpr`, with no `dfm_trace.psfs` or
  `trap.zpr`; no other payloads are allowed.
- **Purpose:** Prove that compile-time `ADD_TRACE=n` suppresses the trace
  payload on the real Zephyr fault path without suppressing its coredump.
- **Build:** `m3_no_trace`, whole-image `-Os`, with coredumps enabled and
  `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n`.
- **Stimulus:** Execute the Cortex-M `UDF #0` instruction from
  `dfm_t25_undefined_instruction`, enter Zephyr's real fatal path, and reboot
  from `k_sys_fatal_error_handler` after DFM has serialized the alert.
- **Expected:** One type-1025 alert, a valid `fault.zpr`, no trace payload,
  `K_ERR_ARM_USAGE_UNDEFINED_INSTRUCTION`, exactly one expected reboot, and
  `DFMT:RESUMED:1025:END` followed by suite completion.
- **Manual review:** Verify the exact payload inventory first. Open
  `fault.zpr` with the `Build-M3-NoTrace` ELF; verify readable core/fault
  registers, the undefined-instruction fault state and PC, and a usable unwind
  through `dfm_t25_undefined_instruction` to `dfm_test_run_t25`. Verify the
  target-side `FAULT_TEST_MATCH` and `FAULT_REASON_UNDEFINED_INSTRUCTION`
  checks. No event-log artifact may exist for this alert.

### Test 1026 — DFM_TRAP without trace payload

- **Alert:** Type 1026; `Test 1026`.
- **Expected payloads:** Exactly `trap.zpr`, with no `dfm_trace.psfs` or
  `fault.zpr`; no other payloads are allowed.
- **Purpose:** Prove that compile-time `ADD_TRACE=n` suppresses the trace
  payload on a returning `DFM_TRAP()` without suppressing its coredump.
- **Build:** `m3_no_trace`, whole-image `-Os`, with coredumps enabled and
  `CONFIG_PERCEPIO_DFM_CFG_ADD_TRACE=n`.
- **Stimulus:** Confirm that TraceRecorder is running, invoke a normal PSP
  `DFM_TRAP(1026, "Test 1026", 0)`, and inspect recorder state after return.
- **Expected:** One alert, valid `trap.zpr`, no trace payload, normal return,
  and a recorder that remained enabled before and after the trap.
- **Manual review:** Verify the exact payload inventory first. Open `trap.zpr`
  with the `Build-M3-NoTrace` ELF and verify the callsite and an unwind through
  `dfm_test_run_t26`. Verify both target-side recorder checks and
  `DFMT:RETURNED:1026:0`. No event-log artifact may exist for this alert.

### Test 1027 — Retained alert and measured trap duration

- **Alert:** Exactly one transmitted type-1027 alert; its description is
  `Test 1027B` with the source location appended.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`, with no
  `fault.zpr`; no other payloads are allowed.
- **Purpose:** Verify that a complete alert survives a restart in Zephyr
  retained memory and is transmitted by `xDfmAlertSendAll()` from `main()`.
  Measure the time required to create and retain a complete `DFM_TRAP()` alert.
- **Build:** `m3_retained`, whole-image `-Os`, with a 9,392-byte `retention0`
  region. Its four-byte validity prefix and four-byte SUM32 leave 9,384 usable
  bytes: 229 bytes (2.50%) above the measured 9,155-byte full alert.
  The build uses the retained coredump strategy with trace capture enabled.
- **Stimulus:** Emit `T1027 RETAIN BEGIN`, call returning
  `DFM_TRAP(1027, "Test 1027A", 0)`, emit `T1027 RETAIN END`, then call
  `DFM_TRAP(1027, "Test 1027B", 1)`. The second trap captures the two timing
  events in its trace, replaces the first retained alert, and reboots.
- **Expected:** No DFM transport block is emitted before the reboot. At the
  next boot, `main()` reports `DFMT:RETAINED_ALERT:FOUND`, sends the retained
  1027B alert, verifies that send-all cleared the retention marker, reports
  `DFMT:RETAINED_ALERT:SENT`, and the harness reports `DFMT:RESUMED:1027:END`
  before suite completion.
- **Manual review:** Verify the exact payload inventory and that the sole
  transmitted alert is 1027B. In `dfm_trace.psfs`, verify the order
  `T1027 RETAIN BEGIN -> ALERT Test 1027A -> T1027 RETAIN END -> ALERT Test
  1027B`; subtract the two retained-event timestamps to obtain the complete
  first-trap time. Open `trap.zpr` with the matching ELF and verify the second
  trap callsite. DFM writes entries directly through the
  generic retained-memory backend, accumulates SUM32 from the data already in
  hand, then commits the checksum and complete alert with one
  `retention_write()` call. No full checksum pass is made before reboot.
  Current DFM retained memory holds one alert: each
  new retained alert clears and replaces the previous one. The reference QEMU
  run used 9,155 retained bytes for 1027B; the region is deliberately sized
  for that one full alert plus 2.50% usable-data margin.

### Test 1028 — Corrupted retained alert after restart

- **Alert:** None is transmitted.
- **Expected payloads:** None; no other payloads are allowed.
- **Purpose:** Verify that the retained-memory SUM32 detects data corruption
  after restart and prevents a damaged alert from being sent.
- **Build:** `m3_retained`, whole-image `-Os`, with the normal 9,392-byte
  retained region and trace capture enabled.
- **Stimulus:** Retain a complete restarting
  `DFM_TRAP(1028, "Test 1028", 1)`. On the next boot, before checking the
  retained alert, flip one bit in its first data byte without changing its
  validity prefix or stored SUM32.
- **Expected:** The target reports `CORRUPTION_INJECTED` and
  `CORRUPTION_REJECTED`, emits no DFM transport block for type 1028, clears the
  invalid storage, reports `DFMT:RESUMED:1028:END`, and completes the variant.
- **Manual review:** Verify both target checks, the resume marker, and the
  complete absence of a type-1028 alert or payload. Because the validity
  prefix remains intact, rejection specifically exercises the checksum path.

### Test 1029 — Trace is truncated in 8 KiB retained memory

- **Alert:** Exactly one transmitted type-1029 alert with description
  `Test 1029` and the source location appended.
- **Expected payloads:** Exactly one complete `trap.zpr` plus a best-effort
  leading prefix of `dfm_trace.psfs` in the raw DFM entries; no other payloads
  are allowed. The receiver may expose the trace prefix as a truncated file or
  reject that incomplete file. A complete or directly openable trace is not
  required.
- **Purpose:** Verify that retained-memory exhaustion preserves the alert,
  every complete payload, and the leading chunks of the payload that filled
  the retained region.
- **Build:** `m3_retained_8k`, whole-image `-Os`, with an 8,192-byte
  `retention0` region. Its four-byte prefix and four-byte SUM32 leave 8,184
  bytes for DFM data; trace capture remains enabled.
- **Stimulus:** Invoke restarting `DFM_TRAP(1029, "Test 1029", 1)` with the
  recorder enabled. The retained writer stores entries until the first write
  failure, stops further payload writes, and commits the successfully written
  prefix.
- **Expected:** After reboot, `main()` reports `DFMT:RETAINED_ALERT:FOUND`,
  sends the retained entries, reports `DFMT:RETAINED_ALERT:SENT`, and the
  harness resumes with `DFMT:RESUMED:1029:1030`. The reference QEMU run emits
  the complete one-chunk coredump and trace chunks 1-6 of 7; trace chunk 7 is
  absent.
- **Manual review:** Verify the type-1029 alert, open `trap.zpr` with the
  matching ELF, and verify the Test 1029 callsite. Verify that the raw trace
  chunks form the contiguous prefix 1-6 of 7 and that no writes are attempted
  after the first retained payload failure. Compare with Test 1030 in the same
  build, where no trace payload is added.

### Test 1030 — Coredump-only retained alert fits in 8 KiB

- **Alert:** Exactly one transmitted type-1030 alert; its description is
  `Test 1030` with the source location appended.
- **Expected payloads:** Exactly `trap.zpr`, with no `dfm_trace.psfs` or
  `fault.zpr`; no other payloads are allowed.
- **Purpose:** Provide the coredump-only comparison for Test 1029: prove that
  the same 8 KiB retained region stores and delivers the alert header and
  coredump when no trace snapshot is attached.
- **Build:** `m3_retained_8k`, identical to Test 1029.
- **Stimulus:** Stop TraceRecorder at runtime, verify the stop succeeded, then
  invoke restarting `DFM_TRAP(1030, "Test 1030", 1)`.
- **Expected:** The target reports `TRACE_DISABLED`; after reboot `main()`
  reports `DFMT:RETAINED_ALERT:FOUND` and `DFMT:RETAINED_ALERT:SENT`, the
  harness reports `DFMT:RESUMED:1030:END`, and exactly one alert is serialized.
- **Manual review:** Verify the exact payload inventory, open `trap.zpr` with
  the `Build-M3-Ret8K` ELF, and verify the Test 1030 callsite and unwind. No
  trace event-log artifact may exist for this alert.

## 4. Armv8-M Qualification

These cases are implemented in the physical-board-only `m33_qual` variant.
The variant has been build validated for `b_u585i_iot02a`; alert, coredump,
and unwind evidence still requires execution on physical hardware. The M3
QEMU suite excludes this variant.

### Test 1022 — Active floating-point state

- **Alert:** Type 1022;
  `Test 1022`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Verify that an active floating-point context does not prevent
  coredump creation, core-register interpretation, unwind, or normal return.
- **Build:** `m33_qual`, whole-image `-O0`, with FPU support, FPU context
  sharing, and hardware stack protection enabled.
- **Stimulus:** Write the sentinel value `100` to `s16`, verify
  that `CONTROL.FPCA` is active, and invoke DFM.
- **Target checks:** `FPCCR.ASPEN` and `FPCCR.LSPEN` are enabled; FP context is
  active before and after the trap; `s16` retains the sentinel; and the trap
  returns normally.
- **Expected:** One alert with a coredump; the core registers and application
  frames are readable, unwind succeeds without stack-frame offset errors, and
  execution returns normally with the FP context intact.
- **Zephyr limitation:** The coredump format used by this release exports only
  the core register set. `s0`–`s31` and `FPSCR` are therefore not expected in
  Detect/GDB output, and their absence must not fail this test.
- **Manual review:** Verify coredump presence, readable core registers,
  application frames, successful unwind, the target-side FP-state checks, and
  normal return. Do not require FP-register values in the coredump output.

### Test 1023 — PSPLIM and stack protection

- **Alert:** Type 1023;
  `Test 1023`.
- **Expected payloads:** Exactly `trap.zpr` and `dfm_trace.psfs`; no other
  payloads are allowed.
- **Purpose:** Verify DFM operation near an Armv8-M process-stack limit.
- **Build:** `m33_qual`, with `CONFIG_HW_STACK_PROTECTION=y`, a dedicated
  2048-byte test-thread stack, and a 2048-byte DFM coredump buffer.
- **Stimulus:** Keep 1024 bytes of volatile live-stack data while invoking DFM
  from a PSP thread with an active PSPLIM.
- **Target checks:** PSPLIM is nonzero and unchanged across the trap; measured
  headroom is 128..1152 bytes; the trap returns; Zephyr's stack guard remains
  intact; and the live-data hash is unchanged.
- **Expected:** One alert and coredump; no false limit violation; dump, unwind,
  and return all succeed without corrupting the guard or stack state.
- **Manual review:** Verify PSPLIM, SP values, guard status, stack headroom,
  dump contents, and application unwind.

## 5. Evidence Required for Every Executed Case

- Test ID, variant, exact `.config`, compiler flags, and matching ELF.
- `qemu_last_session.log` markers before and after the invocation.
- Alert type, description, build identity, and payload names.
- `trap.zpr`, `fault.zpr`, and trace payloads when expected, or verified
  absence when not.
- For coredump cases: `info registers`, `bt`, `bt full`, required arguments,
  locals, and callsite from GDB using the exact ELF.
- Manual verdict: `PASS`, `FAIL`, or `BLOCKED`, with reviewer, date, and defect
  reference where applicable.

`PASS` means every case-specific and common expected result was observed.
`FAIL` means observed product behavior contradicts an expectation. `BLOCKED`
means tooling, missing evidence, or correlation prevents a product verdict.
