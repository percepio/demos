# DFM Test Report Overview

This section is the human review log and may not be edited by AI. 

PASS here means that the payloads where displayed without errors, appeared plausible and that the payloads text exports were approved by Codex (GTP-5.6 Sol Extra High).

Test 1001: PASS
Test 1002: PASS
Test 1003: PASS
Test 1004: PASS
Test 1005: PASS
Test 1006: PASS
Test 1007: PASS
Test 1008: PASS
Test 1009: PASS
Test 1010: No alert but expected. PASS
Test 1011: PASS
Test 1012: PASS
Test 1013: PASS
Test 1014: PASS
Test 1015: PASS (no payloads, expected)
Test 1016: PASS
Test 1017: PASS
Test 1018: PASS
Test 1019: PASS
Test 1020: PASS
Test 1021: PASS
Test 1022: (TODO - Needs Armv8-M device like M33)
Test 1023: (TODO - Needs Armv8-M device like M33)
Test 1024: PASS

# Codex Review
Each Codex recommendation compares the documented oracle in
`dfm_test_cases.md`, the corresponding implementation in `dfm_tests/src/`, and
the observed evidence from the test artifacts. Any mismatch between these
sources is reported explicitly.

# Test 1001 — Unoptimized Reference Chain

**Reviewer:** Codex  
**Build:** `Build-M3-O0`, Cortex-M3/QEMU, whole-image `-O0`  
**Artifacts:** matching `zephyr.elf`, `trap.zpr`, and `dfm_trace.psfs`

## Reviewed evidence

- `run_suite.py`: Test returned normally; `m3_o0` completed. The full alert
  description was 83 characters and within both configured and Detect limits.
- `bt -full`: complete chain from `prvDfmTriggerCoredump` through
  `trap_site <- service <- public_api <- test_thread`, the harness, and `main`.
  The formerly missing `dfm_t01_test_thread` frame was recovered.
- Frame 0 registers matched the oracle:
  `r0=11111111`, `r1=22222222`, `r2=22222222`, `r3=77777777`.
- All six arguments matched `11111111` through `66666666`.
- Locals matched: `local_sum=66666665`, `local_xor=77777777`,
  `service_sentinel=51A7E001`, `api_sentinel=A91C0002`.
- Trace order matched:
  `T1001 BEGIN -> ARGS -> public_api/service -> service/trap_site -> ALERT`.
  The alert event coincided with Trace End, as expected.

The outer `result` locals were ignored because their initializing calls had
not returned. The shortened `[ALERT]` text in the trace is a TraceRecorder
event limitation; the DFM alert description itself was complete.

**Recommendation:** PASS

# Test 1002 — Optimized Inline and Noinline Chain

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching `zephyr.elf`, `trap.zpr` (539 B), and
`dfm_trace.psfs` (6.7 KB)

## Reviewed evidence

- `run_suite.py`: Test 1002 returned normally and `m3_os` completed.
- Detect metadata and the complete description matched Test 1002 and the
  callsite at `test_call_chains.c:103`.
- `bt -full` recovered `trap_leaf <- inline_wrapper <- public_api <-
  test_thread`, followed by the harness and Zephyr thread-entry frames. The
  forced inline wrapper was represented correctly in DWARF.
- GDB showed `mode=7`, `scalar=02020202`, `name="t02-name"`,
  `leaf_sentinel=02EA7001`, and payload values `tag=02C0FFEE`, `count=2233`,
  `enabled=1`.
- Trace order matched:
  `T1002 BEGIN -> ARGS -> DATA -> public_api/inline_wrapper ->
  inline_wrapper/trap_leaf -> ALERT -> Trace End`.

The optimized-out `result` locals are expected in this `-Os` build and are not
part of the test oracle.

**Recommendation:** PASS

# Test 1003 — Trap at Function Entry

**Reviewer:** Codex  
**Build:** `Build-M3-O0`, Cortex-M3/QEMU, whole-image `-O0`  
**Artifacts:** matching `zephyr.elf`, `trap.zpr`, and `dfm_trace.psfs`

## Reviewed evidence

