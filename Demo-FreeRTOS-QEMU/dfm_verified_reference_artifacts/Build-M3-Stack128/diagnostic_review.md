# DFM diagnostic review - Build-M3-Stack128

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1024 — PASS:** Allowlisted evidence matches the oracle for Build-M3-Stack128.

## Evidence

### Test 1024 — PASS

- Alert metadata confirms type/test 1024, callsite test_call_chains.c:30, revision, session, and two payloads.
- Coredump contains valid DFM_TRAP data, expected arguments/locals, and the required trap_site → service → public_api → test_thread backtrace within the 128-byte limit.
- All current [DFM Tests] event rows are complete, ordered, and match the allowlisted source; the alert row matches metadata.
- Target evidence proves execution, normal return, and suite completion. Build settings match -O0 and stack_dump_size 128.

This automated second opinion supplements, and does not replace, the manual product verdict.
