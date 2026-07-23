import 'dart:io';

import '../../data/network_patterns.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';

class InsecureNetworkAudit extends Audit {
  @override
  String get id => 'insecure_network';

  @override
  String get name => 'Insecure Network Usage Detection';

  @override
  String get description =>
      'Scans Dart source files for cleartext HTTP URLs and disabled certificate/SSL validation.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    if (!context.libDirectory.existsSync()) {
      return AuditResult(issues: issues);
    }

    final dartFiles = context.libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final content = await file.readAsString();

      for (final rule in networkPatterns) {
        for (final match in rule.pattern.allMatches(content)) {
          issues.add(
            SecurityIssue(
              id: '${id}_${file.path}_${match.start}_${rule.name}',
              title: rule.name,
              description:
                  'A potential ${rule.name} issue was found in source code.',
              severity: rule.severity,
              file: file.path,
              line: _lineNumberAt(content, match.start),
              recommendation: rule.recommendation,
            ),
          );
        }
      }
    }

    return AuditResult(issues: issues);
  }

  int _lineNumberAt(String content, int offset) {
    return '\n'.allMatches(content.substring(0, offset)).length + 1;
  }
}