- `run_suite.py`: Test 1003 returned normally and `m3_o0` completed.
- Detect metadata and the complete description matched Test 1003 and the
  callsite at `test_call_chains.c:164`.
- Frame 0 registers matched the exact oracle: `r0=03030300`, `r1=03030301`,
  `r2=03030302`, and `r3=03030303`.
- `bt -full` recovered `trap_at_entry <- test_thread <- run_t03`, followed by
  the harness and `main`, without unwind errors. GDB's function arguments also
  matched all four expected values.
- Trace order matched:
  `T1003 BEGIN -> ARGS r0/r1 -> ARGS r2/r3 -> test_thread/trap_at_entry ->
  ALERT -> Trace End`.

The failed `info regs` command was only a GDB command abbreviation error; the
subsequent `info registers` output was valid. The preceding Test 1001 events in
the trace are retained history and do not affect the Test 1003 payload.

**Recommendation:** PASS

# Test 1004 — Trap at Return Boundary

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus the supplied
`trap.zpr` and `dfm_trace.psfs` exports

## Reviewed evidence

- Alert key `DevAlert/ZephyrQEMU/1789389798701/2`, revision, complete
  description, and callsite `test_call_chains.c:194` matched Test 1004.
- `bt -full` recovered `trap_before_return(value=4000,
  return_value=4404) <- caller <- test_thread <- run_t04`, followed by the
  harness and Zephyr entry frames, without unwind errors. Frame 0 also held
  `r0=0x1134` (4404).
- The saved QEMU run independently recorded
  `DFMT:CHECK:1004:PASS:CALLER_CONTINUED_ONCE`, `DFMT:RETURNED:1004:0`, and
  completion of `m3_os`.
- Trace order matched:
  `T1004 BEGIN -> DATA input/expected_return -> caller/trap_before_return ->
  ALERT -> Trace End`.

The outer `result` locals being optimized out is expected in the `-Os` build.
The shortened trace `[ALERT]` event is a harmless recorder-text limit; the
Detect Description and coredump callsite were complete.

**Recommendation:** PASS

# Test 1005 — Startup after DFM Initialization

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus the supplied
`trap.zpr` and `dfm_trace.psfs` exports

## Reviewed evidence

- Alert key `DevAlert/ZephyrQEMU/1789389798713/1`, revision, complete
  description, type 1005, and callsite `test_contexts.c:48` matched the oracle
  and `DFM_TRAP(..., restart=0)` implementation.
- The valid coredump's explicit `bt -full` recovered
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_t05_application <-
  z_sys_init_run_level <- bg_thread_main <- z_thread_entry` without unwind
  errors. At the trap, `ipsr=0`, `control=2`, and `xpsr=0x21000000`, whose IPSR
  field is zero; this confirms Thread mode with PSP selected.
- The saved QEMU run recorded exactly one startup entry, return from the hook,
  passing `THREAD_MODE` and `PSP_SELECTED` checks, continuation to Test 1006,
  and completion of `m3_os`.
- The trace showed the expected post-reboot startup activity through the Test
  1005 alert and Trace End.

The repeated `dfm_test_t05_application` source view is harmless optimized DWARF
inline/line-table representation at the same address. Optimized-out locals are
expected for `-Os`; the shortened trace `[ALERT]` event does not affect the
complete Detect Description.

**Recommendation:** PASS

# Test 1006 — Handler-Mode Invocation

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus both supplied
`dfm_trace.psfs` exports and the 1006B `trap.zpr` GDB export

## Reviewed evidence

- Alert X (`DevAlert/ZephyrQEMU/1789389798728/2`) is 1006A: its revision,
  complete description, type, and `test_contexts.c:64` callsite matched the
  Handler-mode `DFM_TRAP(..., restart=0)` implementation. As required, it had
  no `trap.zpr`; its trace recorded `T1006A CTX Handler IPSR=11` before the
  alert.
- Alert Y (`DevAlert/ZephyrQEMU/1789389798744/3`) is 1006B: its matching trace
  retained the 1006A history, then recorded `T1006B RETURN first trap;
  IPSR=11` before the second alert. This proves that the unsupported
  Handler/MSP coredump path returned and execution continued.
- The 1006B coredump was valid. Its explicit `bt -full` recovered
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_run_t06 <- run_tests <-
  main <- bg_thread_main <- z_thread_entry` without unwind errors, and located
  the witness trap at `test_contexts.c:79`. Its `xpsr=0x21000000` has a zero
  IPSR field, as expected for the normal-thread witness.
