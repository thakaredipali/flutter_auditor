import 'audit.dart';
import 'audit_result.dart';

/// Pairs an [Audit] with the [AuditResult] it produced, so reporters can
/// reference the audit's id/name alongside its findings (e.g. to list
/// which audits passed, or to categorize findings by audit).
class AuditRunResult {
  final Audit audit;
  final AuditResult result;

  const AuditRunResult({required this.audit, required this.result});
}
