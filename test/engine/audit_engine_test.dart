import 'dart:io';

import 'package:flutter_auditor/engine/audit_engine.dart';
import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

class _FakeAudit extends Audit {
  _FakeAudit({
    required this.id,
    required this.name,
    List<SecurityIssue> issues = const [],
  }) : _issues = issues;

  @override
  final String id;

  @override
  final String name;

  final List<SecurityIssue> _issues;

  @override
  String get description => 'Fake audit for testing.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    return AuditResult(issues: _issues);
  }
}

class _ThrowingAudit extends Audit {
  @override
  String get id => 'throwing_audit';

  @override
  String get name => 'Throwing Audit';

  @override
  String get description => 'Always throws, to test engine error isolation.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    throw StateError('boom');
  }
}

void main() {
  group('AuditEngine', () {
    final context = ProjectContext(rootDirectory: Directory.systemTemp);

    test('runs all registered audits', () async {
      final auditA = _FakeAudit(id: 'a', name: 'Audit A');
      final auditB = _FakeAudit(id: 'b', name: 'Audit B');
      final engine = AuditEngine(audits: [auditA, auditB]);

      final results = await engine.run(context);

      expect(results.map((r) => r.audit), [auditA, auditB]);
    });

    test('returns empty result when no audits are registered', () async {
      final engine = AuditEngine(audits: []);

      final results = await engine.run(context);

      expect(results, isEmpty);
    });

    test('returns results from all audits', () async {
      final issue = SecurityIssue(
        id: 'a.issue',
        title: 'Issue A',
        description: 'desc',
        severity: Severity.high,
        file: 'lib/main.dart',
        recommendation: 'fix it',
      );
      final auditA = _FakeAudit(id: 'a', name: 'Audit A', issues: [issue]);
      final auditB = _FakeAudit(id: 'b', name: 'Audit B');
      final engine = AuditEngine(audits: [auditA, auditB]);

      final results = await engine.run(context);

      expect(results[0].result.issues, [issue]);
      expect(results[1].result.issues, isEmpty);
    });

    test(
      'isolates a throwing audit instead of aborting the whole run',
      () async {
        final before = _FakeAudit(id: 'before', name: 'Before');
        final after = _FakeAudit(id: 'after', name: 'After');
        final engine = AuditEngine(audits: [before, _ThrowingAudit(), after]);

        final results = await engine.run(context);

        expect(results, hasLength(3));
        expect(results[0].result.issues, isEmpty);
        expect(results[2].result.issues, isEmpty);

        final failure = results[1].result.issues.single;
        expect(failure.severity, Severity.info);
        expect(failure.title, contains('Throwing Audit'));
        expect(failure.description, contains('boom'));
      },
    );
  });
}
