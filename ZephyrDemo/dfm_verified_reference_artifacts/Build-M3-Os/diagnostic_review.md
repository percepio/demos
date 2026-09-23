# DFM diagnostic review - Build-M3-Os

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1002 — PASS:** Exactly one alert and the two expected payloads are present. Metadata, coredump values/backtrace, TraceRecorder rows and ordering, target execution markers, and required build settings all agree with the oracle.
- **1004 — PASS:** All required oracle claims are supported by the allowlisted evidence.
- **1005 — PASS:** All oracle requirements are supported by the allowlisted evidence.
- **1006 — PASS:** All required payload, metadata, trace, handler-return, coredump, target, source, and build-contract checks passed.
- **1007 — PASS:** Both alerts contain exactly the required payloads; dumps, trace events, ordering, paths, sentinels, resumption, return status, and build settings are valid.
- **1008 — PASS:** The alert is Test 1008 with one alert and exactly the authoritative payload set: trap.zpr and dfm_trace.psfs. The coredump shows DFM_TRAP(1008, "Test 1008", 1) with a complete ordered backtrace and no unwind error. The event log contains all [DFM Tests] rows in order; T1008 BEGIN is followed by the alert with no unexpected current-test rows. Target markers prove the expected DFM reboot, ordered resume to Test 1009, no repeat, and suite completion. Build variant and all contracted settings match.
- **1009 — PASS:** Exactly one alert is evidenced with the required two payloads. Execution, return checks, backtrace, registers/locals, trace rows/order, metadata, and build settings are consistent.
- **1010 — PASS:** The oracle requires no alert or payload, and the allowlisted evidence shows the startup call returned, validated thread mode and PSP selection, resumed to END, and completed the suite without a Type 1010 alert.
- **1011 — PASS:** Exactly trap.zpr and dfm_trace.psfs are present. The callback chain, value 11, ordered trace events, complete backtrace, normal return, and m3_os configuration all match the oracle.
- **1014 — PASS:** One matching alert; exactly trap.zpr and dfm_trace.psfs; expected arguments, locals, complete backtrace, ordered trace rows, return 0, suite completion, and configuration are all evidenced.
- **1016 — PASS:** Both alerts, payloads, metadata, coredump, trace events, target checks, and build contract are consistent.
- **1017 — PASS:** Exactly one trap.zpr payload is present; no trace payload is listed. Trace was stopped before and remained stopped, the trap returned normally, and the build contract/configuration match m3_os.
- **1018 — PASS:** All oracle, payload, target, source, event ordering, stack, and build-contract checks passed.
- **1019 — PASS:** Both independent 1019 alerts and their payloads are complete, correctly ordered, and consistent with source and build evidence.
- **1021 — PASS:** Both alerts, exact payload sets, coredumps, trace ordering, target checks, and build contract are consistent with the oracle.

## Evidence

### Test 1002 — PASS

- Metadata identifies alert/test 1002, session 1790171758625, revision Build-M3-Os, callsite test_call_chains.c:104, and payload count 2.
- Payload inventory is complete and contains exactly trap.zpr and dfm_trace.psfs.
- Coredump confirms mode=7, scalar=30, name=t02-name, payload tag=10/count=20/enabled=1, leaf_sentinel=100, correct inline/noinline call chain, and callsite 104.
- Eventlog contains every expected T1002 row in source order: BEGIN, two ARGS rows, four DATA rows, two PATH rows, followed by the alert.
- Target evidence proves DFMT BEGIN, RETURNED, and suite completion for m3_os.
- Build contract variant m3_os and all required settings match build configuration evidence.

### Test 1004 — PASS

- Metadata identifies alert type/test 1004, session 1790171758664, revision Build-M3-Os, callsite test_call_chains.c:203, and payload count 2.
- Complete payload inventory contains exactly trap.zpr and dfm_trace.psfs with no errors or additional payloads.
- Coredump is a valid DFM_TRAP payload with r0=4404, value=4000, return_value=4404, the expected three application frames, epilogue callsite, and complete unwinding without an error.
- Eventlog history rows are all T1002 rows preceding the current window; current T1004 rows are complete, correctly formatted, unique, and ordered: BEGIN, input=4000, expected_return=4404, and caller -> trap_before_return.
- Target evidence confirms DFMT:CHECK:1004:PASS:CALLER_CONTINUED_ONCE, DFMT:RETURNED:1004:0, and suite completion.
- Build variant m3_os and all required settings CONFIG_SIZE_OPTIMIZATIONS=y, CONFIG_INIT_STACKS=y, and CONFIG_THREAD_STACK_INFO=y match the embedded build contract.

### Test 1005 — PASS

