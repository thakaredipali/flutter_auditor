## 1.0.0

Initial release.

- Android audits: `allowBackup`, cleartext traffic, exported components,
  debuggable flag, manifest permissions, Network Security Configuration,
  and backup/data-extraction rules.
- iOS audits: App Transport Security exceptions, `UIFileSharingEnabled`,
  and usage-description strings (empty, mismatched, or missing).
- Cross-platform source scans: hardcoded secrets, insecure network usage
  (cleartext URLs, disabled certificate validation, WebView SSL bypass),
  and insecure storage (`SharedPreferences`, unencrypted Hive boxes).
- Dependency hygiene: outdated/discontinued/restricted-license packages,
  an outdated Dart SDK constraint, and unused dependencies.
- Console report with severity-grouped findings and a pass/fail exit code.
- HTML report (`--html`) with a severity donut chart and category bar
  chart, viewable offline; `--open` launches it in the browser.
