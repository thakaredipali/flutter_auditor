import 'dart:io';

import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/gradle_helper.dart';

/// Checks whether release builds are shrunk/obfuscated: Android's R8 (via
/// `minifyEnabled`) for the Android build, and Dart's `--obfuscate` flag for
/// any scripted `flutter build` release invocations found in common CI/build
/// automation files.
class ObfuscationAudit extends Audit {
  static final _minifyEnabledPattern = RegExp(
    r'''(?:minifyEnabled|isMinifyEnabled)\s*=?\s*(true|false)''',
  );

  /// Matches a `flutter build` invocation for a target that produces an
  /// AOT-compiled, `--obfuscate`-eligible artifact. `web` is excluded since
  /// Flutter web doesn't support the flag.
  static final _flutterBuildPattern = RegExp(
    r'flutter\s+build\s+(apk|appbundle|aab|ios|ipa|macos|linux|windows)\b',
  );

  /// CI/build automation files commonly used to script `flutter build`
  /// invocations. Only files that actually exist are scanned. Paths are
  /// relative to the project root.
  static const _buildScriptPaths = [
    'fastlane/Fastfile',
    'codemagic.yaml',
    'bitrise.yml',
    'Makefile',
  ];

  /// How far past a `flutter build` match to look for a paired
  /// `--obfuscate` flag, to stay within the same (possibly multi-line,
  /// backslash-continued) shell command without spilling into unrelated
  /// steps later in the file.
  static const _obfuscateSearchWindow = 400;

  @override
  String get id => 'obfuscation';

  @override
  String get name => 'Obfuscation Audit';

  @override
  String get description =>
      'Checks that release builds are shrunk/obfuscated: Android R8/ProGuard (minifyEnabled) and the Dart --obfuscate flag for scripted flutter build invocations.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    _checkAndroidMinification(context, issues);
    await _checkDartObfuscateFlag(context, issues);

    return AuditResult(issues: issues);
  }

  void _checkAndroidMinification(
    ProjectContext context,
    List<SecurityIssue> issues,
  ) {
    final gradleFile = GradleHelper.findAppBuildGradle(context);

    if (gradleFile == null) {
      return;
    }

    final content = gradleFile.readAsStringSync();
    final releaseBlock = GradleHelper.extractBlock(content, 'release');

    if (releaseBlock == null) {
      return;
    }

    final match = _minifyEnabledPattern.firstMatch(releaseBlock);
    final isEnabled = match != null && match.group(1) == 'true';

    if (isEnabled) {
      return;
    }

    issues.add(
      SecurityIssue(
        id: 'obfuscation.android_minify_disabled',
        title: 'Android Release Build Not Minified/Obfuscated',
        description:
            'The release buildType does not enable minifyEnabled (R8), so '
            'the Android build ships unshrunk and unobfuscated Java/Kotlin '
            'bytecode, making the app easier to reverse-engineer and '
            'inflating its size.',
        severity: Severity.medium,
        file: gradleFile.path,
        recommendation:
            'Set minifyEnabled true (Groovy) or isMinifyEnabled = true '
            '(Kotlin DSL) on the release buildType, with a proguardFiles '
            'entry for any rules your app or plugins need to keep.',
      ),
    );
  }

  Future<void> _checkDartObfuscateFlag(
    ProjectContext context,
    List<SecurityIssue> issues,
  ) async {
    for (final file in _buildScriptFiles(context)) {
      final content = await file.readAsString();

      for (final match in _flutterBuildPattern.allMatches(content)) {
        final windowEnd = (match.end + _obfuscateSearchWindow).clamp(
          0,
          content.length,
        );
        final window = content.substring(match.start, windowEnd);

        if (window.contains('--obfuscate')) {
          continue;
        }

        issues.add(
          SecurityIssue(
            id: '${id}_${file.path}_${match.start}',
            title: 'Scripted Release Build Missing --obfuscate',
            description:
                'A "flutter build ${match.group(1)}" invocation in '
                '${file.path} does not pass --obfuscate '
                '--split-debug-info=<dir>, so the compiled Dart AOT code '
                'keeps its original class/method/field names, making the '
                'app easier to reverse-engineer.',
            severity: Severity.low,
            file: file.path,
            recommendation:
                'Add --obfuscate --split-debug-info=<dir> to this build '
                'command and store the generated debug symbols so stack '
                'traces from obfuscated crash reports can be symbolicated.',
          ),
        );
      }
    }
  }

  /// GitHub Actions workflow YAML files, plus the other well-known CI/build
  /// automation files in [_buildScriptPaths], for whichever of them exist.
  Iterable<File> _buildScriptFiles(ProjectContext context) sync* {
    final workflowsDir = Directory('${context.rootPath}/.github/workflows');

    if (workflowsDir.existsSync()) {
      for (final entity in workflowsDir.listSync()) {
        if (entity is File &&
            (entity.path.endsWith('.yml') || entity.path.endsWith('.yaml'))) {
          yield entity;
        }
      }
    }

    for (final relativePath in _buildScriptPaths) {
      final file = File('${context.rootPath}/$relativePath');

      if (file.existsSync()) {
        yield file;
      }
    }
  }
}
