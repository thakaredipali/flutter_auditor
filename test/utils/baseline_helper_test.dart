import 'dart:convert';

import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/utils/baseline_helper.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

class _FakeAudit extends Audit {
  _FakeAudit(this.id);

  @override
  final String id;

  @override
  String get name => id;

  @override
  String get description => 'Fake audit for testing.';

  @override
  Future<AuditResult> run(ProjectContext context) async =>
      const AuditResult(issues: []);
}

void main() {
  group('BaselineHelper', () {
    test('returns an empty config when the file is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final config = await BaselineHelper.load(context);

      expect(config.isEmpty, isTrue);
    });

    test('returns an empty config for malformed JSON', () async {
      final context = await createProjectContextWithFiles(
        files: {'.flutter_auditor_baseline.json': 'not valid json {'},
      );

      final config = await BaselineHelper.load(context);

      expect(config.isEmpty, isTrue);
    });

    test('write then load round-trips the same fingerprints', () async {
      final context = await createProjectContextWithFiles(files: {});
      final issue = SecurityIssue(
        id: 'a.one',
        title: 'Title',
        description: 'Description',
        severity: Severity.medium,
        file: '${context.rootPath}/lib/x.dart',
        recommendation: 'Fix it',
      );
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(issues: [issue]),
        ),
      ];

      await BaselineHelper.write(results, context);
      final loaded = await BaselineHelper.load(context);

      final (filtered, baselined, exempt) = loaded.apply(results, context);
      expect(baselined, 1);
      expect(exempt, isEmpty);
      expect(filtered[0].result.issues, isEmpty);
    });

    test(
      'writes valid, sorted, indented JSON with a generatedAt field',
      () async {
        final context = await createProjectContextWithFiles(files: {});
        final results = <AuditRunResult>[];

        await BaselineHelper.write(results, context);

        final raw = await context.baselineFile.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;

        expect(decoded['fingerprints'], isEmpty);
        expect(decoded['generatedAt'], isA<String>());
      },
    );
  });
}
