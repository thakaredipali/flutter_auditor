import 'package:flutter_auditor/data/android_permissions.dart';
import 'package:flutter_auditor/data/permission_info.dart';
import 'package:flutter_auditor/data/permission_risk.dart';
import 'package:xml/xml.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/android_manifest_helper.dart';

class ManifestPermissionAudit extends Audit {
  @override
  String get id => 'android_manifest_permissions';

  @override
  String get name => 'Android Manifest Permissions';

  @override
  String get description =>
      'Checks AndroidManifest.xml for high, medium, and low risk permissions.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final document = await AndroidManifestHelper.load(context);

    if (document == null) {
      return const AuditResult(issues: []);
    }

    final issues = <SecurityIssue>[];

    const androidNamespace = 'http://schemas.android.com/apk/res/android';

    final permissionLookup = {
      for (final permission in allAndroidPermissions)
        permission.permission: permission,
    };

    final permissions = document.findAllElements('uses-permission');

    for (final permissionElement in permissions) {
      final permissionName = permissionElement.getAttribute(
        'name',
        namespace: androidNamespace,
      );

      if (permissionName == null) {
        continue;
      }

      final permissionInfo = permissionLookup[permissionName];

      if (permissionInfo == null) {
        continue;
      }
      
      if (permissionInfo.risk == PermissionRisk.low) {
        // TODO: Ignore for now.
        continue;
       }

      issues.add(
        SecurityIssue(
          id: '${id}_$permissionName',
          title: permissionName.split('.').last,
          description: permissionInfo.reason,
          severity: _mapSeverity(permissionInfo),
          file: context.androidManifest.path,
          recommendation: permissionInfo.recommendation,
        ),
      );
    }

    return AuditResult(issues: issues);
  }

  Severity _mapSeverity(PermissionInfo permission) {
    switch (permission.risk) {
      case PermissionRisk.high:
        return Severity.high;

      case PermissionRisk.medium:
        return Severity.medium;

      case PermissionRisk.low:
        return Severity.low;
    }
  }
}