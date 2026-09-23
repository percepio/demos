# DFM diagnostic review - Build-M3-Retained

- Run ID: `20260923T135555Z-9052a3b1`
- Generated: `2026-09-23T14:29:29+00:00`

## Overview

- **1027 — PASS:** Exactly one 1027B alert was transmitted with the required two payloads; trace ordering, trap callsite, backtrace, reboot/resume markers, and build contract all match.
- **1028 — PASS:** No alert or payload is expected; corruption was injected and rejected, the test resumed at END, and the suite completed.

## Evidence

### Test 1027 — PASS

- Metadata confirms Alert Type 1027, Test ID 1027B, source test_contexts.c:96, session 1790171759540, and payload count 2.
- Complete payload inventory contains exactly trap.zpr and dfm_trace.psfs; no fault.zpr or additional payloads.
- Coredump confirms DFM_TRAP(), registers r6/r9=1027, complete unwind without error, and DFM_TRAP(1027, "Test 1027B", 1) at test_contexts.c:96.
- Event log contains every current-test row in order: T1027 BEGIN, T1027 RETAIN BEGIN, ALERT 1027A, T1027 RETAIN END, ALERT 1027B.
- Allowlisted source confirms the two traps and TraceRecorder calls, with the 1027 case registered as DFM_REBOOT.
- Embedded target evidence confirms RETAINED_ALERT:FOUND, RETAINED_ALERT:SENT, one reboot, RESUMED:1027:1028, trace channel registration, and suite completion.
- All required build-contract settings match the embedded build configuration evidence; m3_retained is valid under the stated portable Cortex-M policy.

### Test 1028 — PASS

- Oracle and manifest inventory require zero alerts and zero payloads; artifacts and payload_inventory are empty.
- Target evidence confirms BEGIN:1028, REBOOT_EXPECTED, CORRUPTION_INJECTED PASS, CORRUPTION_REJECTED PASS, BOOT with reboots=2, RESUMED:1028:END, and SUITE_COMPLETE.
- Allowlisted source confirms a data-byte-only corruption, checksum-based rejection/clearing, and the 1028 DFM reboot flow.
- All required build-contract settings exactly match build_config_evidence for m3_retained.

This automated second opinion supplements, and does not replace, the manual product verdict.
