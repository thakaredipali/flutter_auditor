import 'dart:io';

import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';

/// Checks whether android:allowBackup is enabled.
class AllowBackupAudit extends Audit {
  @override
  String get id => 'android.allow_backup';

  @override
  String get name => 'Allow Backup Audit';

  @override
  String get description =>
      'Checks whether android:allowBackup is enabled in AndroidManifest.xml.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final File manifest = context.androidManifest;

    if (!manifest.existsSync()) {
      return const AuditResult(
        issues: [],
      );
    }

    final content = await manifest.readAsString();

    final hasAllowBackup =
        content.contains('android:allowBackup="true"');

    if (!hasAllowBackup) {
      return const AuditResult(
        issues: [],
      );
    }

    return AuditResult(
      issues: [
        SecurityIssue(
          id: id,
          title: 'Android Backup Enabled',
          description:
              'The application allows Android backups.',
          severity: Severity.high,
          file: manifest.path,
          recommendation:
              'Set android:allowBackup="false" in AndroidManifest.xml.',
        ),
      ],
    );
  }
}