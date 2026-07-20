import 'security_issue.dart';

/// Represents the result of a security audit.
class AuditResult {
  /// Unique identifier of the audit.
  final String auditId;

  /// Security issues found during the audit.
  final List<SecurityIssue> issues;

  const AuditResult({
    required this.auditId,
    required this.issues,
  });

  /// Returns true if the audit found any issues.
  bool get hasIssues => issues.isNotEmpty;
}