/// Describes an Info.plist usage-description key checked by
/// [UsageDescriptionAudit].
class UsageDescriptionRule {
  final String key;
  final String capability;

  /// pubspec.yaml dependency names that require this key to be present.
  final List<String> requiredByPackages;

  /// Other usage-description keys that Apple requires to also be present
  /// whenever this key is present (e.g. "Always" location requires
  /// "When In Use" location too).
  final List<String> requiresAlsoPresent;

  final String recommendation;

  const UsageDescriptionRule({
    required this.key,
    required this.capability,
    this.requiredByPackages = const [],
    this.requiresAlsoPresent = const [],
    required this.recommendation,
  });
}
