import 'dart:io';

import '../../data/required_reason_apis.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/info_plist_helper.dart';

/// Checks the app's PrivacyInfo.xcprivacy privacy manifest against the
/// required-reason APIs its own native code (ios/Runner) uses.
///
/// Only the Runner target is scanned: Flutter plugins ship their own
/// privacy manifests, so APIs used inside plugins are their
/// responsibility, not the app's.
class PrivacyManifestAudit extends Audit {
  static const _manifestName = 'PrivacyInfo.xcprivacy';
  static const _sourceExtensions = ['.swift', '.m', '.mm'];

  @override
  String get id => 'ios_privacy_manifest';

  @override
  String get name => 'Privacy Manifest Audit';

  @override
  String get description =>
      'Checks that PrivacyInfo.xcprivacy exists, is bundled, and declares an approved reason for every required-reason API the app\'s native code uses.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];
    final runnerDirectory = context.iosRunnerDirectory;

    if (!runnerDirectory.existsSync()) {
      return AuditResult(issues: issues);
    }

    final usages = await _findRequiredReasonApiUsages(runnerDirectory);
    final manifestFile = _findManifest(runnerDirectory);

    if (manifestFile == null) {
      if (usages.isEmpty) {
        issues.add(
          SecurityIssue(
            id: 'ios.privacy_manifest.missing',
            title: 'No Privacy Manifest',
            description:
                'The app has no $_manifestName. None of its own native code uses a required-reason API, so App Store Connect will not reject it for this, but a manifest is the place to declare tracking and collected data types.',
            severity: Severity.info,
            file: runnerDirectory.path,
            recommendation:
                'Add $_manifestName to the Runner target in Xcode (File > New > File > App Privacy) if the app tracks users or collects data.',
          ),
        );
      }

      for (final usage in usages) {
        issues.add(_undeclaredApiIssue(usage, manifestMissing: true));
      }

      return AuditResult(issues: issues);
    }

    _checkBundled(context, manifestFile, issues);

    final manifest = await InfoPlistHelper.loadFile(manifestFile);

    if (manifest == null) {
      issues.add(
        SecurityIssue(
          id: 'ios.privacy_manifest.parse_error',
          title: 'Unable to Parse Privacy Manifest',
          description:
              '"${manifestFile.path}" could not be parsed as an XML property list.',
          severity: Severity.low,
          file: manifestFile.path,
          recommendation:
              'Open the file in Xcode and verify it is a valid property list.',
        ),
      );
      return AuditResult(issues: issues);
    }

    final declaredReasons = _declaredReasons(manifest);

    for (final usage in usages) {
      if (!declaredReasons.containsKey(usage.api.category)) {
        issues.add(_undeclaredApiIssue(usage, manifestMissing: false));
      }
    }

    for (final api in requiredReasonApis) {
      final reasons = declaredReasons[api.category];
      if (reasons == null) {
        continue;
      }

      final invalid = reasons.difference(api.validReasons);
      if (reasons.isEmpty || invalid.isNotEmpty) {
        issues.add(
          SecurityIssue(
            id: 'ios.privacy_manifest.invalid_reason.${api.category}',
            title: 'Invalid Required-Reason Declaration',
            description: reasons.isEmpty
                ? '${api.category} is declared without any reason code.'
                : '${api.category} declares unrecognized reason code(s): ${invalid.join(', ')}.',
            severity: Severity.medium,
            file: manifestFile.path,
            recommendation:
                'Use one or more of Apple\'s approved reasons for this category: ${api.validReasons.join(', ')}.',
          ),
        );
      }
    }

    final tracking = manifest['NSPrivacyTracking'] == true;
    final trackingDomains = manifest['NSPrivacyTrackingDomains'];
    if (tracking && (trackingDomains is! List || trackingDomains.isEmpty)) {
      issues.add(
        SecurityIssue(
          id: 'ios.privacy_manifest.tracking_domains_missing',
          title: 'Tracking Enabled Without Tracking Domains',
          description:
              'NSPrivacyTracking is true but NSPrivacyTrackingDomains lists no domains. iOS blocks connections to undeclared tracking domains until the user grants tracking permission, so undeclared ones are neither disclosed nor gated.',
          severity: Severity.low,
          file: manifestFile.path,
          recommendation:
              'List every domain the app contacts for tracking in NSPrivacyTrackingDomains, or set NSPrivacyTracking to false if the app does not track users.',
        ),
      );
    }

