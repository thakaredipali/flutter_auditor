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

  /// True if this severity is at least as severe as [threshold] (lower
  /// index in [Severity.values] means more severe: critical is the most
  /// severe, info the least).
  bool isAtLeastAsSevereAs(Severity threshold) => index <= threshold.index;
}
