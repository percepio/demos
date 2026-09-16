# DFM test execution policy

- Agents may run `python dfm_tests/run_suite.py` (including its documented
  `--variants` selection) when validating this repository.
- To run `load-zephyr-alerts.bat`, its Detect cleanup/loading steps, the
  Receiver, or Detect REST verification, the agent must ask the user for permission.
  This since the batch file resets the Detect state, so it is normally intended  for the user to invoke manually. This can be allowed explicitly by the user for agent troubleshooting.
- Never start, stop, clean, or otherwise modify the Detect server, client,
  containers, database volume, or alert directory on the user's behalf.
