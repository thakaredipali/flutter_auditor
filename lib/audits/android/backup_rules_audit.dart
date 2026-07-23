import 'dart:io';

import 'package:flutter_audit/models/audit.dart';
import 'package:flutter_audit/models/audit_result.dart';
import 'package:flutter_audit/models/project_context.dart';
import 'package:flutter_audit/models/security_issue.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:flutter_audit/utils/android_manifest_helper.dart';
import 'package:xml/xml.dart';

class BackupRulesAudit extends Audit {
  static const _androidNamespace =
      'http://schemas.android.com/apk/res/android';

  @override
  String get id => 'backup_rules';

  @override
  String get name => 'Backup Rules Audit';

  @override
  String get description =>
      'Checks Android backup configuration and validates referenced backup rule files.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final manifest = await AndroidManifestHelper.load(context);

    if (manifest == null) {
      return AuditResult(issues: issues);
    }

    final applications = manifest.findAllElements('application');

    if (applications.isEmpty) {
      return AuditResult(issues: issues);
    }

    final application = applications.first;

    final allowBackup = application.getAttribute(
      'allowBackup',
      namespace: _androidNamespace,
    );

    final fullBackupContent = application.getAttribute(
      'fullBackupContent',
      namespace: _androidNamespace,
    );

    final dataExtractionRules = application.getAttribute(
      'dataExtractionRules',
      namespace: _androidNamespace,
    );

    if (allowBackup == 'false') {
      return AuditResult(issues: issues);
    }

    if (fullBackupContent == null) {
      issues.add(
        SecurityIssue(
          id: 'android.backup_rules.missing_full_backup_content',
          severity: Severity.medium,
          title: 'Missing Backup Rules',
          description:
              'Backups are enabled but no fullBackupContent configuration is specified.',
          recommendation:
              'Specify android:fullBackupContent or disable backups if not required.',
          file: context.androidManifest.path,
        ),
      );
    } else {
      _validateXmlReference(
        context: context,
        reference: fullBackupContent,
        issueId: 'android.backup_rules.missing_backup_rules_file',
        title: 'Missing Backup Rules File',
        issues: issues,
      );
    }

    if (dataExtractionRules != null) {
      _validateXmlReference(
        context: context,
        reference: dataExtractionRules,
        issueId: 'android.backup_rules.missing_data_extraction_rules',
        title: 'Missing Data Extraction Rules',
        issues: issues,
      );
    }

    return AuditResult(issues: issues);
  }

  void _validateXmlReference({
    required ProjectContext context,
    required String reference,
    required String issueId,
    required String title,
    required List<SecurityIssue> issues,
  }) {
    if (!reference.startsWith('@xml/')) {
      return;
    }

    final fileName = reference.replaceFirst('@xml/', '');

    final file = File(
      '${context.rootPath}/android/app/src/main/res/xml/$fileName.xml',
    );

    if (!file.existsSync()) {
      issues.add(
        SecurityIssue(
          id: issueId,
          severity: Severity.medium,
          title: title,
          description:
              'The manifest references "$reference", but the file does not exist.',
          recommendation:
              'Create the referenced XML file or remove the manifest attribute.',
          file: context.androidManifest.path,
        ),
      );
    }
  }
}