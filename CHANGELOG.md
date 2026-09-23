## Unreleased

- New audit: Privacy Manifest Audit — flags required-reason APIs
  (file timestamps, boot time, disk space, active keyboards, user
  defaults) used by the app's own iOS native code but not declared in
  `PrivacyInfo.xcprivacy`, invalid reason codes, a manifest that exists
  but isn't in the Xcode project (so never bundled), and
  `NSPrivacyTracking` without tracking domains.
- Fix: the process exit code now reflects the audit result. Previously
  `flutter_auditor` always exited `0` even when findings met `--fail-on`,
  so CI pipelines never failed. Invalid usage now exits `64`.
- New: GitHub Action (`uses: thakaredipali/flutter_auditor@v1`) that runs
  the audit and uploads SARIF findings to GitHub code scanning.

## 1.3.0

- New audit: Obfuscation Audit — flags an Android release buildType that
  doesn't enable `minifyEnabled`/`isMinifyEnabled` (R8/ProGuard), and
  scripted `flutter build` release invocations (GitHub Actions workflows,
  Fastlane `Fastfile`, `codemagic.yaml`, `bitrise.yml`, `Makefile`) missing
  the `--obfuscate` flag.

## 1.2.0

- New: `--update-baseline` snapshots current findings into
  `.flutter_auditor_baseline.json`, fingerprinted by audit/file/description
  (not line number, so unrelated edits don't expire baselined findings).
  Subsequent runs never fail on baselined findings a second time —
  critical/high findings stay visible in the report so they're never
  silently forgotten (new findings print first, pre-existing ones follow
  under a "Pre-existing (baselined, non-blocking)" divider, and the
  summary breaks down new vs. pre-existing counts), while medium/low/info
  findings are fully hidden — except maintenance findings (outdated/unused
  dependencies, unused/overlarge assets), which always stay visible since
  they never affect the exit code to begin with. The console always
  reports how many were accepted.
- New: `--json <path>` writes a JSON report for scripting/CI dashboards.
- New: `--sarif <path>` writes a SARIF 2.1.0 report, for tools like GitHub
  code scanning that turn SARIF results into PR-line annotations.

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
