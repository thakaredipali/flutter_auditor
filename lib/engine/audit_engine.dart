import '../models/audit.dart';
import '../models/audit_result.dart';
import '../models/audit_run_result.dart';
import '../models/project_context.dart';
import '../models/security_issue.dart';
import '../models/severity.dart';

/// Executes all registered audits.
class AuditEngine {
  final List<Audit> audits;

  const AuditEngine({required this.audits});

  /// Runs all audits and returns their results, paired with the audit that
  /// produced each one.
  ///
  /// A single audit throwing (e.g. on an unexpected/malformed project file)
  /// does not abort the run — it is reported as an info-level finding for
  /// that audit so the rest of the report still completes.
  Future<List<AuditRunResult>> run(ProjectContext context) async {
    final results = <AuditRunResult>[];

    for (final audit in audits) {
      AuditResult result;
      try {
        result = await audit.run(context);
      } catch (e) {
        result = AuditResult(
          issues: [
            SecurityIssue(
              id: '${audit.id}.audit_error',
              title: 'Audit Failed: ${audit.name}',
              description: 'This audit did not complete: $e',
              severity: Severity.info,
              file: context.rootPath,
              recommendation:
                  'This may indicate an unexpected or malformed project '
                  'file. Please report this if it persists.',
            ),
          ],
        );
      }
      results.add(AuditRunResult(audit: audit, result: result));
    }

    return results;
  }
}