- The saved QEMU run independently recorded passing `HANDLER_MODE` and
  `ISR_RETURNED` checks, `DFMT:RETURNED:1006:0`, continuation to Test 1007,
  and completion of `m3_os`.

The failed `regs` and `registers` commands were harmless GDB command-name
errors because the subsequent `info reg` output succeeded. Optimized-out
values are expected for `-Os`; the shortened trace `[ALERT]` text does not
affect either complete Detect Description.

**Recommendation:** PASS

# Test 1007 — Two Caller Paths and Trace Resumption

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus both supplied
`trap.zpr` GDB exports and `dfm_trace.psfs` text exports

## Reviewed evidence

- Alert X (`DevAlert/ZephyrQEMU/1789389798759/4`) and Alert Y
  (`DevAlert/ZephyrQEMU/1789389798775/5`) had the expected distinct 1007A/1007B
  descriptions and the shared `test_call_chains.c:236` trap callsite.
- Both coredumps were valid. Their explicit `bt -full` results recovered only
  the intended application path: `shared_error_handler <- left_path <-
  run_t07` for 1007A, versus `shared_error_handler <- right_inner <-
  right_path <- run_t07` for 1007B, followed by the common harness and Zephyr
  frames without unwind errors.
- At the shared handler, both the `path_sentinel` argument and
  `handler_sentinel` local matched the source: `0x07aaa001` (128622593) for
  1007A and `0x07bbb002` (129740802) for 1007B. Frame registers also retained
  test type 1007 in `r9`.
- Trace ordering matched the oracle. The 1007A payload showed
  `T1007 BEGIN -> T1007A PATH -> ALERT`; the 1007B payload retained that history
  and then showed `T1007A returned trace_enabled=1 -> T1007B PATH -> ALERT`,
  proving return and recorder resumption after the first trap.
- The saved QEMU run independently recorded passing `TRACE_RESUMED` checks
  after both calls, `DFMT:RETURNED:1007:0`, continuation to Test 1008, and
  completion of `m3_os`.

Earlier-test events and the 1007A history retained in the trace buffers are
expected recorder history. The shortened trace `[ALERT]` text and optimized-out
nonessential values are harmless; both complete Detect descriptions and all
required sentinels, paths, and return/resumption evidence were present.

**Recommendation:** PASS

# Test 1008 — DFM-Requested Reboot

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus the supplied
`trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798791/6` had the expected revision and
  description. The valid DFM-trap coredump resolved the witness to
  `DFM_TRAP(1008, ..., restart=1)` at `test_contexts.c:86`; `r9=0x3f0`
  independently retained alert type 1008.
