import '../models/severity.dart';

/// Describes a pattern used to detect a hardcoded secret in source code.
class SecretPattern {
  final String name;
  final RegExp pattern;
  final Severity severity;
  final String recommendation;

  /// Generic patterns (keyword + assigned string literal) are suppressed on
  /// a line where a more specific pattern already matched, to avoid noise.
  final bool isGeneric;

  const SecretPattern({
    required this.name,
    required this.pattern,
    required this.severity,
    required this.recommendation,
    this.isGeneric = false,
  });
}
