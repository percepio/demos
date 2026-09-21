# DFM diagnostic review - Build-M3-Os

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1002 — PASS:** Required alert, payload values, backtrace frames, ordered trace events, normal return, and -Os configuration are verified.
- **1004 — PASS:** One type-1004 alert is present with two payloads; coredump, trace rows, backtrace, return value, and target evidence are consistent.
- **1005 — PASS:** All allowlisted evidence matches the embedded oracle and build contract.
- **1006 — PASS:** Two intact type-1006 payloads are present and ordered. Handler/MSP context, nonzero IPSR, ISR return, trace rows, target checks, and build configuration all match the embedded oracle.
- **1007 — PASS:** Both valid type-1007 payloads are present with distinct left/right call chains, correct sentinels, complete backtraces, ordered TraceRecorder events, trace resumption, and matching -Os configuration.
- **1008 — PASS:** Build, alert metadata, coredump, trace events, reboot/resume markers, and source control flow are consistent.
- **1009 — PASS:** Payload, trace rows, timer-daemon unwind, value 9, target checks, return, and -Os configuration all match the oracle.
- **1010 — PASS:** All oracle requirements are satisfied by the allowlisted source, target evidence, and build contract evidence.
- **1011 — PASS:** One type-1011 alert is present with complete metadata and callsite; coredump and trace evidence confirm callback value 11 and the required unwind chain. Target evidence confirms normal return and suite completion.
- **1014 — PASS:** The single type-1014 alert, optimized call chain, payload data, trace rows, target execution markers, and -Os contract are consistent.
- **1016 — PASS:** Build-M3-Os satisfies the oracle for both type-1016 witnesses.
- **1017 — PASS:** The alert, valid trap dump, no TraceRecorder payload, target trace-stopped checks, normal return, and build contract all match the embedded oracle.
- **1018 — PASS:** All oracle requirements are supported by the allowlisted evidence.
- **1019 — PASS:** Both alerts and payloads are present and intact; trace events, trap callsites, return ordering, target execution markers, and -Os configuration all match the embedded oracle.
- **1021 — PASS:** Both valid DFM trap/trace payloads match the oracle and source control flow; no contradictory evidence found.
- **1025 — PASS:** The single alert is type 1025 with a fault.dmp processor-fault payload. Registers, CFSR/HFSR, undefined-instruction disassembly, complete usable backtrace, source, event ordering, reset/resume, and build settings are consistent.

## Evidence

### Test 1002 — PASS

- Alert metadata confirms type/test 1002, correct callsite, revision, session, and two payloads.
- Coredump confirms DFM_TRAP, required frames, registers, locals, and values.
- Eventlog contains every expected [DFM Tests] row exactly once in source order.
- Target evidence confirms test begin, normal return, and suite completion.
- Build contract and configuration evidence match m3_os with -Os.

### Test 1004 — PASS

- Alert metadata: type 1004, test ID 1004, Build-M3-Os, payload count 2 with payloads 1 and 2.
- Coredump references trap.dmp, reports DFM_TRAP, shows value=4000 and return_value=4404, and unwinds through dfm_t04_trap_before_return and dfm_t04_caller.
- Eventlog contains all retained T1002 history before the current T1004 window, followed by the complete ordered T1004 rows: BEGIN, input=4000, expected_return=4404, and caller -> trap_before_return; one matching ALERT follows.
- Target evidence confirms BEGIN:1004:1, CHECK:1004:PASS:CALLER_CONTINUED_ONCE, RETURNED:1004:0, with suite completion.
- Build contract requires m3_os and -Os; embedded build configuration reports -Os.

### Test 1005 — PASS

- Alert metadata confirms exactly one type-1005 alert with payloads 1 and 2.
- Coredump contains trap.dmp evidence, register/local values IPSR=0 and CONTROL=4, and the complete allowed unwind through dfm_test_run_post_init_startup to run_tests; stopping at the initial MSP boundary is oracle-permitted.
- Eventlog contains the expected startup trace and alert; no unexpected [DFM Tests] rows are present.
- Target evidence confirms startup ordering, THREAD_MODE, MSP_SELECTED, return from trap, continuation at test 1006, trace-channel registration, and suite completion.
- Build contract and embedded configuration evidence agree on variant m3_os and optimization -Os.

### Test 1006 — PASS

