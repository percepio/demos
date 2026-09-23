# DFM diagnostic review - Build-M3-O0

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1001 — PASS:** One alert with exactly trap.zpr and dfm_trace.psfs; payload metadata, coredump, trace ordering, target execution/return, and build contract all match.
- **1003 — PASS:** Exactly one alert and exactly the two expected payloads are present. The coredump confirms r0-r3 = 10,20,30,40, the entry trap callsite, and a complete backtrace through the caller. All current-test TraceRecorder rows are complete and ordered correctly; prior T1001 rows precede the T1003 window. Normal return and required build configuration are confirmed.
- **1012 — PASS:** Exactly one alert and exactly the two expected payloads are present. Payload, coredump, trace, execution, return, and build-contract evidence are consistent.

## Evidence

### Test 1001 — PASS

- Metadata identifies alert/test 1001, session 1790171758329, callsite test_call_chains.c:26, and payload count 2.
- Coredump contains registers, arg0..arg5 = 1..6, local_sum=21, local_xor=7, service_sentinel=10, api_sentinel=100, and the complete application backtrace in oracle order with trap callsite.
- Eventlog contains exactly four current-test [DFM Tests] rows in source order: BEGIN, ARGS a0=1, ARGS a5=6, PATH public_api -> service, PATH service -> trap_site; the alert follows them.
- Target evidence proves BEGIN, RETURNED, and SUITE_COMPLETE for test 1001.
- Payload inventory is complete and exhaustive with exactly trap.zpr and dfm_trace.psfs; build variant m3_o0 and CONFIG_NO_OPTIMIZATIONS=y match the contract.

### Test 1003 — PASS

- Metadata: Alert Type 1003, Test ID 1003, Session ID 1790171758368, Payload count 2.
- Manifest payload inventory: trap.zpr and dfm_trace.psfs only; declared count 2, complete=true, errors=[].
- Coredump registers: r0=10, r1=20, r2=30, r3=40; fault registers include pc, sp, lr, and xpsr.
- Coredump backtrace includes dfm_t03_trap_at_entry at test_call_chains.c:169, dfm_t03_test_thread at line 186, dfm_test_run_t03 at line 194, then run_tests and main.
- Source confirms DFM_TRAP(1003), four T1003 ARGS values, T1003 PATH test_thread -> trap_at_entry, and the 10/20/30/40 call.
- Eventlog contains all six T1003 rows in order: BEGIN, ARGS r0/r1/r2/r3, PATH; retained T1001 rows precede them.
- Target evidence confirms DFMT:BEGIN:1003:1 and DFMT:RETURNED:1003:0, with suite completion.
- Build contract and embedded build_config_evidence confirm variant m3_o0 and CONFIG_NO_OPTIMIZATIONS=y.

### Test 1012 — PASS

- Metadata identifies alert/test 1012, session 1790171758411, revision Build-M3-O0, callsite test_call_chains.c:351, and payload count 2.
- Complete payload inventory contains exactly trap.zpr and dfm_trace.psfs with no errors.
- Coredump shows the five application frames in order, scalar=10, wide=5000000000 with aligned register placement, text="t12-text", small=20, record tag=30 and values={1,2,3}, *pointer=40, trap_sentinel=100, and large_frame first/last values 1 and 24.
- Event log contains all six current T1012 rows in source order: BEGIN, small-to-large path, wide data, large-to-six-args path, scalar argument, and small argument. Earlier T1001/T1003 rows precede the current window.
- Embedded target evidence shows DFMT:BEGIN:1012:2, DFMT:RETURNED:1012:0, and suite completion.
- Build contract variant m3_o0 and required CONFIG_NO_OPTIMIZATIONS=y match embedded build configuration evidence.

This automated second opinion supplements, and does not replace, the manual product verdict.
