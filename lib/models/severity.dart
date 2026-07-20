/// Represents the severity level of a security issue.
enum Severity {
  critical,
  high,
  medium,
  low,
  info;

  /// Human-readable name.
  String get label {
    switch (this) {
      case Severity.critical:
        return 'Critical';
      case Severity.high:
        return 'High';
      case Severity.medium:
        return 'Medium';
      case Severity.low:
        return 'Low';
      case Severity.info:
        return 'Info';
    }
  }
}