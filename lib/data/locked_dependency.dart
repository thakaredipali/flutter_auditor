/// A single resolved entry from pubspec.lock.
class LockedDependency {
  final String name;
  final String version;
  final String source;
  final String dependencyType;

  const LockedDependency({
    required this.name,
    required this.version,
    required this.source,
    required this.dependencyType,
  });

  /// True for packages declared directly in pubspec.yaml's `dependencies:`
  /// (as opposed to dev_dependencies or transitive dependencies pulled in
  /// by something else).
  bool get isDirectMain => dependencyType == 'direct main';

  /// True for ordinary pub.dev-hosted packages (as opposed to sdk, path,
  /// or git dependencies, which pub.dev has no meaningful listing for).
  bool get isHosted => source == 'hosted';
}
