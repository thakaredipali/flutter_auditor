import 'dart:convert';

import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/sarif_reporter.dart';
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

SecurityIssue _issue({
  required String id,
  required String file,
  required Severity severity,
  int? line,
}) {
  return SecurityIssue(
    id: id,
    title: 'Title',
    description: 'Description for $id',
    severity: severity,
    file: file,
    line: line,
    recommendation: 'Fix it',
  );
}

void main() {
  group('SarifReporter', () {
    test('produces a valid SARIF 2.1.0 document shape', () async {
      final context = await createProjectContextWithFiles(files: {});
      final results = [
        AuditRunResult(
          audit: _FakeAudit('android.allow_backup', 'Allow Backup Audit'),
          result: AuditResult(
            issues: [
              _issue(
                id: 'android.allow_backup',
                file: '${context.rootPath}/android/AndroidManifest.xml',
                severity: Severity.high,
                line: 5,
              ),
            ],
          ),
        ),
      ];

      final sarif = const SarifReporter().generateSarif(
        results,
        context: context,
      );
      final decoded = jsonDecode(sarif) as Map<String, dynamic>;

      expect(decoded['version'], '2.1.0');
      final run = (decoded['runs'] as List).single as Map<String, dynamic>;
      expect(run['tool']['driver']['name'], 'flutter_auditor');

      final rules = run['tool']['driver']['rules'] as List;
      expect(rules, hasLength(1));
      expect(rules.single['id'], 'android.allow_backup');

      final sarifResults = run['results'] as List;
      final result = sarifResults.single as Map<String, dynamic>;
      expect(result['ruleId'], 'android.allow_backup');
      expect(result['level'], 'error');

      final location = (result['locations'] as List).single['physicalLocation'];
      expect(
        location['artifactLocation']['uri'],
        'android/AndroidManifest.xml',
      );
      expect(location['region']['startLine'], 5);
    });

    test('maps severities to SARIF levels correctly', () async {
      final context = await createProjectContextWithFiles(files: {});
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a', 'A'),
          result: AuditResult(
            issues: [
              _issue(
                id: 'crit',
                file: '${context.rootPath}/lib/x.dart',
                severity: Severity.critical,
              ),
              _issue(
                id: 'med',
                file: '${context.rootPath}/lib/x.dart',
                severity: Severity.medium,
              ),
              _issue(
                id: 'low',
                file: '${context.rootPath}/lib/x.dart',
                severity: Severity.low,
              ),
            ],
          ),
        ),
      ];

      final sarif = const SarifReporter().generateSarif(
        results,
        context: context,
      );
      final decoded = jsonDecode(sarif) as Map<String, dynamic>;
      final sarifResults = (decoded['runs'] as List).single['results'] as List;
      final levels = sarifResults
          .map((r) => (r as Map<String, dynamic>)['level'])
          .toList();

      expect(levels, ['error', 'warning', 'note']);
    });

    test('omits the region when the issue has no line', () async {
      final context = await createProjectContextWithFiles(files: {});
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a', 'A'),
          result: AuditResult(
            issues: [
              _issue(
                id: 'a.one',
                file: '${context.rootPath}/pubspec.yaml',
                severity: Severity.medium,
              ),
            ],
          ),
        ),
      ];

      final sarif = const SarifReporter().generateSarif(
        results,
        context: context,
      );
      final decoded = jsonDecode(sarif) as Map<String, dynamic>;
      final result =
          ((decoded['runs'] as List).single['results'] as List).single
              as Map<String, dynamic>;
      final physicalLocation =
          (result['locations'] as List).single['physicalLocation'];

      expect(physicalLocation.containsKey('region'), isFalse);
    });

    test('produces an empty rules and results list for no findings', () async {
      final context = await createProjectContextWithFiles(files: {});

      final sarif = const SarifReporter().generateSarif([], context: context);
      final decoded = jsonDecode(sarif) as Map<String, dynamic>;
      final run = (decoded['runs'] as List).single as Map<String, dynamic>;

      expect(run['tool']['driver']['rules'], isEmpty);
      expect(run['results'], isEmpty);
    });
  });
}
