import '../models/severity.dart';

/// Describes a regex-based rule used to flag insecure code in source files.
class PatternRule {
  final String name;
  final RegExp pattern;
  final Severity severity;
  final String recommendation;

  const PatternRule({
    required this.name,
    required this.pattern,
    required this.severity,
    required this.recommendation,
  });
}
