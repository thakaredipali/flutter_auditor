import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/audit_run_result.dart';
import '../models/project_context.dart';
import '../models/severity.dart';
import '../utils/path_utils.dart';

/// Writes audit results as a JSON document, for machine consumption (CI
/// dashboards, custom tooling, scripts) rather than human reading.
class JsonReporter {
  const JsonReporter();

  File writeReport(
    List<AuditRunResult> results, {
    required ProjectContext context,
    String outputPath = 'audit_report.json',
  }) {
    final json = generateJson(results, context: context);
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(json);
    return file;
  }

  String generateJson(
    List<AuditRunResult> results, {
    required ProjectContext context,
  }) {
    final findings = <Map<String, dynamic>>[];
    final countBySeverity = {
      for (final severity in Severity.values) severity.name: 0,
    };

    for (final run in results) {
      for (final issue in run.result.issues) {
        countBySeverity[issue.severity.name] =
            (countBySeverity[issue.severity.name] ?? 0) + 1;

        findings.add({
          'auditId': run.audit.id,
          'auditName': run.audit.name,
          'id': issue.id,
          'title': issue.title,
          'description': issue.description,
          'severity': issue.severity.name,
          'file': PathUtils.relativeToRoot(issue.file, context.rootPath),
          if (issue.line != null) 'line': issue.line,
          'recommendation': issue.recommendation,
        });
      }
    }

    final document = {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'project': p.basename(context.rootPath),
      'summary': {'total': findings.length, ...countBySeverity},
      'findings': findings,
    };

    return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
  }
}
