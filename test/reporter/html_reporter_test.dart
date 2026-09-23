import 'dart:io';

import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/html_reporter.dart';
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
      recommendation: 'Fix $id.',
    );

AuditRunResult _run(String auditId, List<SecurityIssue> issues) =>
    AuditRunResult(
      audit: _FakeAudit(auditId, 'Audit $auditId'),
      result: AuditResult(issues: issues),
    );

void main() {
  group('HtmlReporter', () {
    late ProjectContext context;

    setUp(() async {
      context = await createProjectContextWithFiles(files: {});
    });

    test('renders an empty report as ALL CLEAR', () {
      final html = const HtmlReporter().generateHtml([
        _run('a', []),
      ], context: context);

      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('ALL CLEAR'));
      expect(html, contains('donut-empty'));
      expect(html, contains('✔ Audit a — no issues found'));
    });

    test('renders findings with a severity chart and status', () {
      final html = const HtmlReporter().generateHtml([
        _run('a', [
          _issue('h', Severity.high, title: 'High thing'),
          _issue('m', Severity.medium, title: 'Medium thing'),
        ]),
      ], context: context);

      expect(html, contains('ACTION REQUIRED'));
      expect(html, contains('conic-gradient'));
      expect(html, contains('High thing'));
      expect(html, contains('Medium thing'));
      expect(html, contains('<span class="donut-total">2</span>'));
    });

    test('puts maintenance findings in their own collapsed section', () {
      final html = const HtmlReporter().generateHtml([
        _run('unused_asset', [_issue('asset', Severity.low)]),
      ], context: context);

      expect(html, contains('Maintenance'));
      expect(html, contains('<details class="issue-section" >'));
      // Maintenance does not count as a security issue for the status.
      expect(html, contains('ALL CLEAR'));
    });

    test('escapes HTML in finding text', () {
      final html = const HtmlReporter().generateHtml([
        _run('a', [
          _issue('x', Severity.high, title: '<script>alert("x")</script>'),
        ]),
      ], context: context);

      expect(html, isNot(contains('<script>alert')));
      expect(
        html,
        contains('&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;'),
      );
    });

    test('writeReport writes the HTML to the given path', () async {
      final outDir = await Directory.systemTemp.createTemp(
        'flutter_auditor_html',
      );
      final file = const HtmlReporter().writeReport(
        [_run('a', [])],
        context: context,
        outputPath: '${outDir.path}/nested/report.html',
      );

      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('<!DOCTYPE html>'));
    });
  });
}
