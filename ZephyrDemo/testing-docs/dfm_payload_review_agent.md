# DFM payload review agent protocol

This is a narrow evidence-review task. The per-test JSON manifest is the
allowlist and contains the exact authoritative oracle excerpt copied from
`dfm_test_cases.md`.

Read only:

- the manifest's embedded `oracle.markdown`;
- every path in `artifacts`;
- every path in `source_files`;
- every path in `target_logs`;
- `build_config`, when present.

Paths in `artifacts`, `target_logs`, and `build_config` are relative to
`artifact_root`. Paths in `source_files` are relative to `repository`.

Read each allowlisted file at most once and retain that content throughout the
review. Do not repeat `Get-Content`, and do not follow a complete read with
`Select-String` or another search of the same file. Read each target log once
and derive all required markers from that result. Do not read the complete
`zephyr.config`; when the embedded oracle directly requires a configuration
fact, query all relevant `CONFIG_` keys together in one selective command.
Otherwise, skip `build_config`.

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

Do not treat a host-suite PASS as payload proof. Conversely, a failed evidence
command is not itself a product failure if all required facts remain directly
verifiable. Return PASS only when every required oracle claim is supported by
the allowlisted evidence; otherwise return FAIL with a concise reason.