- The viewer's fixed frame selection (not an explicit complete `bt`) exposed
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_run_t08 <- run_tests <-
  main <- bg_thread_main`, including the required Test 1008 and harness frames.
- GDB recovered persisted state `run_id=48793`, `next_index=6`,
  `armed_test=1008`, `phase=6`, and `reboot_count=2`. This matches the saved
  run's `0000be99` ID and the runner's pre-trap transition to the next test and
  expected-DFM-reboot phase.
- From its own marker, the trace showed `T1008 BEGIN -> ALERT`. The saved QEMU
  log showed every Test 1008 alert-data segment ending before the restart,
  then one additional reboot, `DFMT:RESUMED:1008:1009`, and Test 1009 starting;
  there was no return-failure marker, repeat of Test 1008, or reboot loop, and
  `m3_os` completed.

Earlier-test trace events are expected retained recorder history. The shortened
trace `[ALERT]` text and optimized-out parameters/locals are harmless for this
`-Os` build; the full Detect description, callsite, required caller frames, and
reboot/resume evidence are present.

**Recommendation:** PASS

# Test 1009 — System-Workqueue Chain

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus the supplied
`trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798808/1`, revision, complete description,
  and `test_contexts.c:98` callsite matched Test 1009 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The valid coredump viewer's fixed frame selection (not an explicit complete
  `bt`) exposed `dfm_t09_trap_site <- dfm_t09_service <-
  dfm_t09_app_work_handler <- work_queue_main <- z_thread_entry`, including all
  required application frames and the Zephyr workqueue root.
- At `dfm_t09_trap_site`, the argument, `trap_value` local, and `r0` all matched
  the source sentinel: `0x0909cafe` (151636734). The workqueue frame also
  resolved `work=t09_work` and `handler=dfm_t09_app_work_handler`.
- From its own marker, the trace showed
  `T1009 BEGIN -> work submit/context switch -> T1009 PATH -> T1009 DATA
  value=0909CAFE -> ALERT`.
- The matching saved QEMU run recorded passing `WORK_SUBMITTED`,
  `WORK_COMPLETED`, and `TRAP_RETURNED` checks, `DFMT:RETURNED:1009:0`,
  continuation to Test 1011, and eventual completion of `m3_os`.

Optimized-out work-handler parameters and workqueue locals are expected for
this `-Os` build. The shortened trace `[ALERT]` text is harmless because the
Detect Description and coredump callsite were complete.

**Recommendation:** PASS

# Test 1011 — Indirect Callback Chain

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf` and `qemu.log`, plus the supplied
`trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798824/2`, revision, complete description,
  and `test_call_chains.c:288` callsite matched Test 1011 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The valid coredump viewer's fixed frame selection (not an explicit complete
  `bt`) exposed `trap_site <- callback_handler <- dispatcher <- test_thread <-
  run_t11`, including the indirect callsite at line 309.
- At the trap, `value` and `r0` matched `0x1111cafe` (286378750), and `r9`
  retained type 1011. The dispatcher resolved `callback` to
  `dfm_t11_callback_handler`, confirming the runtime-selected target.
- From its own marker, the trace showed
  `T1011 BEGIN -> DATA callback value=1111CAFE -> PATH callback_handler ->
  trap_site -> ALERT`.
- The matching saved QEMU run recorded `DFMT:RETURNED:1011:0`, continuation to
  Test 1014, and eventual completion of `m3_os`.

The retained Test 1009 trace history is expected. The shortened trace `[ALERT]`
text is harmless because the Detect Description and coredump callsite were
complete; absent leaf locals are expected because the trap is its first
statement in an `-Os` build.

**Recommendation:** PASS

# Test 1012 — Deep Mixed-Frame ABI Chain

**Reviewer:** Codex  
**Build:** `Build-M3-O0`, Cortex-M3/QEMU, whole-image `-O0`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798522/3`, revision, complete description,
  and `test_call_chains.c:340` callsite matched Test 1012. The valid coredump's
  addresses also resolved against the archived ELF to the intended functions.
- The viewer's fixed frame selection (not an explicit complete `bt`) exposed
  all five contiguous application frames: `trap_site <- six_args <-
  large_frame <- small_frame <- test_thread`.
- GDB recovered all six mixed-ABI arguments: `scalar=0x12121212`,
  `wide=0x1234567887654321`, `text="t12-text"`, `small=0x12ab`, and the
  expected record/data pointers. It also showed `record->tag=0x12c0ffee`,
  values `0x1201..0x1203`, `*pointer=0x12d00d12`,
  `trap_sentinel=0x12feed01`, and large-frame endpoints `0x12000000` and
  `0x12000017`.
- From its own marker, the trace order matched:
  `T1012 BEGIN -> small/large PATH -> DATA wide -> large/six_args PATH ->
  ARGS scalar/small -> ALERT`.
- The matching saved QEMU run recorded `DFMT:RETURNED:1012:0` and
  `DFMT:SUITE_COMPLETE:m3_o0`.

Intermediate `result` locals were ignored because their initializing calls had
not returned; only the two initialized large-frame endpoints are meaningful.
Earlier trace events and the shortened trace `[ALERT]` text are harmless because
the Test 1012 sequence and complete Detect Description were present.

**Recommendation:** PASS

# Test 1013 — Reference Chain at Debug Optimization

**Reviewer:** Codex  
**Build:** `Build-M3-Og`, Cortex-M3/QEMU, whole-image `-Og`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798604/1`, revision, complete description,
  and `test_call_chains.c:28` callsite matched Test 1013 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The valid coredump loaded the archived `Build-M3-Og` ELF. The viewer's fixed
  frame selection (not an explicit complete `bt`) exposed the required
  four-frame application chain: `trap_site <- service <- public_api <-
  test_thread`, followed by `dfm_test_run_reference`.
