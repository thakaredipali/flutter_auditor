import '../models/audit.dart';
import '../models/audit_run_result.dart';
import '../models/project_context.dart';

/// Executes all registered audits.
class AuditEngine {
  final List<Audit> audits;

  const AuditEngine({required this.audits});

  /// Runs all audits and returns their results, paired with the audit that
  /// produced each one.
  Future<List<AuditRunResult>> run(ProjectContext context) async {
    final results = <AuditRunResult>[];

    for (final audit in audits) {
      final result = await audit.run(context);
      results.add(AuditRunResult(audit: audit, result: result));
    }

    return results;
  }
}
