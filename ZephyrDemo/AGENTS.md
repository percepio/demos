# DFM test execution policy

- Agents may run `python dfm_tests/run_suite.py` (including its documented
  `--variants` selection) when validating this repository.
- Never run `load-zephyr-alerts.bat`, `dfm_tests/load_dfm_alerts.bat`, their
  Detect cleanup/loading steps, the Receiver, or Detect REST verification on
  the user's behalf. These batch files reset Detect state, so they are
  reserved for the user to invoke manually.
- Never start, stop, clean, or otherwise modify the Detect server, client,
  containers, database volume, or alert directory on the user's behalf.