- Metadata identifies alert/test 1005, callsite test_contexts.c:48, revision Build-M3-Os, matching session, and payload count 2.
- Complete payload inventory contains exactly trap.zpr and dfm_trace.psfs with no errors.
- Coredump confirms IPSR=0, CONTROL=2 (PSP), startup-hook callsite/locals, ordered complete backtrace, and no unwind error.
- Eventlog contains one matching [ALERT] row and no [DFM Tests] rows; source control flow reboots before the startup case's later trace print, so no current-test trace rows are expected.
- Target evidence proves startup entry, one reboot, return in Thread mode with PSP selected, continuation to Test 1006, and suite completion.
- Build contract and embedded configuration evidence match m3_os and all required optimization/stack settings.

### Test 1006 — PASS

- 1006A has exactly dfm_trace.psfs and no trap.zpr.
- 1006B has exactly trap.zpr and dfm_trace.psfs.
- Trace rows show handler IPSR=11 and first-trap return IPSR=11 in the required order.
- Alert callsites match test_contexts.c lines 64 and 79.
- The 1006B coredump contains r9=1006 and a valid backtrace through line 79 with no unwind error.
- Target evidence shows HANDLER_MODE PASS, ISR_RETURNED PASS, RETURNED:1006:0, and suite completion.
- Build contract requirements exactly match the embedded configuration evidence.

### Test 1007 — PASS

- Both metadata files identify type 1007, correct 1007A/1007B IDs, sessions, revision, and payload count 2.
- Both payload inventories are complete with exactly trap.zpr and dfm_trace.psfs.
- 1007A dump shows sentinel 70 and the left-path backtrace; 1007B shows sentinel 71 and the right-inner/right-path backtrace, with no unwind errors.
- Event logs contain all expected current-test rows in order, including T1007A returned trace_enabled=1 before the 1007B path; retained earlier rows precede the current window.
- Target evidence records suite begin, test begin, TRACE_RESUMED for both alerts, return 0, and suite completion.
- Build contract variant m3_os and all required settings match build configuration evidence.

### Test 1008 — PASS

- alert-metadata-1008-1790171758902.txt: Alert Type 1008, Test ID 1008, session 1790171758902, callsite test_contexts.c:86, payload count 2.
- payload_inventory: complete=true; exactly trap.zpr and dfm_trace.psfs; no errors.
- coredump-1008-1790171758902.txt: DFM_TRAP() call; r9=1008; source line 86 invokes DFM_TRAP(1008, "Test 1008", 1); ordered backtrace reaches run_tests/main/thread entry with no unwind error.
- eventlog-1008-1790171758902.txt: retained T1006/T1007 rows precede the current window; current rows contain only T1008 BEGIN before the Test 1008 alert.
- target_evidence: DFMT:BEGIN:1008:5, DFMT:REBOOT_EXPECTED:1008:dfm, boot phase=6/index=6/reboots=2, DFMT:RESUMED:1008:1009, harness trace registration PASS, and suite completion.
- build_contract/build_config_evidence: variant m3_os and CONFIG_SIZE_OPTIMIZATIONS=y, CONFIG_INIT_STACKS=y, CONFIG_THREAD_STACK_INFO=y all match.

### Test 1009 — PASS

- Metadata identifies alert/test 1009, session 1790171758940, Build-M3-Os, callsite test_contexts.c:108, and payload count 2.
- Payload inventory is complete and contains exactly trap.zpr and dfm_trace.psfs.
- Coredump shows r0=9, trap_value=9, the application chain trap_site -> service -> app_work_handler, then work_queue_main and z_thread_entry, with no unwind error.
- Eventlog contains the complete current-test rows in order: T1009 BEGIN, T1009 PATH app_work_handler -> service, T1009 DATA value=9, followed by the matching alert.
- Target evidence confirms WORK_SUBMITTED, WORK_COMPLETED, TRAP_RETURNED, RETURNED:1009:0, and suite completion.
- Build contract variant m3_os and all required settings match the embedded build configuration evidence.

### Test 1010 — PASS

- Oracle: Expected payloads are None; artifacts and payload inventory are empty.
- Target evidence: DFMT:BEGIN:1010, startup reboot marker, DFMT:RETURNED:1010:startup:ipsr=0:control=0x2, THREAD_MODE PASS, PSP_SELECTED PASS, RESUMED:1010:END, and SUITE_COMPLETE.
- Allowlisted sources register 1010 as the final startup case, arm and invoke DFM_TRAP(1010, "Test 1010", 1), then persist startup completion; no alternate 1010 payload path is present.
- Build contract m3_os requirements match embedded build configuration: CONFIG_SIZE_OPTIMIZATIONS=y, CONFIG_INIT_STACKS=y, CONFIG_THREAD_STACK_INFO=y.

