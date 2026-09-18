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
Do not open `zephyr.config`, search for additional CPU/configuration symbols, or
invent requirements absent from the contract.

The `m3_*` names identify portable common Cortex-M test profiles, not the
physical processor. They do not require `CONFIG_CPU_CORTEX_M3` and are valid on
a Cortex-M33 board. Only the `m33_qual` contract requires Cortex-M33-specific
configuration. A present `CONFIG_CPU_CORTEX_M33=y` therefore does not contradict
an `m3_*` profile.

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
- complete backtrace order and any unwind error;
- TraceRecorder events, values, and ordering;
- target-log proof of execution, return/continuation, or intentional no-alert
  behavior;
- only the configuration facts explicitly listed in `build_contract`.

TraceRecorder user events are the exported event-log lines that start with a
bracketed string (pattern `^\[[^\]]+\]`), for example `[DFM Tests]` and
`[ALERT]`. Recorder event storage is bounded, so the end of any such user-event
text may be shortened. Do not treat that shortening alone as payload
corruption, transport loss, or a missing event. Use the visible prefix for
identity and ordering, then corroborate omitted details with other allowlisted
evidence such as adjacent user events, alert metadata, coredump text,
`target_evidence`, or source. In particular, alert metadata is authoritative
for the complete alert description; the trace `[ALERT]` event is only a bounded
copy. Return FAIL only when an oracle-required fact remains unsupported or is
contradicted after this corroboration, not merely because a user-event line
ends mid-word or mid-message.

Do not treat a host-suite PASS as payload proof. Return PASS only when every
required oracle claim is supported by the allowlisted evidence. Return FAIL for
missing, corrupt, or contradictory product evidence, but only after reasonable
narrow retries have ruled out a tool-command or output-truncation problem.
