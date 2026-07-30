import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/ignore_config.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
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

SecurityIssue _issue({required String id, required String file}) {
  return SecurityIssue(
    id: id,
    title: 'Title',
    description: 'Description',
    severity: Severity.high,
    file: file,
    recommendation: 'Fix it',
  );
}

void main() {
  group('IgnoreConfig', () {
    late ProjectContext context;

    setUp(() async {
      context = await createProjectContextWithFiles(files: {});
    });

    test('an empty config suppresses nothing', () {
      const config = IgnoreConfig();
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.issue', file: '${context.rootPath}/lib/x.dart'),
            ],
          ),
        ),
      ];

      final (filtered, suppressed) = config.apply(results, context);

      expect(suppressed, 0);
      expect(filtered[0].result.issues, hasLength(1));
    });

    test('suppresses every issue from an ignored audit id', () {
      const config = IgnoreConfig(auditIds: {'a'});
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.one', file: '${context.rootPath}/lib/x.dart'),
              _issue(id: 'a.two', file: '${context.rootPath}/lib/y.dart'),
            ],
          ),
        ),
        AuditRunResult(
          audit: _FakeAudit('b'),
          result: AuditResult(
            issues: [
              _issue(id: 'b.one', file: '${context.rootPath}/lib/z.dart'),
            ],
          ),
        ),
      ];

      final (filtered, suppressed) = config.apply(results, context);

      expect(suppressed, 2);
      expect(filtered[0].result.issues, isEmpty);
      expect(filtered[1].result.issues, hasLength(1));
    });

    test('suppresses by exact issue id', () {
      const config = IgnoreConfig(issueIds: {'a.one'});
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.one', file: '${context.rootPath}/lib/x.dart'),
              _issue(id: 'a.two', file: '${context.rootPath}/lib/y.dart'),
            ],
          ),
        ),
      ];

      final (filtered, suppressed) = config.apply(results, context);

      expect(suppressed, 1);
      expect(filtered[0].result.issues.single.id, 'a.two');
    });

    test('suppresses by file glob, matched relative to the project root', () {
      const config = IgnoreConfig(filePatterns: ['test/fixtures/**']);
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(
                id: 'a.one',
                file: '${context.rootPath}/test/fixtures/fake.dart',
              ),
              _issue(id: 'a.two', file: '${context.rootPath}/lib/y.dart'),
            ],
          ),
        ),
      ];

      final (filtered, suppressed) = config.apply(results, context);

      expect(suppressed, 1);
      expect(filtered[0].result.issues.single.id, 'a.two');
    });

    test('a single-segment glob does not match across directories', () {
      const config = IgnoreConfig(filePatterns: ['*.dart']);
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.one', file: '${context.rootPath}/lib/y.dart'),
            ],
          ),
        ),
      ];

      final (filtered, suppressed) = config.apply(results, context);

      expect(suppressed, 0);
      expect(filtered[0].result.issues, hasLength(1));
    });
  });
}