### Test 1011 — PASS

- Payload inventory is complete with exactly two payloads; metadata reports alert 1011 and payload count 2.
- Coredump shows r0=11, the indirect callback target, callback chain, trap source line, and complete unwind.
- Eventlog shows prior T1009 history followed by T1011 BEGIN, DATA callback value=11, PATH callback_handler -> trap_site, and the alert in correct order.
- Target evidence proves suite begin, test execution, return code 0, and suite completion.
- Build contract and embedded config evidence match m3_os and all required settings.

### Test 1014 — PASS

- alert metadata: Test ID 1014, matching session 1790171759021, payload count 2.
- payload inventory: complete; exactly trap.zpr and dfm_trace.psfs.
- coredump: expected arguments 1–6, locals/sentinels, callsite, and four noinline frames.
- eventlog: all T1014 rows present in source order; earlier rows precede the current window.
- target evidence: m3_os begin, T1014 begin/return 0, and suite complete.
- build evidence: m3_os and all required settings match.

### Test 1016 — PASS

- 1016A has exactly dfm_trace.psfs; 1016B has exactly trap.zpr and dfm_trace.psfs; inventories are complete.
- Event logs contain all expected current-test rows in source order, including MSP/PSP context and return values.
- Coredump 1016B is valid with complete backtrace and control_after=2.
- Target evidence shows all four checks PASS and DFMT:RETURNED:1016:0.
- m3_os and all required configuration settings match the build contract.

### Test 1017 — PASS

- Metadata reports Alert Type/Test ID 1017, payload count 1, and payload number 1.
- Payload inventory contains exactly trap.zpr, is complete, and has no errors.
- Coredump identifies a DFM_TRAP call with register/local evidence and a complete backtrace through dfm_test_run_t17 at test_boundaries.c:14.
- Source disables TraceRecorder, invokes DFM_TRAP(1017, "Test 1017", 0), and checks stopped state before and after.
- Embedded target evidence is ordered: BEGIN, TRACE_STOPPED_BEFORE PASS, TRACE_STILL_STOPPED PASS, RETURNED 0.
- Build contract and configuration evidence match m3_os with all three required settings enabled.

### Test 1018 — PASS

- Metadata identifies alert 1018, session 1790171759161, callsite test_boundaries.c:51, and exactly 2 payloads.
- Complete payload inventory contains exactly trap.zpr and dfm_trace.psfs with no errors.
- Coredump contains registers, sentinel r12=0xaaaaaaaa, expected locals, and an ordered complete backtrace through dfm_t18_small_stack_thread.
- Eventlog contains all current [DFM Tests] rows in source order: BEGIN, STACK size=1536, STACK unused=1460; alert row is complete.
- Target evidence confirms stack_size=1536, unused_before=1460, unused_after=1300, thread completion, trap return, successful measurements, remaining headroom, and return 0.
- Build configuration evidence matches every required build-contract setting.

### Test 1019 — PASS

- Manifest inventory records exactly trap.zpr and dfm_trace.psfs for 1019A and 1019B, with complete=true and no errors.
- Both metadata files report Alert Type 1019, the expected test identity, correct callsite, and Payload count 2.
- Both coredumps report DFM_TRAP(), register values r7/r9=1019, fault PC in prvDfmTriggerCoredump, and complete backtraces through test_boundaries.c lines 100 and 103.
- 1019A eventlog contains T1019 BEGIN followed by T1019A MSG chars=10 formatted_max=49 and its alert.
- 1019B eventlog contains the retained earlier-test rows first, then T1019A alert, T1019B RETURN first trap completed, and T1019B alert in the required order.
- Allowlisted target evidence confirms DFMT:BEGIN:1019:12, input_bytes=10, DFMT:RETURNED:1019:0, and suite completion.
- Build contract and embedded configuration evidence match m3_os with CONFIG_SIZE_OPTIMIZATIONS, CONFIG_INIT_STACKS, and CONFIG_THREAD_STACK_INFO enabled.

### Test 1021 — PASS

- Metadata and payload inventories confirm 1021A/1021B each have exactly trap.zpr and dfm_trace.psfs.
- Coredumps contain fault data and complete backtraces; 1021B records stayed_blocked=true and wait_result=0.
- Event logs contain the required ordered rows, including T1021A RETURN high_ran=0, T1021B POST high_ran=1, and T1021B POST wait=0.
- Target evidence shows both checks PASS, return 0, and suite completion.
- Embedded build configuration satisfies all required settings.

This automated second opinion supplements, and does not replace, the manual product verdict.
