# DFM diagnostic review - Build-M3-O0

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1001 — PASS:** All oracle requirements are supported by the allowlisted evidence.
- **1003 — PASS:** One type-1003 alert is present with complete metadata and two payloads; the coredump contains the required trap, registers, frame, arguments, and valid unwind boundary; all current TraceRecorder rows match source order and values; execution returned normally; build settings match the contract.
- **1012 — PASS:** One complete type-1012 alert is supported by valid trace, coredump, metadata, target execution/return markers, and matching -O0 configuration.

## Evidence

### Test 1001 — PASS

- Alert metadata identifies one type-1001 alert at test_call_chains.c:26 with matching Build-M3-O0 revision, session, path suffix, and two payloads (1, 2).
- Coredump confirms DFM_TRAP, required six arguments 1–6, local_sum=21, local_xor=7, sentinels, valid fault context, and the required unwind frames through dfm_t01_test_thread.
- Event log contains every current-test [DFM Tests] row in source order: BEGIN, a0=1, a5=6, public_api path, service path, followed by the matching alert.
- Target evidence confirms suite begin, test begin, normal return DFMT:RETURNED:1001:0, and suite completion.
- Build contract requires -O0; embedded build configuration evidence reports -O0.

### Test 1003 — PASS

- alert-metadata-1003-1789991014883.txt: Alert Type 1003, Test ID 1003, callsite test_call_chains.c:169, Revision Build-M3-O0, Session ID 1789991014883, Payload count 2.
- coredump-1003-1789991014883.txt: DFM_TRAP() call; r0=10, r1=20, r2=30, r3=40; frame #0 is dfm_t03_trap_at_entry at test_call_chains.c:169; frames #1-#3 complete the expected chain. The stack-marker unwind stop is permitted by the review guide.
- eventlog-1003-1789991014883.txt: All 11 [DFM Tests] rows inventoried. Earlier T1001 history precedes the T1003 window; current rows are T1003 BEGIN, r0=10, r1=20, r2=30, r3=40, and test_thread -> trap_at_entry, in source order, followed by the matching alert.
- Manifest target_evidence: DFMT:BEGIN:1003:1, DFMT:RETURNED:1003:0, and matching suite begin/completion markers.
- Manifest build_contract/build_config_evidence: variant m3_o0 and optimization -O0 match exactly.

### Test 1012 — PASS

- Event rows are complete and ordered: T1012 BEGIN; PATH small_frame -> large_frame; DATA wide=5000000000; PATH large_frame -> six_args; ARGS scalar=10; ARGS small=20; then one matching ALERT. Earlier T1001/T1003 rows precede this window as history.
- Coredump contains DFM_TRAP data, registers, locals, text t12-text, scalar 10, wide 5000000000, small 20, record tag 30 with values {1,2,3}, pointed value 40, and the required ordered frames: trap_site, six_args, large_frame, small_frame, test_thread, test entry.
- Metadata identifies Alert Type/Test ID 1012, callsite test_call_chains.c:351, session 1789991014937, revision Build-M3-O0, alert suffix /3, and payload count 2.
- Target evidence shows DFMT BEGIN:1012:2, RETURNED:1012:0, and suite completion. Build contract variant m3_o0 and required -O0 match build-config evidence.

This automated second opinion supplements, and does not replace, the manual product verdict.
