# DFM diagnostic review - Build-M3-SmallCD

- Run ID: `20260921T114333Z-9678339c`
- Generated: `2026-09-21T12:23:23+00:00`

## Overview

- **1020 — PASS:** Both alerts are structurally valid; the first trap returned before the second alert, and no coredump content appears in the allowlisted artifacts.

## Evidence

### Test 1020 — PASS

- Alerts 1020A and 1020B have type 1020, correct callsites, revision Build-M3-SmallCD, and payload count 1.
- Event logs show T1020 BEGIN, then the first alert; the second snapshot additionally shows T1020B RETURN first trap completed before alert 1020B.
- Source invokes 1020A, emits the return event, then invokes 1020B.
- Target evidence shows suite begin, DFMT BEGIN, DFMT RETURNED, and suite completion.
- Build contract requires -Os and max_coredump_size 128; embedded configuration evidence matches.

This automated second opinion supplements, and does not replace, the manual product verdict.
