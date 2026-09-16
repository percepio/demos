# DFM payload review agent protocol

This is a narrow evidence-review task. The per-test JSON manifest is the
allowlist and contains the exact authoritative oracle excerpt copied from
`dfm_test_cases.md`.

Read only:

- the manifest's embedded `oracle.markdown`;
- every path in `artifacts`;
- every path in `source_files`;
- the manifest's embedded `target_evidence`;
- `build_config`, when present.

Paths in `artifacts` and `build_config` are relative to `artifact_root`. Paths
in `source_files` are relative to `repository`.

Avoid redundant full-file reads, but a failed or truncated tool command does
not consume the right to inspect that evidence. Retry with a narrower, simpler
command until the required fact is resolved. A command failure or output-limit
message is not a product FAIL by itself.

`target_evidence` is extracted verbatim by the orchestrator from the source
target log, with original line numbers. It contains the test's complete
target-side `DFMT:` block plus suite begin/completion markers. Use those embedded
lines for execution, return, reboot/resume, context checks, and suite-completion
evidence. Do not open the referenced `serial.log` or `qemu.log`.

Do not read the complete `zephyr.config`; when the oracle directly requires a
configuration fact, query the relevant `CONFIG_` keys selectively. Otherwise,
skip `build_config`.

Prefer one simple read/search command per evidence file. Do not construct
custom PowerShell objects or large combined scripts; restricted-language mode
may reject them. If a command fails, retry the affected file with a basic
`Get-Content`, `Select-String`, or `rg` command.

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
- configuration facts only when the oracle makes them relevant.

Do not treat a host-suite PASS as payload proof. Return PASS only when every
required oracle claim is supported by the allowlisted evidence. Return FAIL for
missing, corrupt, or contradictory product evidence, but only after reasonable
narrow retries have ruled out a tool-command or output-truncation problem.
