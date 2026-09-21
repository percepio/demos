# DFM diagnostic review - Build-M33-Qual

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1022 — PASS:** All authoritative oracle claims are satisfied by the allowlisted evidence.
- **1023 — PASS:** Required payloads, metadata, coredump, trace rows, target checks, source behavior, and build settings all match.

## Evidence

### Test 1022 — PASS

- Metadata confirms one type-1022 alert, exact callsite, matching revision/session, and two payloads.
- Coredump is present with readable registers and an unwind through dfm_t22_active_fp_trap; target evidence authoritatively confirms s16=100.
- Every [DFM Tests] event-log row matches the allowlisted source in order and format.
- Target evidence shows all five checks passing, normal return, and suite completion.
- Build configuration matches the contract: STM32U585 target, -O0, and max coredump size 2048.

### Test 1023 — PASS

- Alert metadata identifies type/test 1023 with two payloads and callsite test_m33.c:117.
- Coredump contains DFM_TRAP(), dfm_t23_protected_stack_task at test_m33.c:117, and required register/local evidence.
- All current T1023 event rows match source order and formatting; earlier T1022 rows precede the current window.
- Target evidence confirms PSPLIM restoration, 968-byte headroom, stack guard, live data, trap return, task completion, and all required checks.
- Build target, -O0 optimization, and 2048-byte coredump settings match the contract.

This automated second opinion supplements, and does not replace, the manual product verdict.
