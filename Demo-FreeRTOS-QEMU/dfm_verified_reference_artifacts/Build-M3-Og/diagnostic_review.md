# DFM diagnostic review - Build-M3-Og

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1013 — PASS:** All allowlisted evidence matches the embedded oracle and -Og build contract.

## Evidence

### Test 1013 — PASS

- One type-1013 alert is present with payloads 1 and 2.
- Coredump shows the expected trap site, arguments 1–6, locals local_sum=21 and local_xor=7, registers, and complete relevant call chain.
- Eventlog contains all six current-test rows in source order: BEGIN, two ARGS, two PATH, and ALERT; no contradictory history rows.
- Target evidence confirms m3_og execution, return code 0, and suite completion.
- Allowlisted source confirms T1013 trace messages, call-chain order, trap 1013, and return 0; build evidence confirms -Og.

This automated second opinion supplements, and does not replace, the manual product verdict.