    return AuditResult(issues: issues);
  }

  File? _findManifest(Directory runnerDirectory) {
    for (final entity in runnerDirectory.listSync(recursive: true)) {
      if (entity is File && entity.uri.pathSegments.last == _manifestName) {
        return entity;
      }
    }
    return null;
  }

  /// A manifest that isn't referenced by the Xcode project is never copied
  /// into the app bundle, so Apple never sees it — a common mistake when the
  /// file is created outside Xcode.
  void _checkBundled(
    ProjectContext context,
    File manifestFile,
    List<SecurityIssue> issues,
  ) {
    final project = context.iosXcodeProject;
    if (!project.existsSync()) {
      return;
    }

    if (!project.readAsStringSync().contains(_manifestName)) {
      issues.add(
        SecurityIssue(
          id: 'ios.privacy_manifest.not_bundled',
          title: 'Privacy Manifest Not Included in Xcode Project',
          description:
              '$_manifestName exists on disk but is not referenced by Runner.xcodeproj, so it is not copied into the app bundle and App Store Connect never sees it.',
          severity: Severity.medium,
          file: manifestFile.path,
          recommendation:
              'In Xcode, add $_manifestName to the Runner target (drag it into the Runner group and tick "Runner" under Target Membership).',
        ),
      );
    }
  }

  /// Maps each declared `NSPrivacyAccessedAPIType` to its reason codes.
  Map<String, Set<String>> _declaredReasons(Map<String, dynamic> manifest) {
    final result = <String, Set<String>>{};
    final entries = manifest['NSPrivacyAccessedAPITypes'];

    if (entries is! List) {
      return result;
    }

    for (final entry in entries) {
      if (entry is! Map) {
        continue;
      }

      final category = entry['NSPrivacyAccessedAPIType'];
      final reasons = entry['NSPrivacyAccessedAPITypeReasons'];

      if (category is! String) {
        continue;
      }

      result.putIfAbsent(category, () => {}).addAll([
        if (reasons is List) ...reasons.whereType<String>(),
      ]);
    }

    return result;
  }

  /// Returns the first usage of each required-reason API category found in
  /// the Runner's Swift/Objective-C sources.
  Future<List<_ApiUsage>> _findRequiredReasonApiUsages(
    Directory runnerDirectory,
  ) async {
    final usages = <String, _ApiUsage>{};

    final sourceFiles = runnerDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => _sourceExtensions.any(file.path.endsWith));

    for (final file in sourceFiles) {
      final lines = await file.readAsLines();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//') || line.startsWith('*')) {
          continue;
        }

        for (final api in requiredReasonApis) {
          if (!usages.containsKey(api.category) && api.pattern.hasMatch(line)) {
            usages[api.category] = _ApiUsage(api, file.path, i + 1);
          }
        }
      }
    }

    return usages.values.toList();
  }

  SecurityIssue _undeclaredApiIssue(
    _ApiUsage usage, {
    required bool manifestMissing,
  }) {
    return SecurityIssue(
      id: 'ios.privacy_manifest.undeclared_api.${usage.api.category}',
      title: 'Undeclared Required-Reason API: ${usage.api.displayName}',
      description: manifestMissing
          ? 'Native code uses a ${usage.api.displayName.toLowerCase()} API, which Apple requires to be declared in $_manifestName, but the app has no privacy manifest. App Store Connect rejects such uploads (ITMS-91053).'
          : 'Native code uses a ${usage.api.displayName.toLowerCase()} API, but $_manifestName does not declare ${usage.api.category}. App Store Connect rejects such uploads (ITMS-91053).',
      severity: Severity.medium,
      file: usage.file,
      line: usage.line,
      recommendation:
          'Declare ${usage.api.category} under NSPrivacyAccessedAPITypes in $_manifestName with an approved reason (${usage.api.validReasons.join(', ')}), or remove the API call.',
    );
  }
}

class _ApiUsage {
  final RequiredReasonApi api;
  final String file;
  final int line;

  const _ApiUsage(this.api, this.file, this.line);
}
