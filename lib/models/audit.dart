import 'audit_result.dart';
import 'project_context.dart';

/// Base contract for all security audits.
abstract class Audit {
  /// Unique identifier for the audit.
  String get id;

  /// Human-readable audit name.
  String get name;

  /// Short description of what this audit checks.
  String get description;

  /// Executes the audit.
  Future<AuditResult> run(ProjectContext context);
}