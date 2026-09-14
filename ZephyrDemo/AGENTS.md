# DFM test execution policy

- Agents may run `python dfm_tests/run_suite.py` (including its documented
  `--variants` selection) when validating this repository.
- Never run `dfm_tests/load_dfm_alerts.bat`, its Detect cleanup/loading steps,
  the Receiver, or Detect REST verification on the user's behalf. The batch
  file deletes the existing Detect database and alert files, so it is reserved
  for the user to invoke manually.
- Never start, stop, clean, or otherwise modify the Detect server, client,
  containers, database volume, or alert directory on the user's behalf.
