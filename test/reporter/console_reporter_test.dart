import 'dart:async';

import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/console_reporter.dart';
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

SecurityIssue _issue(String id, Severity severity, {String? title}) =>
    SecurityIssue(
      id: id,
      title: title ?? 'Issue $id',
      description: 'Description of $id.',
      severity: severity,
      file: 'lib/main.dart',
      line: 7,
      recommendation: 'Fix $id.',
    );

AuditRunResult _run(String auditId, List<SecurityIssue> issues) =>
    AuditRunResult(
      audit: _FakeAudit(auditId, 'Audit $auditId'),
      result: AuditResult(issues: issues),
    );

/// Runs [body] while capturing everything it prints.
({int exitCode, String output}) _capture(int Function() body) {
  final lines = <String>[];
  final exitCode = runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return (exitCode: exitCode, output: lines.join('\n'));
}

void main() {
  group('ConsoleReporter', () {
    late ProjectContext context;

    setUp(() async {
      context = await createProjectContextWithFiles(files: {});
    });

    test('exits 0 and reports ALL CLEAR when there are no issues', () {
      final report = _capture(
        () => const ConsoleReporter().printReport([
          _run('a', []),
        ], context: context),
      );

      expect(report.exitCode, 0);
      expect(report.output, contains('ALL CLEAR'));
      expect(report.output, contains('✔ Audit a — no issues found'));
    });

    test('exits 1 when a high-severity issue is present', () {
      final report = _capture(
        () => const ConsoleReporter().printReport([
          _run('a', [_issue('x', Severity.high, title: 'Bad thing')]),
        ], context: context),
      );

      expect(report.exitCode, 1);
      expect(report.output, contains('ACTION REQUIRED'));
      expect(report.output, contains('[1] Bad thing'));
      expect(report.output, contains('📍 lib/main.dart:7'));
    });

    test('exits 0 for medium issues under the default failOn', () {
      final report = _capture(
        () => const ConsoleReporter().printReport([
          _run('a', [_issue('x', Severity.medium)]),
        ], context: context),
      );

      expect(report.exitCode, 0);
      expect(report.output, contains('REVIEW RECOMMENDED'));
    });

    test('respects a stricter failOn', () {
      final report = _capture(
        () => const ConsoleReporter().printReport(
          [
            _run('a', [_issue('x', Severity.medium)]),
          ],
          context: context,
          failOn: Severity.medium,
        ),
      );

      expect(report.exitCode, 1);
    });

    test('always exits 0 when failOn is null', () {
      final report = _capture(
        () => const ConsoleReporter().printReport(
          [
            _run('a', [_issue('x', Severity.critical)]),
          ],
          context: context,
          failOn: null,
        ),
      );

      expect(report.exitCode, 0);
    });

    test('maintenance findings never affect the exit code', () {
      final report = _capture(
        () => const ConsoleReporter().printReport([
          _run('dependency_hygiene', [_issue('dep', Severity.high)]),
        ], context: context),
      );

      expect(report.exitCode, 0);
      expect(report.output, contains('MAINTENANCE (1)'));
    });

    test('baselined high issues are shown but do not fail the run', () {
      final report = _capture(
        () => const ConsoleReporter().printReport(
          [
            _run('a', [_issue('old', Severity.high)]),
          ],
          context: context,
          exemptFromFailOn: {'old'},
        ),
      );

      expect(report.exitCode, 0);
      expect(report.output, contains('Pre-existing (baselined, non-blocking)'));
      expect(report.output, contains('(0 new, 1 pre-existing)'));
    });

    test('collapses low-risk items unless verbose', () {
      final results = [
        _run('a', [_issue('low', Severity.low, title: 'Minor')]),
      ];

      final collapsed = _capture(
        () => const ConsoleReporter().printReport(results, context: context),
      );
      final verbose = _capture(
        () => const ConsoleReporter().printReport(
          results,
          context: context,
          verbose: true,
        ),
      );

      expect(collapsed.output, contains('Run with --verbose'));
      expect(collapsed.output, isNot(contains('Fix: Fix low.')));
      expect(verbose.output, contains('Fix: Fix low.'));
    });
  });
}