- All six arguments matched `0x11111111` through `0x66666666`. GDB also
  recovered `local_sum=0x66666665`, `local_xor=0x77777777`,
  `service_sentinel=0x51a7e001`, and `api_sentinel=0xa91c0002`.
- From its own marker, the trace order matched:
  `T1013 BEGIN -> ARGS a0/a5 -> public_api/service -> service/trap_site ->
  ALERT`.
- The saved configuration confirmed `CONFIG_DEBUG_OPTIMIZATIONS=y`; the
  matching QEMU run recorded `DFMT:RETURNED:1013:0` and
  `DFMT:SUITE_COMPLETE:m3_og`.

The optimized-out outer `result` locals are harmless in this `-Og` build:
their initializing calls had not returned, and the oracle explicitly permits
nonessential variables to be optimized out.

**Recommendation:** PASS

# Test 1014 — Reference Chain at Size Optimization

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798839/3`, revision, complete description,
  and `test_call_chains.c:32` callsite matched Test 1014 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The valid coredump viewer's fixed frame selection (not an explicit complete
  `bt`) exposed the required four-frame application chain:
  `trap_site <- service <- public_api <- test_thread`, followed by
  `dfm_test_run_reference`.
- All six arguments matched `0x11111111` through `0x66666666`. GDB also
  recovered `local_sum=0x66666665`, `local_xor=0x77777777`,
  `service_sentinel=0x51a7e001`, and `api_sentinel=0xa91c0002`; `r9=1014`
  retained the alert type.
- From its own marker, the trace order matched:
  `T1014 BEGIN -> ARGS a0/a5 -> public_api/service -> service/trap_site ->
  ALERT`.
- The matching saved QEMU run recorded `DFMT:RETURNED:1014:0`, continuation to
  Test 1016, and eventual completion of `m3_os`.

The earlier Test 1009 and 1011 trace events are expected retained recorder
history. Optimized-out `result` locals are harmless in the `-Os` build because
their initializing calls had not returned and they are nonessential to the
oracle.

**Recommendation:** PASS

# Test 1015 — Compile-time No-Coredump Fallback

**Reviewer:** Codex  
**Build:** `Build-M3-NoCD`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied alert metadata and confirmation that the alert had no
payloads

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798420/1`, revision, type 1015, complete
  description, and `test_contexts.c:142` callsite matched the oracle and the
  exact `DFM_TRAP(..., restart=0)` implementation.
- The reported absence of all payloads includes the required absence of
  `trap.zpr`. The matching saved config has `CONFIG_DEBUG_COREDUMP` unset and
  omits the DFM coredump-enable/send options; the saved ELF confirms that this
  separately configured image built successfully.
- The saved QEMU run recorded exactly one alert-data block, then
  `DFMT:RETURNED:1015:0` and `DFMT:SUITE_COMPLETE:m3_no_coredump`, with no
  failure marker. Its encoded revision and description also match the
  supplied alert.

The final config retains generic `CONFIG_THREAD_STACK_INFO=y` from the base
image, but this is harmless: with `CONFIG_DEBUG_COREDUMP` disabled, the
coredump backend, memory-dump mode, and coredump stack-top capture are not
compiled and cannot produce `trap.zpr`.

**Recommendation:** PASS

