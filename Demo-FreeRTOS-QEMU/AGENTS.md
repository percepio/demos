# DFM test execution policy

- Agents may run `python dfm_tests/run_suite.py` with
  `--skip-payload-processing`, including focused variants and test cases, when
  validating this repository.
- Running `load-freertos-alerts.bat --dry-run` is allowed because it changes no
  files, processes, containers, or Detect state.
- Before running the loader without `--dry-run`, the Receiver, or Detect REST
  verification, an agent must obtain explicit user permission. A full loader
  invocation resets Detect state and is normally for the user to run manually.
- Never start, stop, clean, or otherwise modify the Detect server, client,
  containers, database volume, or alert directory without that permission.
