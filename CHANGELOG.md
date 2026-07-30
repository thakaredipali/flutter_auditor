## 1.1.0

- New audit: Release Signing Audit — flags a release build signed with the
  debug key, hardcoded signing credentials in `build.gradle`, and an
  un-gitignored `key.properties`.
- New audit: Unused Asset Audit — flags assets declared in `pubspec.yaml`
  that no Dart file references.
- New audit: Overlarge Asset Audit — flags declared assets large enough to
  meaningfully bloat the app bundle (≥1 MB medium, ≥5 MB high).
- New: suppression mechanism via a `.flutter_auditor_ignore.yaml` file at
  the project root — suppress findings by audit, exact issue id, or file
  glob. Suppressed findings are never silent: the console reports how many
  were suppressed before the report.

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
