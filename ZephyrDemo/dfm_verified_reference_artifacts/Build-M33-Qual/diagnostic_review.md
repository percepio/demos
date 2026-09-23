# DFM diagnostic review - Build-M33-Qual

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1022 — PASS:** One alert has exactly the required payloads, complete coredump evidence, correct TraceRecorder events/order, passing target FP-state checks, normal return, and matching build configuration.
- **1023 — PASS:** All manifest-authorized oracle requirements are supported.

## Evidence

### Test 1022 — PASS

- Metadata identifies alert/test 1022, session 1790171759919, callsite test_m33.c:48, and payload count 2.
- Payload inventory is complete and contains exactly trap.zpr and dfm_trace.psfs.
- Coredump contains readable core registers and application backtrace frames #0 through #5 with no unwind error; FP registers are correctly not required.
- Eventlog contains all current-test [DFM Tests] rows in order: T1022 BEGIN, FPCCR=C0000000, sentinel=100, followed by the matching alert row.
- Target evidence confirms FPCCR=0xc0000000, CONTROL.FPCA active before and after, s16=100, all five checks PASS, and normal return.
- Build variant is m33_qual and every contract setting matches the embedded build configuration evidence.

### Test 1023 — PASS

- Exactly trap.zpr and dfm_trace.psfs are present; metadata reports payload count 2 and matching alert identity/session.
- Coredump contains registers, locals, ordered backtrace, and no unwind error.
- All eventlog [DFM Tests] rows are complete and ordered; T1022 rows are valid history preceding T1023.
- Target evidence confirms PSPLIM preservation, 920-byte headroom, trap return, intact guard, and intact live data.
- Build contract and embedded configuration match the required m33_qual settings.

This automated second opinion supplements, and does not replace, the manual product verdict.