- Alert metadata 1006A and 1006B each reports Alert Type 1006, the correct suffix/callsite, revision Build-M3-Os, and payload count 2 with payloads 1 and 2.
- Coredump 1006A is captured in DFM_Test_IRQHandler at test_contexts.c:55; xPSR 0x4100001b proves nonzero IPSR 27, with MSP/PSP context shown. The unwind ending at the signal-handler boundary is permitted for Handler/MSP evidence.
- Coredump 1006B is captured in dfm_test_run_t06 at test_contexts.c:78 with the runner frame beneath it, proving the post-interrupt witness and return path.
- Eventlog A contains every current-test row in order: T1006 BEGIN, T1006A CTX Handler IPSR=27, ALERT 1006A. Eventlog B contains the same cumulative rows followed by T1006B RETURN first trap; IPSR=27 and ALERT 1006B. Earlier Test 1005 alert history precedes the current window.
- Source control flow matches the trace values and ordering: interrupt trigger, T1006A handler trace and trap, returned flag, T1006B witness trace, checks, and second trap.
- Embedded target evidence is ordered: suite begin, DFMT BEGIN:1006:3, HANDLER_MODE PASS, ISR_RETURNED PASS, RETURNED:1006:0, suite complete.
- Build contract requires variant m3_os and optimization -Os; embedded build configuration reports optimization -Os, with no additional contract requirement.

### Test 1007 — PASS

- Alert metadata A/B matches IDs, callsite, revision, distinct sessions, and payloads 1/2.
- Coredumps show valid DFM_TRAP payloads with A sentinel 70 and left_path; B sentinel 71 and right_inner/right_path.
- Event logs contain all [DFM Tests] rows in order; retained T1006 history precedes the T1007 window.
- Target evidence confirms BEGIN, TRACE_RESUMED for A and B, RETURNED 0, and suite completion.
- Build contract and configuration evidence both specify -Os.

### Test 1008 — PASS

- Build-M3-Os contract requires -Os; build configuration reports -Os.
- Metadata records one type-1008 alert with session 1789991015476 and two payloads.
- Coredump contains the DFM_TRAP call at test_contexts.c:85 and the runner frame at test_runner.c:321, with reboot state armed for 1008.
- All [DFM Tests] rows are ordered; retained T1006/T1007 rows precede T1008 BEGIN, and no unexpected current-test rows follow the alert.
- Target evidence shows BEGIN, REBOOT_EXPECTED, BOOT, RESUMED, and suite completion, with no harness-return failure marker.

### Test 1009 — PASS

- Alert metadata identifies type/test 1009, callsite test_contexts.c:98, Build-M3-Os, and two payloads.
- Coredump contains value 9 and the required unwind through dfm_t09_trap_site, dfm_t09_service, dfm_t09_app_work_handler, and FreeRTOS timer-daemon frames.
- Eventlog rows are complete and ordered: BEGIN, PATH timer-daemon -> service, DATA value=9, then ALERT.
- Target evidence proves WORK_SUBMITTED, WORK_COMPLETED, TRAP_RETURNED, RETURNED:1009:0, and suite completion.
- Build contract and configuration both specify -Os.

### Test 1010 — PASS

- Oracle requires Build-M3-Os, zero alerts, and a silent pre-initialization DFM_TRAP.
- Source control flow invokes dfm_test_run_pre_init_startup before DFM initialization, records IPSR/CONTROL, executes DFM_TRAP(1010), and commits startup completion state.
- Target evidence shows BEGIN:1010, startup reboot expectation, return with ipsr=0 and control=0x4, THREAD_MODE and MSP_SELECTED checks passing, RESUMED:1010:END, and SUITE_COMPLETE.
- No artifacts are listed, so there are no payload, alert, TraceRecorder, fault, register, local, or backtrace rows contradicting the zero-alert oracle.
- Build evidence matches the contract: variant m3_os and optimization -Os.

### Test 1011 — PASS

- Alert metadata: Alert Type/Test ID 1011, Description at test_call_chains.c:299, Revision Build-M3-Os, Session ID 1789991015618, path suffix /2, and payload count 2.
- Coredump: trap.dmp source is recorded; r0=11; dfm_t11_trap_site(value=11) -> dfm_t11_callback_handler(value=11) -> dfm_t11_dispatcher(value=11) -> dfm_t11_test_thread -> dfm_test_run_t11.
- Eventlog current window contains, in order, T1011 BEGIN, T1011 DATA callback value=11, T1011 PATH callback_handler -> trap_site, and the matching alert. Earlier T1009 rows precede this window as history.
- Target evidence: DFMT:BEGIN:1011:8, DFMT:RETURNED:1011:0, and suite completion marker.
- Build contract variant m3_os and optimization -Os match the embedded build configuration evidence.

### Test 1014 — PASS

- Alert metadata identifies Test 1014 at test_call_chains.c:32, revision Build-M3-Os, session 1789991015667, alert path suffix /3, and payload count 2 with payload numbers 1 and 2.
- Coredump confirms the DFM_TRAP at dfm_t01_trap_site line 32 with recovered arguments 1,2,3,4,5,6; local_sum=21, local_xor=7; service_sentinel=10; api_sentinel=100; optimized-out locals are permitted by the oracle.
- Backtrace order is dfm_t01_trap_site, dfm_t01_service, dfm_t01_public_api, dfm_t01_test_thread, dfm_test_run_reference, and dfm_test_runner_task. The reported stack boundary after the required chain is permitted by the review guide.
- All current-test event rows are present and ordered as T1014 BEGIN, ARGS a0=1, ARGS a5=6, PATH public_api -> service, PATH service -> trap_site, matching the allowlisted source. Earlier T1009 and T1011 rows precede the current window and are retained history.
- Embedded target evidence shows DFMT:BEGIN:1014:9, DFMT:RETURNED:1014:0, and matching suite begin/completion markers.
- Build contract variant m3_os requires -Os, and embedded build configuration evidence reports optimization -Os.

