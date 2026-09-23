# DFM diagnostic review - Build-M3-NoTrace

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1025 — PASS:** Exactly one fault.zpr payload is present; the undefined-instruction fault, coredump, reboot flow, target checks, and no-trace configuration are all supported by the allowlisted evidence.
- **1026 — PASS:** Exactly one alert and one valid trap.zpr payload are evidenced; trace/fault payloads and event-log artifacts are absent as required.

## Evidence

### Test 1025 — PASS

- Complete payload inventory: one fault.zpr, no errors, and no trace or trap payload.
- Coredump verifies readable registers, udf #0 at dfm_t25_undefined_instruction, and an ordered unwind through dfm_test_run_t25.
- Target evidence confirms reason 36, both fault checks PASS, one reboot, RESUMED:1025:END, and suite completion.
- Build contract and embedded configuration match m3_no_trace with coredumps enabled and ADD_TRACE disabled.

### Test 1026 — PASS

- Metadata confirms alert/test 1026, session 1790171758240, revision Build-M3-NoTrace, and payload count 1.
- Complete payload inventory contains exactly trap.zpr with no errors or additional payloads.
- Coredump identifies a DFM_TRAP, shows DFM_TRAP(1026, "Test 1026", 0) at test_no_trace.c:13, and unwinds through dfm_test_run_t26.
- Coredump registers include r9=1026; recorder_enabled_before is true, with target checks proving enabled before and after.
- Embedded target evidence confirms suite begin, DFMT:BEGIN:1026:0, both recorder checks PASS, DFMT:RETURNED:1026:0, and suite completion.
- Embedded build configuration matches all contract requirements, including size optimization, coredumps, debug coredump backend, and ADD_TRACE disabled.
- No event-log artifact is listed, consistent with the oracle requirement for no trace payload.

This automated second opinion supplements, and does not replace, the manual product verdict.