# Test 1016 — Thread Mode Using MSP

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied metadata and `dfm_trace.psfs` exports for both alerts and the
1016B `trap.zpr` GDB export

## Reviewed evidence

- Alerts `DevAlert/ZephyrQEMU/1789389798855/4` (1016A) and
  `DevAlert/ZephyrQEMU/1789389798872/5` (1016B) had the required revision,
  complete descriptions, and `test_contexts.c:160`/`:186` callsites matching
  the two `DFM_TRAP(..., restart=0)` calls.
- Alert 1016A had no coredump payload, as required. From `T1016 BEGIN`, its
  trace recorded `ACTION switch PSP -> MSP`, then
  `CTX IPSR=0 CONTROL=00000000`, and then the 1016A alert.
- The 1016B trace retained that sequence and continued with
  `RETURN trap_CTL=00000000 now_CTL=00000002` before the witness alert,
  proving return from the first trap and restoration of `CONTROL.SPSEL`.
- The valid 1016B DFM-trap coredump loaded the archived `Build-M3-Os` ELF. The
  viewer's fixed frame selection (not an explicit complete `bt`) showed
  `dfm_test_run_t16` at the line 186 trap call; `control_after=2`,
  `xpsr=0x21000000` (Thread mode), and the main-thread stack were consistent
  with the restored-PSP witness.
- The matching saved QEMU run passed `THREAD_MODE`, `MSP_SELECTED`,
  `PSP_RESTORED`, and `TRAP_RETURNED`, then recorded
  `DFMT:RETURNED:1016:0`, continuation to Test 1017, and eventual
  `DFMT:SUITE_COMPLETE:m3_os`.

Earlier-test events retained in both trace buffers and the shortened
TraceRecorder `[ALERT]` text are harmless; the complete Detect descriptions
and the full Test 1016 event sequence are present.

**Recommendation:** PASS

# Test 1017 — Trace Initially Stopped

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export; no trace payload was present

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798891/6`, revision, complete description,
  and `test_boundaries.c:14` callsite matched Test 1017 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The alert contained only `trap.zpr`, so the required trace-payload absence
  was satisfied. The valid DFM-trap coredump loaded the archived
  `Build-M3-Os` ELF; `r9=1017` retained the alert type.
- The viewer's fixed frame selection (not an explicit complete `bt`) showed
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_run_t17 <- run_tests <-
  main <- bg_thread_main`, including the required Test 1017 and harness frames.
- At the trap, GDB recovered `stopped_before=true`. The matching saved QEMU
  run then recorded PASS for both `TRACE_STOPPED_BEFORE` and
  `TRACE_STILL_STOPPED`, `DFMT:RETURNED:1017:0`, continuation to Test 1018,
  and eventual `DFMT:SUITE_COMPLETE:m3_os`.

`stopped_after` is unavailable at the trap because its assignment occurs only
after `DFM_TRAP()` returns; this is harmless because the post-return harness
check directly confirms that the recorder remained stopped.

**Recommendation:** PASS

# Test 1018 — Small Valid Stack Margin

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389798901/7`, revision, complete description,
  and `test_boundaries.c:49` callsite matched Test 1018 and its
  `DFM_TRAP(..., restart=0)` implementation.
- The valid DFM-trap coredump loaded the archived `Build-M3-Os` ELF. The
  viewer's fixed frame selection (not an explicit complete `bt`) showed
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_t18_small_stack_thread` at the
  required trap line, followed by `z_thread_entry`.
- GDB recovered `unused_before=1460`. From its own marker, the trace recorded
  the 1536-byte thread creation and scheduling, then
  `T1018 STACK size=1536 unused=1460 -> ALERT`, agreeing with GDB and the saved
  observation.
- The saved configuration confirmed size optimization, initialized stacks,
  thread-stack information, strong stack canaries, and the stack sentinel.
  The matching QEMU run recorded `unused_after=1244`, passed all four Test 1018
  checks, returned zero, continued to Test 1019, and completed `m3_os`.

