import '../../data/usage_description_rule.dart';
import '../../data/usage_description_rules.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/info_plist_helper.dart';
import '../../utils/pubspec_helper.dart';

/// Checks Info.plist usage-description strings (NSCameraUsageDescription,
/// NSLocationWhenInUseUsageDescription, ...): keys present but left blank,
/// Apple-mandated key pairings that are missing, and keys missing entirely
/// for permissions the app's dependencies actually request.
class UsageDescriptionAudit extends Audit {
  @override
  String get id => 'ios_usage_descriptions';

  @override
  String get name => 'Usage Description Audit';

  @override
  String get description =>
      'Checks Info.plist for empty, mismatched, or missing usage-description strings for permissions the app requests.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final plist = await InfoPlistHelper.load(context);

    if (plist == null) {
      return AuditResult(issues: issues);
    }

    final file = context.iosInfoPlist.path;
    final alreadyFlaggedMissing = <String>{};

    _checkEmptyValues(plist, file, issues);
    _checkRequiredPairings(plist, file, issues, alreadyFlaggedMissing);
    await _checkMissingForUsedPackages(
      context,
      plist,
      file,
      issues,
      alreadyFlaggedMissing,
    );

    return AuditResult(issues: issues);
  }

  bool _isBlank(dynamic value) => value is! String || value.trim().isEmpty;

  /// 1. Flags a usage-description key that is present but has an empty (or
  /// whitespace-only) string value.
  void _checkEmptyValues(
    Map<String, dynamic> plist,
    String file,
    List<SecurityIssue> issues,
  ) {
    for (final rule in usageDescriptionRules) {
      if (!plist.containsKey(rule.key)) {
        continue;
      }

      if (_isBlank(plist[rule.key])) {
        issues.add(
          SecurityIssue(
            id: 'ios.usage_description.empty.${rule.key}',
            title: 'Empty Usage Description: ${rule.key}',
            description:
                '${rule.key} is present in Info.plist but has an empty value. iOS shows this blank string to the user in the permission prompt, and Apple can reject the app during review.',
            severity: Severity.medium,
            file: file,
            recommendation:
                'Provide a clear, non-empty explanation of why the app needs ${rule.capability} access.',
          ),
        );
      }
    }
  }

  /// 3. Flags a key that Apple requires to be paired with another key that
  /// is missing (e.g. "Always" location requires "When In Use" location).
  void _checkRequiredPairings(
    Map<String, dynamic> plist,
    String file,
    List<SecurityIssue> issues,
    Set<String> alreadyFlaggedMissing,
  ) {
    for (final rule in usageDescriptionRules) {
      if (_isBlank(plist[rule.key])) {
        continue;
      }

      for (final pairedKey in rule.requiresAlsoPresent) {
        if (_isBlank(plist[pairedKey])) {
          issues.add(
            SecurityIssue(
              id: 'ios.usage_description.missing_pairing.${rule.key}',
              title: 'Missing Paired Usage Description: $pairedKey',
              description:
                  'Info.plist sets ${rule.key} but does not also set $pairedKey. Apple requires both keys together, otherwise the permission request fails silently at runtime.',
              severity: Severity.high,
              file: file,
              recommendation:
                  'Add $pairedKey to Info.plist alongside ${rule.key}.',
            ),
          );
          alreadyFlaggedMissing.add(pairedKey);
        }
      }
    }
  }

  /// 2. Flags a usage-description key that is missing entirely while a
  /// pubspec.yaml dependency that requires it is present.
  Future<void> _checkMissingForUsedPackages(
    ProjectContext context,
    Map<String, dynamic> plist,
    String file,
    List<SecurityIssue> issues,
    Set<String> alreadyFlaggedMissing,
  ) async {
    final dependencies = await PubspecHelper.loadDependencyNames(context);

    if (dependencies.isEmpty) {
      return;
    }

    for (final UsageDescriptionRule rule in usageDescriptionRules) {
      if (!_isBlank(plist[rule.key]) ||
          alreadyFlaggedMissing.contains(rule.key)) {
        continue;
      }

      final matchedPackage = rule.requiredByPackages.firstWhere(
        dependencies.contains,
        orElse: () => '',
      );

      if (matchedPackage.isEmpty) {
        continue;
      }

      issues.add(
        SecurityIssue(
          id: 'ios.usage_description.missing.${rule.key}',
          title: 'Missing Usage Description: ${rule.key}',
          description:
              'The app depends on "$matchedPackage", which requires ${rule.capability} access, but Info.plist does not define ${rule.key}. iOS will crash the app when this capability is requested.',
          severity: Severity.high,
          file: file,
          recommendation: rule.recommendation,
        ),
      );
    }
  }
}
