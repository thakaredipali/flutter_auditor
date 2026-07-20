import 'severity.dart';

/// Represents a security issue found during an audit.
class SecurityIssue {
  /// Unique identifier for the issue.
  final String id;

  /// Short title of the issue.
  final String title;

  /// Detailed description of the issue.
  final String description;

  /// Severity level.
  final Severity severity;

  /// File where the issue was found.
  final String file;

  /// Line number (if available).
  final int? line;

  /// Recommendation to resolve the issue.
  final String recommendation;

  const SecurityIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.file,
    this.line,
    required this.recommendation,
  });
}