### Test 1016 — PASS

- Alert metadata confirms 1016A/1016B, correct callsites, distinct sessions, and two payloads each.
- Coredumps show the required trap sites, registers, xPSR/fault context, and valid required backtrace frames.
- Event logs contain every current-test [DFM Tests] row in source order; retained earlier-test rows precede the T1016 window.
- Trace values prove IPSR=0, CONTROL=0x00000004 for MSP, then trap_CTL=0x00000004 and now_CTL=0x00000006 for PSP restoration.
- Target evidence confirms BEGIN, all four PASS checks, RETURNED:1016:0, and suite completion.
- Build contract variant m3_os and required optimization -Os match embedded build-config evidence.

### Test 1017 — PASS

- Alert metadata identifies type/test 1017, callsite test_boundaries.c:14, revision Build-M3-Os, and exactly one payload.
- Coredump is a valid DFM_TRAP() dump with registers, required locals, and a call stack containing dfm_test_run_t17 at test_boundaries.c:14 and the test runner.
- No [DFM Tests] or TraceRecorder payload rows are present in the allowlisted coredump artifact.
- Target evidence shows TRACE_STOPPED_BEFORE, TRACE_STILL_STOPPED, and RETURNED:1017:0, with matching suite begin and completion markers.
- Source confirms tracing is disabled before DFM_TRAP, checked after the trap, and cleanup restart occurs only afterward.
- Build contract variant m3_os and required optimization -Os match build configuration evidence.

### Test 1018 — PASS

- Alert metadata matches type 1018, Build-M3-Os, test_boundaries.c:49, and one alert with two payloads.
- Coredump contains the required trap, registers, stack marker, and dfm_t18_small_stack_thread frame.
- Eventlog rows are complete, correctly formatted, ordered, and match the source: BEGIN, STACK size=1536, STACK unused=1456.
- Target evidence proves task completion, trap return, stack measurements, unused_after=1336, remaining headroom, and suite completion.
- The m3_os variant and required -Os optimization match build-config evidence.

### Test 1019 — PASS

- Alert metadata A/B: type 1019, IDs 1019A/1019B, descriptions at test_boundaries.c:103/:106, Build-M3-Os revision, distinct sessions, and payload count 2 with payloads 1 and 2.
- Both coredumps are DFM_TRAP() payloads with r8=1019 and call frames at source lines 103 and 106; each has the expected FreeRTOS unwind boundary after the real frames.
- Every [DFM Tests] row is accounted for: retained T1018 history precedes T1019; A contains T1019 BEGIN then the 10-character message; B additionally contains T1019B RETURN first trap completed, followed by alert B.
- Allowlisted source confirms message length 10, message formatting, first trap, return event, and second trap in the required order.
- Embedded target evidence shows DFMT:BEGIN:1019:13, input_bytes=10, DFMT:RETURNED:1019:0, and suite completion.
- Build contract m3_os with -Os matches embedded build_config_evidence; the portable Cortex-M policy is satisfied.

### Test 1021 — PASS

- Alert metadata identifies 1021A/1021B with correct callsites, revision, distinct sessions, payload counts, and payload numbers.
- Coredumps show DFM_TRAP payloads at test_contexts.c:241 and :260 with valid registers, locals, and ordered backtraces; expected stack-crop termination is present.
- Event logs contain all [DFM Tests] rows in source order, including cumulative history and current-test rows with correct formatted values and multiplicity.
- 1021A proves the high-priority task was ready while the scheduler was locked and had not run; 1021B records high_ran=1 and wait=1 after unlock.
- Target evidence shows DFMT checks HIGH_THREAD_CREATED, OUTER_LOCK_PRESERVED, and HIGH_THREAD_RAN_AFTER_UNLOCK all PASS, followed by DFMT:RETURNED:1021:0 and suite completion.
- Build contract and embedded configuration evidence agree on variant m3_os and optimization -Os.

### Test 1025 — PASS

- Alert metadata: Alert Type/Test ID 1025, one session, payload count 2.
- Coredump references fault.dmp; CFSR is 0x00010000, HFSR is 0x40000000, PC is dfm_test_run_t25+14 at udf #0, and the backtrace reaches dfm_test_run_t25 and dfm_test_runner_task.
- Allowlisted source implements T1025 with xTracePrint followed by __asm volatile("udf #0").
- Eventlog contains the ordered T1025 BEGIN and fault trace rows followed by exactly one matching alert row.
- Target evidence confirms reboot expectation, resume to 1009, trace channel registration, and suite completion.
- Build contract and build-config evidence both specify variant m3_os with -Os optimization.

This automated second opinion supplements, and does not replace, the manual product verdict.
