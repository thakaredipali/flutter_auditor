import '../models/audit.dart';
import '../models/audit_result.dart';
import '../models/project_context.dart';

/// Executes all registered audits.
class AuditEngine {
  final List<Audit> audits;

  const AuditEngine({
    required this.audits,
  });

  /// Runs all audits and returns their results.
  Future<List<AuditResult>> run(ProjectContext context) async {
    final results = <AuditResult>[];

    for (final audit in audits) {
      final result = await audit.run(context);
      results.add(result);
    }

    return results;
  }
}