# Host device-log architecture and FreeRTOS porting notes

## Zephyr change summary

The host test runner now has two mutually exclusive device-output sources that
remain fixed for an entire suite invocation:

- `--com PORT` for physical hardware. A missing value defaults to
  `auto-detect` when the board name does not contain `qemu`.
- `--devicelog FILE` for QEMU. A missing value defaults to
  `qemu_last_session.log` when the board name contains `qemu`.

Physical capture no longer depends on VS Code Serial Monitor or an externally
named session log. The Python runner uses pyserial at the board-specific baud
rate (460800 for `b_u585i_iot02a`, 115200 by default for other boards), opens
the selected port before every flash, mirrors all decoded target output into
the console and `dfm_test_run.log`, and preserves exact bytes in each artifact
directory's `serial.log`.

Auto-detection enumerates current ports, sorts numbered COM ports descending,
and probes each after the first test image has been built. For each candidate,
the runner opens the port and starts its reader before flashing that image, so
a blank board or an unrelated previous application does not deadlock
discovery. It then waits for at most five seconds after flashing. A port is
accepted only when the case-sensitive substring `Percepio` appears in its
first 1024 received bytes. The successful detection flash and its already-open
reader become the authoritative first run capture; no second flash or stream
reset occurs after selection. An unsuccessful full pass produces a warning
and the search repeats. The selected port is retained for every variant; a
later open/read failure fails the affected run instead of changing devices
silently.

The firmware supplies stable discovery text from `main()`:

```text
Starting Percepio Detect test
Starting Percepio Detect demo
```

`main()` waits one second before emitting this text. The probe reader is
started before flashing, so this delay is an additional USB/UART reset margin
rather than the primary protection against lost startup output.

The serial reader runs concurrently with `west flash`, preventing early boot
text from being lost. It recognizes a variant's `DFMT:SUITE_BEGIN` run ID and
requires the matching `DFMT:SUITE_COMPLETE`. Existing exact alert-count,
description-length, and target-failure checks remain in place. The runner
recalculates each Serial DFM block's CRC-16/CCITT before declaring the variant
successful. Nonzero mismatches and malformed/incomplete blocks fail the run;
checksum `0` explicitly disables the comparison for that block. The runner
also emits `TEST PASS`/`TEST FAIL` for each selected case and a single final
`SUITE PASS`/`SUITE FAIL`.

## FreeRTOS sister-project port

Reuse the host-side pieces rather than reintroducing an external serial-log
producer:

1. Copy or share the CLI source-selection rules, pyserial dependency, numeric
   COM sorting, build-then-flash discovery, five-second/1024-byte probe, and
   threaded serial capture.
2. Keep the FreeRTOS suite's selected COM port fixed across every image in one
   invocation.
3. Add a startup line containing `Percepio`, with distinct wording for its
   test harness and ordinary demo application.
4. Adapt only the target begin/completion regular expressions if the FreeRTOS
   marker namespace differs from `DFMT`.
5. During discovery, build the first image, open each candidate serial port,
   then flash while its reader is active. Keep the successful reader and flash
   as the authoritative first run, and retain that uninterrupted byte stream
   in a stable per-image artifact path.
6. Preserve the two logging levels: exact target bytes in the artifact and
   human-readable orchestration plus target output in the suite log.
7. Port the unit tests for descending order, marker splitting, first-1-KiB
   rejection, rescan after a failed pass, mutually exclusive source options,
   and complete byte capture.

Do not couple the reusable reader to Zephyr's `west`, QEMU process ownership,
or DFM alert decoding. Those remain orchestration adapters around the common
device-output source.
