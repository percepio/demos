# DFM diagnostic review - Build-M3-Stack128

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1024 — FAIL:** The oracle requires GDB to stop at 0x20003b4c after recovering public_api; the coredump reports stopping at 0x20003af4. Other reviewed evidence matched: exact two payloads, metadata, trace rows/order, call-chain values, target execution/return markers, and build settings.

## Evidence

### Test 1024 — FAIL

- Oracle: mapped live-stack interval 0x20003ac8..0x20003b48 and backtrace stop at 0x20003b4c.
- dfm_test_artifacts/Build-M3-Stack128/coredump-1024-1790171759806.txt: Backtrace stopped: Cannot access memory at address 0x20003af4.
- The coredump recovered dfm_t01_trap_site, dfm_t01_service, and dfm_t01_public_api, but the stop address contradicts the oracle.

This automated second opinion supplements, and does not replace, the manual product verdict.