The GDB `unused_after=0` is the local's initialized pre-return value at the trap,
not the final measurement; the post-return observation supplies `1244` bytes of
remaining headroom. The shortened TraceRecorder `[ALERT]` text is also harmless
because the supplied Detect description is complete and correct.

**Recommendation:** PASS

# Test 1019 — Near-Limit Description and Recovery

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus both supplied `trap.zpr` GDB exports and `dfm_trace.psfs` text exports

## Reviewed evidence

- Alerts `DevAlert/ZephyrQEMU/1789389798914/8` and
  `DevAlert/ZephyrQEMU/1789389798930/9` had the required revision, complete
  descriptions, and respective `test_boundaries.c:97` and `:100` callsites,
  matching the two `DFM_TRAP(1019, ..., restart=0)` calls.
- The archived target output decoded exactly two type-1019 headers. Their
  complete descriptions were 91/100 and 79/100 characters; the first was the
  longest of all 19 `m3_os` alert descriptions and remained within Detect's
  limit.
- Both valid DFM-trap coredumps loaded the archived `Build-M3-Os` ELF. The
  viewer's fixed frame selections (not explicit complete `bt` commands) showed
  `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_run_t19 <- run_tests <-
  main <- bg_thread_main` at the correct callsite, with `r7=r9=1019`.
- From `T1019 BEGIN`, the traces recorded
  `T1019A LIMIT input_chars=67 host_limit=100 -> 1019A ALERT`; the second also
  recorded `T1019B RETURN first trap completed -> 1019B ALERT`, directly
  proving that the first trap returned before the independent witness alert.
- The matching QEMU artifact agreed with the 67-byte input, recorded
  `DFMT:RETURNED:1019:0`, continued to Test 1021, and completed `m3_os`.

Earlier-test events retained in the trace buffers and shortened TraceRecorder
`[ALERT]` text are harmless: the current-test markers are ordered correctly,
and both supplied Detect descriptions and locally decoded headers are complete.
Optimized-out arguments and absent locals are also expected for this `-Os`
build and do not obscure either callsite or alert type.

**Recommendation:** PASS

# Test 1020 — Undersized Coredump Buffer

**Reviewer:** Codex  
**Build:** `Build-M3-SmallCD`, Cortex-M3/QEMU, whole-image `-Os`, 128-byte
coredump buffer  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied metadata and `dfm_trace.psfs` text exports for both alerts;
neither alert had a `trap.zpr` payload

## Reviewed evidence

- Alerts `DevAlert/ZephyrQEMU/1789389799044/1` (1020A) and
  `DevAlert/ZephyrQEMU/1789389799055/2` (1020B) had the required revision,
  complete descriptions, and `test_boundaries.c:107`/`:110` callsites,
  matching the two `DFM_TRAP(1020, ..., restart=0)` calls.
- Both alerts contained only the trace payload, satisfying the required
  absence of `trap.zpr` rather than exposing a malformed or partial coredump.
  The archived config confirms coredumps are enabled with
  `CONFIG_PERCEPIO_DFM_CFG_MAX_COREDUMP_SIZE=128` in the size-optimized image.
- From `T1020 BEGIN`, the second trace retained the 1020A alert and then
  recorded `T1020B RETURN first trap completed` before the 1020B alert,
  directly proving deterministic return from the first capacity failure.
- The matching saved QEMU run decoded exactly two type-1020 headers with the
  supplied complete descriptions and callsites, then recorded
  `DFMT:RETURNED:1020:0` and
  `DFMT:SUITE_COMPLETE:m3_small_coredump` with no harness failure marker.

The shortened TraceRecorder `[ALERT]` strings (`smal`/`retu`) are harmless
event-list truncation: the supplied Detect descriptions and locally serialized
headers are complete and correct.

**Recommendation:** PASS

# Test 1021 — Existing Scheduler Lock

**Reviewer:** Codex  
**Build:** `Build-M3-Os`, Cortex-M3/QEMU, whole-image `-Os`  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied metadata, `trap.zpr` GDB exports, and `dfm_trace.psfs` text
exports for both alerts

## Reviewed evidence

