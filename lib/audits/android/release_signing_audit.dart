import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/gradle_helper.dart';

/// Checks the Android release signing configuration for the debug keystore
/// being used to sign release builds, signing credentials hardcoded
/// directly in build.gradle, and a key.properties file that isn't
/// excluded from version control.
class ReleaseSigningAudit extends Audit {
  /// Matches `signingConfig signingConfigs.debug` (Groovy) or
  /// `signingConfig = signingConfigs.getByName("debug")` (Kotlin DSL) —
  /// the exact pattern `flutter create` scaffolds by default, meant to be
  /// replaced with a real release signing config before shipping.
  static final _debugSigningPattern = RegExp(
    r'''signingConfig\s*=?\s*signingConfigs\.(?:debug\b|getByName\(\s*["']debug["']\s*\))''',
  );

  /// Matches a store/key password assigned a literal string value, but not
  /// a lookup into a properties map (e.g. `keystoreProperties['storePassword']`,
  /// where the keyword is a quoted map key rather than an assignment target).
  static final _hardcodedCredentialPattern = RegExp(
    r'''\b(storePassword|keyPassword)\b(?:\s*[:=]\s*|\s+)["']([^"'\n]{3,})["']''',
  );

  @override
  String get id => 'android_release_signing';

  @override
  String get name => 'Release Signing Audit';

  @override
  String get description =>
      'Checks the Android release build signing configuration for debug-key signing and hardcoded signing credentials.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final gradleFile = GradleHelper.findAppBuildGradle(context);

    if (gradleFile != null) {
      final content = await gradleFile.readAsString();

      _checkDebugSigningForRelease(content, gradleFile.path, issues);
      _checkHardcodedCredentials(content, gradleFile.path, issues);
    }

    _checkKeyPropertiesNotIgnored(context, issues);

    return AuditResult(issues: issues);
  }

  void _checkDebugSigningForRelease(
    String content,
    String file,
    List<SecurityIssue> issues,
  ) {
    final releaseBlock = GradleHelper.extractBlock(content, 'release');

    if (releaseBlock == null || !_debugSigningPattern.hasMatch(releaseBlock)) {
      return;
    }

    issues.add(
      SecurityIssue(
        id: 'android.release_signing.debug_key_for_release',
        title: 'Release Build Signed With Debug Key',
        description:
            'The release buildType uses signingConfigs.debug, the placeholder '
            'Flutter scaffolds so `flutter run --release` works before a real '
            'signing config is set up. Shipping a release build signed with '
            'the (publicly known) debug key means anyone can produce an '
            'update-compatible build of this app.',
        severity: Severity.high,
        file: file,
        recommendation:
            'Create a dedicated release signingConfig backed by a real '
            'keystore (commonly loaded from a gitignored key.properties '
            'file) and reference it from the release buildType instead of '
            'signingConfigs.debug.',
      ),
    );
  }

  void _checkHardcodedCredentials(
    String content,
    String file,
    List<SecurityIssue> issues,
  ) {
    for (final match in _hardcodedCredentialPattern.allMatches(content)) {
      final keyword = match.group(1);

      issues.add(
        SecurityIssue(
          id: 'android.release_signing.hardcoded_credential.$keyword.${match.start}',
          title: 'Hardcoded Signing Credential: $keyword',
          description:
              '$keyword is set to a literal string value directly in the '
              'build.gradle file, which is typically committed to version '
              'control.',
          severity: Severity.critical,
          file: file,
          recommendation:
              'Load $keyword from a gitignored key.properties file (or an '
              'environment variable) instead of hardcoding it in '
              'build.gradle.',
        ),
      );
    }
  }

  void _checkKeyPropertiesNotIgnored(
    ProjectContext context,
    List<SecurityIssue> issues,
  ) {
    final keyProperties = context.androidKeyProperties;

    if (!keyProperties.existsSync()) {
      return;
    }

    final gitignore = context.gitignore;
    final gitignoreLines = gitignore.existsSync()
        ? gitignore.readAsLinesSync().map((line) => line.trim())
        : const <String>[];

    final isIgnored = gitignoreLines.any(
      (line) =>
          line == 'key.properties' ||
          line == '*.properties' ||
          line.endsWith('/key.properties'),
    );

    if (isIgnored) {
      return;
    }

    issues.add(
      SecurityIssue(
        id: 'android.release_signing.key_properties_not_ignored',
        title: 'key.properties Not Git-Ignored',
        description:
            'android/key.properties holds signing credentials but does not '
            'appear to be excluded via .gitignore, risking accidental commit '
            'of the release keystore password.',
        severity: Severity.medium,
        file: keyProperties.path,
        recommendation:
            'Add key.properties (and your .jks/.keystore file) to '
            '.gitignore so signing credentials are never committed to '
            'version control.',
      ),
    );
  }
}
