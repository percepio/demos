# DFM payload review agent protocol

This is a narrow evidence-review task. The per-test JSON manifest is the
allowlist and contains the exact authoritative oracle excerpt copied from
`dfm_test_cases.md`.

Read only:

- the manifest's embedded `oracle.markdown`;
- every path in `artifacts`;
- every path in `source_files`;
- the manifest's embedded `target_evidence`;
- the embedded `build_contract` and `build_config_evidence`.

Paths in `artifacts` are relative to `artifact_root`. Paths in `source_files`
are relative to `repository`.

Avoid redundant full-file reads, but a failed or truncated tool command does
not consume the right to inspect that evidence. Retry with a narrower, simpler
command until the required fact is resolved. A command failure or output-limit
message is not a product FAIL by itself.

`target_evidence` is extracted verbatim by the orchestrator from the source
target log, with original line numbers. It contains the test's complete
target-side `DFMT:` block plus suite begin/completion markers. Use those embedded
lines for execution, return, reboot/resume, context checks, and suite-completion
evidence. Do not open the referenced `serial.log` or `qemu.log`.

Use `build_contract` as the complete list of variant/configuration requirements
and compare its `required_settings` with the embedded `build_config_evidence`.
Do not open `build-config.json`, search for additional configuration values, or
invent requirements absent from the contract.

The `m3_*` names identify portable common Cortex-M build profiles, not the
physical processor, and are also valid on STM32U585/Cortex-M33. Only the
`m33_qual` contract requires the STM32U585 hard-float/PSPLIM target.

Use only simple Windows PowerShell commands to inspect the allowlisted files:

- read a complete text or JSON file with
  `Get-Content -Raw -LiteralPath '<exact path>'`;
- search within one file with
  `Select-String -LiteralPath '<exact path>' -SimpleMatch -Pattern '<text>'`;
- add `-Context <before>,<after>` to `Select-String` when surrounding lines are
  needed;
- check a listed path with `Test-Path -LiteralPath '<exact path>'` only when a
  read reports that it is missing.

Use one command per evidence file and preserve the manifest's exact paths. Do
not use `rg`, `grep`, `find`, `findstr`, Python helper scripts, directory
listings, or repository-wide search commands. These tools may be unavailable
in the review process and broader searches violate the evidence allowlist. Do
not construct custom PowerShell objects or large combined scripts;
restricted-language mode may reject them. If a command fails or is truncated,
retry the affected file with a narrower `Get-Content` or `Select-String`
command.

Do not scan directories, search the repository for the test ID, read other
Markdown or historical reports, inspect the raw ELF, hash files, or investigate
build-system files. The exported coredump text already records the ELF used by
GDB. If an allowlisted file is missing, truncated, or contradictory, identify
that evidence gap and return FAIL instead of widening the search.

Check only the expectations relevant to the embedded oracle:

- alert identity, suffixes, sessions, revisions, payload types, and counts;
- registers, exception/fault state, arguments, locals, and sentinels;
- the backtrace order and frames explicitly required by the oracle;
- every `[DFM Tests]` event in each event-log artifact, including its complete
  text, formatted values, multiplicity, and ordering;
- target-log proof of execution, return/continuation, or intentional no-alert
  behavior;
- only the configuration facts explicitly listed in `build_contract`.

TraceRecorder user events are the exported event-log lines that start with a
bracketed channel name, for example `[DFM Tests]` and `[ALERT]`. Excluding that
exported channel label, the fixtures keep every fully formatted event text on
these two channels below 50 characters, so the text is expected to be complete.

For every listed event-log artifact:

1. Inventory every `[DFM Tests]` row in file order; do not inspect only the
   `[ALERT]` row or only rows that happen to support one oracle claim.
2. Identify the current test window from its `T<test-id> BEGIN` row when that
   row is expected to survive, the source control flow, and the alert capture
   point. In a two-alert test, account for the cumulative rows visible in the
   first and second snapshots.
3. Compare every current-test row with all reachable `xTracePrint` and
   `xTracePrintF` calls in the allowlisted source. Require every row that should
   have executed before that snapshot, its fully formatted value, correct
   multiplicity, and source order. An unexpected, duplicated, missing,
   misordered, truncated, or contradictory current-test row is a FAIL.
4. Classify rows for earlier test IDs as retained ring-buffer history. They
   must precede the current test window and must not contradict its session or
   ordering, but they are not substitutes for current-test evidence.

Alert metadata is authoritative for the complete description. The `[ALERT]`
copy must contain the same short test ID and appended callsite without
truncation. Retry a narrower read if tool output, rather than the artifact,
appears truncated; otherwise a shortened `[DFM Tests]` or `[ALERT]` row is a
product-evidence failure.

Do not treat a host-suite PASS as payload proof. Return PASS only when every
required oracle claim is supported by the allowlisted evidence. Return FAIL for
missing, corrupt, or contradictory product evidence, but only after reasonable
narrow retries have ruled out a tool-command or output-truncation problem.

FreeRTOS-specific unwind boundaries are expected evidence, not automatic
corruption. `DFM_STACK_MARKER()` deliberately crops a task dump before the
synthetic task-entry context, so GDB may report `Backtrace stopped` immediately
after the last real task frame. The Zephyr-compatible trap script also asks for
fixed frames 2 through 6; `No frame at level` is harmless when a shorter valid
chain already contains every frame required by the oracle. Likewise, a
Handler/MSP dump may end at `<signal handler called>` because the interrupted
task uses a separate PSP stack. Treat these messages as a failure only when an
oracle-required frame is absent, the error occurs inside the required chain, or
other evidence shows that the payload itself is malformed.
