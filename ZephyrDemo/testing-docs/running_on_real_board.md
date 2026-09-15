# Running the DFM suite on a physical board

The board must be compatible with the selected tests and provide a Zephyr
console that can be captured continuously across target resets. Board
selection and compatibility are the operator's responsibility.

1. Connect the board and start VS Code Serial Monitor with the board's console
   settings. Enable logging to one persistent text file before starting the
   suite. The log file must already exist and must be outside
   `build/dfm_tests/` and `dfm_test_artifacts/`.
   For B-U585I-IOT02A, select the onboard ST-LINK virtual COM port and use
   115200 baud, 8 data bits, no parity, and 1 stop bit.
2. Run the suite with the Zephyr board name and Serial Monitor log path:

   ```powershell
   python dfm_tests/run_suite.py `
     --board b_u585i_iot02a `
     --serial-log C:\temp\zephyr-board-serial.log `
     --runner openocd
   ```

   `--runner` is optional. Without it, `west flash` uses the board's default
   runner. Use `--variants m3_os` or another listed variant for a focused run.
   To build and execute one test case only, let the harness select its owning
   variant automatically:

   ```powershell
   python dfm_tests/run_suite.py `
     --testcase 1016 `
     --board b_u585i_iot02a `
     --serial-log C:\temp\zephyr-board-serial.log `
     --runner openocd
   ```

   `--testcase` and `--variants` are mutually exclusive.

For each selected variant, the harness performs a pristine build, records a
new position in the external serial log, flashes the image, and follows newly
appended data. It proceeds only after observing a fresh
`DFMT:SUITE_BEGIN:<variant>:<run-id>` and the matching
`DFMT:SUITE_COMPLETE:<variant>:<run-id>`. The matching ELF, configuration, and
captured serial slice are saved under `dfm_test_artifacts/<build-label>/` as
`zephyr.elf`, `zephyr.config`, and `serial.log`.

Suite completion proves that target sequencing ended, but it does not hide a
recovered test crash. Any `DFMT:HARNESS_FAIL` or failed `DFMT:CHECK` marker in
the captured image log makes `run_suite.py` return failure. The host also
requires the exact expected number and types of decodable serialized DFM alert
headers for the selected tests. Missing, damaged, or unexpected headers make
the run fail; Test 1010 is the explicit zero-alert case.

The harness never truncates or writes the external Serial Monitor log. A new
run cookie is compiled into all images in each physical-board invocation; it
invalidates stale `.noinit` test state from an earlier invocation while
remaining stable across the intentional target resets within the current run.

Running without `--board` retains the automatic `qemu_cortex_m3` behavior.
The current `m3_*` names are historical build-configuration labels; choosing a
different board changes the actual build target. Tests 1022 and 1023 remain
planned and will not run until their target fixtures and suite variant have
been implemented.
