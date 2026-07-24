import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../../data/license_policy.dart';
import '../../data/locked_dependency.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/pub_dev_client.dart';
import '../../utils/pub_lock_helper.dart';

/// Checks direct pub.dev dependencies for outdated versions, discontinued
/// status, and license compliance risk, plus the project's own SDK
/// constraint for pre-null-safety Dart versions.
///
/// The outdated/discontinued/license checks call the pub.dev API and
/// degrade silently (skip, no issue) on network failure or an unrecognized
/// package, so a flaky connection never fails the audit.
class DependencyHygieneAudit extends Audit {
  static final _nullSafetyMinSdk = Version(2, 12, 0);

  final PubDevClient _client;

  DependencyHygieneAudit({PubDevClient? client})
    : _client = client ?? PubDevClient();

  @override
  String get id => 'dependency_hygiene';

  @override
  String get name => 'Dependency Hygiene Audit';

  @override
  String get description =>
      'Checks dependencies for outdated versions, discontinued packages, license compliance risk, and an outdated project SDK constraint.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    await _checkProjectSdkConstraint(context, issues);

    final dependencies = await PubLockHelper.loadLockedDependencies(context);

    final directHosted = dependencies
        .where((dependency) => dependency.isDirectMain && dependency.isHosted)
        .toList();

    await Future.wait(
      directHosted.map(
        (dependency) => _checkDependency(dependency, context, issues),
      ),
    );

    return AuditResult(issues: issues);
  }

  Future<void> _checkProjectSdkConstraint(
    ProjectContext context,
    List<SecurityIssue> issues,
  ) async {
    if (!await context.pubspec.exists()) {
      return;
    }

    final dynamic document;
    try {
      document = loadYaml(await context.pubspec.readAsString());
    } catch (_) {
      return;
    }

    if (document is! YamlMap) {
      return;
    }

    final environment = document['environment'];

    if (environment is! YamlMap) {
      return;
    }

    final sdkConstraintString = environment['sdk'];

    if (sdkConstraintString is! String) {
      return;
    }

    VersionConstraint constraint;
    try {
      constraint = VersionConstraint.parse(sdkConstraintString);
    } catch (_) {
      return;
    }

    if (constraint is! VersionRange || constraint.min == null) {
      return;
    }

    if (constraint.min! < _nullSafetyMinSdk) {
      issues.add(
        SecurityIssue(
          id: 'dependency_hygiene.old_sdk_constraint',
          title: 'Very Old Dart SDK Constraint',
          description:
              'The project\'s SDK constraint ("$sdkConstraintString") allows Dart SDK versions below 2.12.0, which predates sound null safety.',
          severity: Severity.high,
          file: context.pubspec.path,
          recommendation:
              'Raise the environment.sdk lower bound to 2.12.0 or higher so the project can rely on sound null safety.',
        ),
      );
    }
  }

  Future<void> _checkDependency(
    LockedDependency dependency,
    ProjectContext context,
    List<SecurityIssue> issues,
  ) async {
    final results = await Future.wait([
      _client.fetchPackageInfo(dependency.name),
      _client.fetchMetrics(dependency.name),
    ]);

    final file = context.pubspec.path;

    _checkOutdated(dependency, results[0], file, issues);

    final tags = _extractTags(results[1]);

    if (tags == null) {
      return;
    }

    _checkDiscontinued(dependency, tags, file, issues);
    _checkLicense(dependency, tags, file, issues);
  }

  void _checkOutdated(
    LockedDependency dependency,
    Map<String, dynamic>? packageInfo,
    String file,
    List<SecurityIssue> issues,
  ) {
    if (packageInfo == null) {
      return;
    }

    final latest = packageInfo['latest'];

    if (latest is! Map<String, dynamic>) {
      return;
    }

    final latestVersionString = latest['version'];

    if (latestVersionString is! String) {
      return;
    }

    Version current;
    Version latestVersion;
    try {
      current = Version.parse(dependency.version);
      latestVersion = Version.parse(latestVersionString);
    } catch (_) {
      return;
    }

    if (current >= latestVersion) {
      return;
    }

    final majorVersionsBehind = latestVersion.major - current.major;

    if (majorVersionsBehind >= 2) {
      issues.add(
        SecurityIssue(
          id: 'dependency_hygiene.outdated_major.${dependency.name}',
          title: 'Dependency Significantly Outdated: ${dependency.name}',
          description:
              '${dependency.name} is on v$current, while v$latestVersion is available '
              '($majorVersionsBehind major versions behind).',
          severity: Severity.medium,
          file: file,
          recommendation:
              'Review the changelog and consider upgrading — you may be missing '
              'important fixes or security patches.',
        ),
      );
    } else if (majorVersionsBehind >= 1) {
      issues.add(
        SecurityIssue(
          id: 'dependency_hygiene.outdated_minor.${dependency.name}',
          title: 'Newer Major Version Available: ${dependency.name}',
          description:
              '${dependency.name} is on v$current, while v$latestVersion is available.',
          severity: Severity.low,
          file: file,
          recommendation: 'Not urgent — review when convenient.',
        ),
      );
    }
  }

  Set<String>? _extractTags(Map<String, dynamic>? metrics) {
    if (metrics == null) {
      return null;
    }

    final score = metrics['score'];

    if (score is! Map<String, dynamic>) {
      return null;
    }

    final tags = score['tags'];

    if (tags is! List) {
      return null;
    }

    return tags.map((tag) => tag.toString()).toSet();
  }

  void _checkDiscontinued(
    LockedDependency dependency,
    Set<String> tags,
    String file,
    List<SecurityIssue> issues,
  ) {
    if (!tags.contains('is:discontinued')) {
      return;
    }

    issues.add(
      SecurityIssue(
        id: 'dependency_hygiene.discontinued.${dependency.name}',
        title: 'Discontinued Dependency: ${dependency.name}',
        description:
            '${dependency.name} is marked as discontinued on pub.dev and will not receive further updates or security fixes.',
        severity: Severity.high,
        file: file,
        recommendation:
            'Replace ${dependency.name} with an actively maintained alternative.',
      ),
    );
  }

  void _checkLicense(
    LockedDependency dependency,
    Set<String> tags,
    String file,
    List<SecurityIssue> issues,
  ) {
    String? licenseTag;
    for (final tag in tags) {
      if (tag.startsWith('license:')) {
        licenseTag = tag;
        break;
      }
    }

    if (licenseTag == null) {
      issues.add(
        SecurityIssue(
          id: 'dependency_hygiene.no_license.${dependency.name}',
          title: 'No License Detected: ${dependency.name}',
          description:
              'pub.dev could not detect a license for ${dependency.name}, so its terms of use cannot be verified.',
          severity: Severity.low,
          file: file,
          recommendation:
              'Manually verify ${dependency.name}\'s license before shipping it in the app.',
        ),
      );
      return;
    }

    final licenseId = licenseTag.substring('license:'.length);

    if (restrictedLicenseIds.contains(licenseId)) {
      issues.add(
        SecurityIssue(
          id: 'dependency_hygiene.restricted_license.${dependency.name}',
          title: 'Restricted License: ${dependency.name} ($licenseId)',
          description:
              '${dependency.name} is licensed under $licenseId, a copyleft license that may impose obligations on how the app can be distributed.',
          severity: Severity.medium,
          file: file,
          recommendation:
              'Have legal/compliance review the $licenseId license terms for ${dependency.name} before shipping.',
        ),
      );
    }
  }
}
