import 'dart:convert';
import 'dart:io';

import '../models/audit_run_result.dart';
import '../models/project_context.dart';
import '../models/severity.dart';
import '../utils/path_utils.dart';

/// Writes audit results as a SARIF 2.1.0 document — the standard static
/// analysis interchange format. Notably, GitHub code scanning consumes
/// SARIF directly and turns results into PR-line annotations, instead of
/// findings being buried in CI log text.
class SarifReporter {
  const SarifReporter();

  File writeReport(
    List<AuditRunResult> results, {
    required ProjectContext context,
    String outputPath = 'audit_report.sarif',
  }) {
    final json = generateSarif(results, context: context);
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(json);
    return file;
  }

  String generateSarif(
    List<AuditRunResult> results, {
    required ProjectContext context,
  }) {
    final rules = <String, Map<String, dynamic>>{};
    final sarifResults = <Map<String, dynamic>>[];

    for (final run in results) {
      rules.putIfAbsent(
        run.audit.id,
        () => {
          'id': run.audit.id,
          'name': run.audit.name,
          'shortDescription': {'text': run.audit.description},
        },
      );

      for (final issue in run.result.issues) {
        sarifResults.add({
          'ruleId': run.audit.id,
          'level': _sarifLevel(issue.severity),
          'message': {'text': issue.description},
          'locations': [
            {
              'physicalLocation': {
                'artifactLocation': {
                  'uri': PathUtils.relativeToRoot(issue.file, context.rootPath),
                },
                if (issue.line != null) 'region': {'startLine': issue.line},
              },
            },
          ],
        });
      }
    }

    final document = {
      r'$schema':
          'https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json',
      'version': '2.1.0',
      'runs': [
        {
          'tool': {
            'driver': {
              'name': 'flutter_auditor',
              'informationUri':
                  'https://github.com/thakaredipali/flutter_auditor',
              'rules': rules.values.toList(),
            },
          },
          'results': sarifResults,
        },
      ],
    };

    return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
  }

  String _sarifLevel(Severity severity) {
    switch (severity) {
      case Severity.critical:
      case Severity.high:
        return 'error';
      case Severity.medium:
        return 'warning';
      case Severity.low:
      case Severity.info:
        return 'note';
    }
  }
}
