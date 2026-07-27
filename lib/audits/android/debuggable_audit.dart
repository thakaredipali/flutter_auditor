import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';

class DebuggableAudit extends Audit {
  @override
  String get id => 'android_debuggable';

  @override
  String get name => 'Android Debuggable Enabled';

  @override
  String get description =>
      'Checks whether the application is debuggable in AndroidManifest.xml.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final manifest = context.androidManifest;

    if (!await manifest.exists()) {
      return const AuditResult(issues: []);
    }

    final content = await manifest.readAsString();

    if (!content.contains('android:debuggable="true"')) {
      return const AuditResult(issues: []);
    }

    return AuditResult(
      issues: [
        SecurityIssue(
          id: id,
          title: name,
          description:
              'The application is debuggable. This should be disabled for production builds.',
          severity: Severity.high,
          file: manifest.path,
          recommendation: 'Remove android:debuggable="true".',
        ),
      ],
    );
  }
}
