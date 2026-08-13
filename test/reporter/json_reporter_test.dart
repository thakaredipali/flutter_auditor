import 'dart:convert';

import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/json_reporter.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

class _FakeAudit extends Audit {
  _FakeAudit(this.id, this.name);

  @override
  final String id;

  @override
  final String name;

  @override
  String get description => 'Fake audit for testing.';

  @override
  Future<AuditResult> run(ProjectContext context) async =>
      const AuditResult(issues: []);
}

void main() {
  group('JsonReporter', () {
    test('produces valid JSON with the expected finding fields', () async {
      final context = await createProjectContextWithFiles(files: {});
      final issue = SecurityIssue(
        id: 'android.allow_backup',
        title: 'Android Backup Enabled',
        description: 'The application allows Android backups.',
        severity: Severity.high,
        file: '${context.rootPath}/android/app/src/main/AndroidManifest.xml',
        line: 12,
        recommendation: 'Set android:allowBackup="false".',
      );
      final results = [
        AuditRunResult(
          audit: _FakeAudit('android.allow_backup', 'Allow Backup Audit'),
          result: AuditResult(issues: [issue]),
        ),
      ];

      final json = const JsonReporter().generateJson(results, context: context);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['summary']['total'], 1);
      expect(decoded['summary']['high'], 1);
      expect(decoded['summary']['medium'], 0);

      final finding =
          (decoded['findings'] as List).single as Map<String, dynamic>;
      expect(finding['auditId'], 'android.allow_backup');
      expect(finding['severity'], 'high');
      expect(finding['file'], 'android/app/src/main/AndroidManifest.xml');
      expect(finding['line'], 12);
      expect(finding['recommendation'], 'Set android:allowBackup="false".');
    });

    test('produces an empty findings list when there are no issues', () async {
      final context = await createProjectContextWithFiles(files: {});

      final json = const JsonReporter().generateJson([], context: context);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['findings'], isEmpty);
      expect(decoded['summary']['total'], 0);
    });
  });
}