- Alerts `DevAlert/ZephyrQEMU/1789389798946/10` (1021A) and
  `DevAlert/ZephyrQEMU/1789389798961/11` (1021B) had the required revision,
  complete descriptions, and `test_contexts.c:229`/`:245` callsites, matching
  the two `DFM_TRAP(1021, ..., restart=0)` calls.
- Both valid DFM-trap coredumps loaded the archived `Build-M3-Os` ELF. The
  viewer's fixed frame selections (not explicit complete `bt full` commands)
  exposed `prvDfmTriggerCoredump <- prvDfmTrap <- dfm_test_run_t21 <-
  run_tests <- main <- bg_thread_main` at both required callsites. At 1021B,
  GDB also recovered `stayed_blocked=true` and `wait_result=0`.
- From `T1021 BEGIN`, the second trace recorded priority 5 for `main` and 0 for
  the ready high-priority thread, the locked-scheduler state and 1021A alert,
  then `T1021A RETURN high_ran=0`. Only after the outer unlock did it switch to
  the high-priority thread and record
  `T1021B POST unlock high_ran=1 wait=0` before the 1021B alert.
- This ordering exercises the nested `k_sched_lock()`/`k_sched_unlock()` in
  `prvDfmTrap` and proves it preserved the test's outer lock. The matching QEMU
  artifact serialized exactly the two supplied descriptions, passed both
  target checks, recorded `DFMT:RETURNED:1021:0`, and completed `m3_os`.

Earlier-test events retained in the trace buffers and shortened TraceRecorder
`[ALERT]` strings are harmless; review starts at `T1021 BEGIN`, and the supplied
Detect descriptions and archived serialized headers are complete. Optimized-out
values in this `-Os` build do not obscure the required frames or postconditions.

**Recommendation:** PASS

# Test 1024 — Deliberate 128-Byte Stack-Capture Limit

**Reviewer:** Codex  
**Build:** `Build-M3-Stack128`, Cortex-M3/QEMU, whole-image `-O0`, 128-byte
current-thread stack limit  
**Artifacts:** matching local `zephyr.elf`, `zephyr.config`, and `qemu.log`,
plus the supplied `trap.zpr` GDB export and `dfm_trace.psfs` text export

## Reviewed evidence

- Alert `DevAlert/ZephyrQEMU/1789389799130/1`, revision, complete description,
  and `test_call_chains.c:30` callsite matched Test 1024 and its exact
  `DFM_TRAP(..., restart=0)` implementation.
- The valid DFM-trap coredump loaded the archived `Build-M3-Stack128` ELF. The
  explicit `bt -full` recovered the required application chain
  `dfm_t01_trap_site <- dfm_t01_service <- dfm_t01_public_api`, then stopped
  at inaccessible address `0x20003b2c` without recovering
  `dfm_t01_test_thread`, as required.
- The locally serialized coredump maps the live-stack block as
  `[0x20003aa8, 0x20003b28)`, exactly 128 bytes from the saved `sp`. The saved
  config confirms `CONFIG_DEBUG_COREDUMP_THREAD_STACK_TOP_LIMIT=128` and the
  corresponding current-thread limit, with `CONFIG_NO_OPTIMIZATIONS=y`.
- All six trap-site arguments matched `0x11111111` through `0x66666666`.
  GDB also recovered `local_sum=0x66666665`, `local_xor=0x77777777`,
  `service_sentinel=0x51a7e001`, and `api_sentinel=0xa91c0002`.
- From `T1024 BEGIN`, the trace order matched
  `ARGS a0/a5 -> public_api/service -> service/trap_site -> ALERT`. The saved
  QEMU run recorded `DFMT:RETURNED:1024:0` and
  `DFMT:SUITE_COMPLETE:m3_stack128`.

The stack block is 0x20 below the absolute-address example recorded by an
earlier manual review, but its 128-byte extent and unwind boundary are the
required invariants. The inaccessible outer arguments, not-yet-initialized
outer `result` locals, and shortened TraceRecorder `[ALERT]` text all follow
from that deliberate boundary or normal trap timing; the Detect description
is complete.

**Recommendation:** PASS
