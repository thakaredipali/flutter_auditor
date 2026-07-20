import 'package:flutter_audit/utils/android_manifest_helper.dart';

import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';

class CleartextTrafficAudit extends Audit {
  @override
  String get id => 'android_cleartext_traffic';

  @override
  String get name => 'Cleartext Traffic Enabled';

  @override
  String get description =>
      'Checks whether cleartext (HTTP) traffic is allowed.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final manifest = context.androidManifest;

    if (!await manifest.exists()) {
      return const AuditResult(issues: []);
    }
final document = await AndroidManifestHelper.load(context);

if (document == null) {
  return const AuditResult(issues: []);
}

final application =
    document.rootElement.getElement('application');

if (application == null) {
  return const AuditResult(issues: []);
}

final cleartext =
    application.getAttribute(
      'usesCleartextTraffic',
      namespace: 'http://schemas.android.com/apk/res/android',
    );
    
    if (cleartext != 'true') {
      return const AuditResult(issues: []);
    }

    return AuditResult(
      issues: [
        SecurityIssue(
          id: id,
          title: name,
          description:
              'The application allows unencrypted HTTP traffic.',
          severity: Severity.high,
          file: manifest.path,
          recommendation:
              'Set android:usesCleartextTraffic="false" or use a Network Security Configuration.',
        ),
      ],
    );
  }
}