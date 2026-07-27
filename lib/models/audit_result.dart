import 'security_issue.dart';

/// Represents the result of a security audit.
class AuditResult {
  /// Security issues found during the audit.
  final List<SecurityIssue> issues;

  const AuditResult({required this.issues});

  /// Returns true if the audit found any issues.
  bool get hasIssues => issues.isNotEmpty;
}
