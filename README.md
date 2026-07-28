# flutter_auditor

A command-line security & dependency audit tool for Flutter projects. Point
it at a Flutter project and it scans the Android manifest, iOS `Info.plist`,
Dart source, and `pubspec.yaml`/`pubspec.lock` for common security
misconfigurations and dependency hygiene issues — no project modification,
read-only analysis.

## Installation

```bash
dart pub global activate flutter_auditor
```

Or run it from source without installing:

```bash
dart run bin/flutter_auditor.dart audit
```

## Usage

Run from the root of the Flutter project you want to audit:

```bash
flutter_auditor audit
```

### Options

| Flag | Description |
| --- | --- |
| `-v`, `--verbose` | Show full detail for low-risk and maintenance findings (collapsed by default). |
| `--fail-on <severity>` | Minimum severity that causes a non-zero exit code: `critical`, `high` (default), `medium`, `low`, `info`, or `none`. |
| `--html <path>` | Write an HTML report (with charts) to the given path, e.g. `--html audit_report.html`. |
| `--open` | Open the generated HTML report in the default browser after writing it. |

Example:

```bash
flutter_auditor audit --html audit_report.html --open --fail-on medium
```

## What it checks

**Android**
- `android:allowBackup` enabled
- Cleartext (HTTP) traffic permitted
- Exported activities, services, receivers, and providers
- `android:debuggable` enabled
- Manifest permissions (high/medium risk)
- Network Security Configuration (cleartext traffic, trusted user certificates)
- Missing or misconfigured backup rules / data extraction rules

**iOS**
- App Transport Security exceptions (arbitrary loads, weak minimum TLS version)
- `UIFileSharingEnabled` exposing the Documents directory
- Missing, empty, or mismatched usage-description strings (camera, location, etc.)

**Cross-platform (Dart source)**
- Hardcoded secrets (API keys, tokens, credentials, private keys)
- Insecure network usage (cleartext URLs, disabled certificate validation, WebView SSL bypass)
- Insecure storage (sensitive data in `SharedPreferences` or unencrypted Hive boxes)

**Dependencies**
- Outdated, discontinued, or unlicensed/restricted-license packages
- An outdated Dart SDK constraint (pre-null-safety)
- Dependencies declared in `pubspec.yaml` but never imported

## Exit codes

`0` if no issue meets the `--fail-on` threshold, `1` otherwise. Maintenance
findings (outdated/unused dependencies) never affect the exit code.

## License

MIT — see [LICENSE](LICENSE).
