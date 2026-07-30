# flutter_auditor

A command-line security & dependency audit tool for Flutter projects. Point
it at a Flutter project and it scans the Android manifest, iOS `Info.plist`,
Dart source, and `pubspec.yaml`/`pubspec.lock` for common security
misconfigurations and dependency hygiene issues — no project modification,
read-only analysis.

## Why flutter_auditor?

Most Flutter static-analysis tools focus on code quality, lints, or
performance. `flutter_auditor` is scoped narrowly to **security and
dependency hygiene** — the kind of misconfiguration that quietly ships to
production because nothing in the normal `flutter analyze` workflow looks
for it.

- **Platform-config aware, not just source-aware** — most Dart analyzers
  only look at `.dart` files. `flutter_auditor` also parses
  `AndroidManifest.xml`, the Android Network Security Configuration, backup
  rules XML, and iOS `Info.plist` — the files where most real-world
  Android/iOS misconfigurations actually live (`allowBackup`, exported
  components, ATS exceptions, missing usage descriptions).
- **No upload, no account, no server** — everything runs against files on
  disk, locally. The only network calls are read-only lookups to the public
  pub.dev API for dependency metadata (outdated/discontinued/license
  checks); your source code never leaves your machine.
- **Actionable, not just diagnostic** — every finding ships with a
  severity, the exact file (and line, where applicable), a plain-language
  description, and a concrete fix — not just a rule ID to go look up.
- **Security + dependency hygiene in one pass** — one command reports both
  security misconfigurations and dependency maintenance issues (outdated,
  discontinued, restricted-license, unused), instead of needing separate
  tools for each.
- **CI-friendly by default** — a single exit code (`--fail-on`) gates your
  pipeline; a shareable HTML report (`--html`) with charts is there when
  you want something to hand to a non-technical stakeholder.

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

### Suppressing findings

Add a `.flutter_auditor_ignore.yaml` file to the root of the project being
audited to suppress specific findings — by audit, by exact issue id, or by
a file glob (matched relative to the project root):

```yaml
# .flutter_auditor_ignore.yaml
audits:
  - android_release_signing   # suppress every finding from this audit

ids:
  - android.allow_backup      # suppress one specific, stable finding id

files:
  - test/fixtures/**          # suppress every finding under this path
```

Suppressed findings are never silently dropped — the console output shows
how many were suppressed (`ⓘ N finding(s) suppressed by
.flutter_auditor_ignore.yaml`) before the report.

## What it checks

**Android**
- `android:allowBackup` enabled
- Cleartext (HTTP) traffic permitted
- Exported activities, services, receivers, and providers
- `android:debuggable` enabled
- Manifest permissions (high/medium risk)
- Network Security Configuration (cleartext traffic, trusted user certificates)
- Missing or misconfigured backup rules / data extraction rules
- Release builds signed with the debug key, hardcoded signing credentials in `build.gradle`, and an un-gitignored `key.properties`

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

## Example output

```
╔══════════════════════════════════════════════════════════════╗
║              FLUTTER APP SECURITY & DEPENDENCY AUDIT            ║
╚══════════════════════════════════════════════════════════════╝

📁 Project   : my_app
📄 Scanned   : android/, ios/, lib/, pubspec.yaml
🕐 Date      : 2026-07-29 12:52:25

──────────────────────────────────────────────────────────────────
 SUMMARY
──────────────────────────────────────────────────────────────────
  ✗  High Risk        : 2
  ⚠  Medium Risk       : 3
  ⚠  Low Risk          : 1
  ⓘ  Maintenance       : 2   (outdated/unused deps, licenses)
  ✔  Passed Checks     : 11

  Overall Status: ⚠️  ACTION REQUIRED (high-risk issues present)

──────────────────────────────────────────────────────────────────
 ✗ HIGH RISK (2)
──────────────────────────────────────────────────────────────────

[1] Android Backup Enabled
    📍 android/app/src/main/AndroidManifest.xml
    ⚠️  The application allows Android backups.
    ✅ Fix: Set android:allowBackup="false" in AndroidManifest.xml.

[2] Exported Activity
    📍 android/app/src/main/AndroidManifest.xml
    ⚠️  Activity ".MainActivity" is exported and may be accessible by other applications.
    ✅ Fix: Ensure this Activity is exported only when required and protected with appropriate permissions.

──────────────────────────────────────────────────────────────────
 ✔ PASSED (11)
──────────────────────────────────────────────────────────────────
  ✔ Hardcoded Secrets Detection — no issues found
  ✔ Insecure Storage Detection — no issues found
  ✔ App Transport Security Audit — no issues found
  ...

══════════════════════════════════════════════════════════════════
  Scan complete: 2 high, 3 medium, 1 low, 2 maintenance item(s).
  Exit code: 1 (high-risk issues present — see --fail-on to adjust)
══════════════════════════════════════════════════════════════════
```

The `--html` report shows the same findings with a severity chart:

![HTML report](docs/html-report-screenshot.png)

## Exit codes

`0` if no issue meets the `--fail-on` threshold, `1` otherwise. Maintenance
findings (outdated/unused dependencies) never affect the exit code.

## License

MIT — see [LICENSE](LICENSE).
