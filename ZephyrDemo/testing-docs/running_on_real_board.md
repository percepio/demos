# Running the DFM suite on a physical board

The board must be compatible with the selected tests and provide a Zephyr
console at 115200 baud, 8 data bits, no parity, and 1 stop bit. Board selection
and compatibility remain the operator's responsibility. VS Code Serial Monitor
must be closed because the Python harness needs exclusive access to the port.

Physical-board mode uses
[pyserial](https://pyserial.readthedocs.io/) to enumerate and read serial ports.
Install the checked dependency in the Python environment used to launch the
suite if it is not already present:

```powershell
python -m pip install -r dfm_tests/requirements.txt
```

Run the suite with the Zephyr board name. `--com auto-detect` is the default
for every board name that does not contain `qemu`, but spelling it out makes
the selected input mode clear:

```powershell
python dfm_tests/run_suite.py `
  --board b_u585i_iot02a `
  --com auto-detect `
  --runner openocd
```

`--runner` is optional. Without it, `west flash` uses the board's default
runner. Use `--variants m3_os` for a focused variant or `--testcase 1016` to
build and run one test case. `--testcase` and `--variants` are mutually
exclusive.

For `b_u585i_iot02a`, the board default is `stm32cubeprogrammer`. If its CLI is
not installed, select `--runner openocd`. Select `--runner jlink` only when a
J-Link that supports the STM32 target is physically connected. In particular,
a probe identified as `J-Link OB-SAM3U128-V2-NordicSemi` is the restricted
on-board probe from a Nordic development board, not a general STM32 probe.
Seeing a J-Link software version proves only that the executable was found; it
does not prove that a compatible probe or target connection was found.

When a flash fails, stop the suite and run the exact `west flash` command shown
in `dfm_test_run.log` directly. This removes the concurrent COM reader from the
experiment and preserves the flash tool's diagnostics. To inspect the runners
available to an already configured build, use:

```powershell
west flash --context --build-dir build/dfm_tests/<variant>
```

Auto-detection enumerates all available serial devices and tries COM ports in
descending numeric order. For every candidate it:

1. opens the port at 115200 baud, 8-N-1;
2. starts the serial reader;
3. flashes the first successfully built test image, causing a fresh startup;
4. waits for data for at most five seconds after the flash; and
5. accepts the port only if `Percepio` occurs within its first 1024 bytes.

If no candidate matches, the harness logs a warning and starts another pass
from the highest COM number. It continues until interrupted or a candidate
matches. The firmware prints `Starting Percepio Detect
test` at normal test-app startup and `Starting Percepio Detect demo` in demo
mode after a one-second startup delay. The serial reader is already active
before flashing begins, and the delay adds margin for USB/UART re-enumeration
after reset. The detection flash is necessary when the board is blank or
contains a different application. Once a port matches, the harness flashes
the image again while performing the authoritative per-image capture. The
selected port is then locked for the entire suite; it is not auto-detected
again or silently changed between variants.

An explicit port skips marker-based discovery while keeping the same direct
Python capture:

```powershell
python dfm_tests/run_suite.py `
  --board b_u585i_iot02a `
  --com COM17 `
  --testcase 1016 `
  --runner openocd
```

The harness opens the locked port before every `west flash`, so target output
that starts immediately after reset is retained. Every byte read from the
port is streamed to the terminal and `dfm_test_run.log`. The exact raw bytes
for each image are also saved as
`dfm_test_artifacts/<build-label>/serial.log`. The host requires a fresh
`DFMT:SUITE_BEGIN:<variant>:<run-id>` and its matching
`DFMT:SUITE_COMPLETE:<variant>:<run-id>`.

Suite completion does not hide a recovered test crash. Any
`DFMT:HARNESS_FAIL` or failed `DFMT:CHECK` marker makes the run fail. The host
also requires the exact expected number and types of decodable serialized DFM
alert headers. It prints a distinct `TEST PASS` or `TEST FAIL` line for every
selected case and one final `SUITE PASS` or `SUITE FAIL` line.

A new run cookie is compiled into all images in each physical-board invocation.
It invalidates stale `.noinit` test state from an earlier invocation while
remaining stable across intentional target resets. Physical-board runs include
the hardware-only `m33_qual` variant by default, so the board must support
Armv8-M Mainline, an FPU, FPU context sharing, and hardware stack protection
to run the complete suite. Use `--variants` when running the M3 variants on a
board that does not provide those features.

Tests 1022 and 1023 are implemented in `m33_qual`. The variant has been build
validated for `b_u585i_iot02a`; a physical run is still required to collect
the alert, coredump, and manual unwind evidence.

## QEMU input mode

Any board name containing `qemu` selects QEMU mode. Its device log defaults to
`qemu_last_session.log`; the equivalent explicit command is:

```powershell
python dfm_tests/run_suite.py `
  --board qemu_cortex_m3 `
  --devicelog qemu_last_session.log
```

`--com` and `--devicelog` are mutually exclusive. The chosen setting remains
fixed for the complete suite. The default QEMU run excludes the hardware-only
`m33_qual` variant, and explicitly selecting it in QEMU mode is rejected.
