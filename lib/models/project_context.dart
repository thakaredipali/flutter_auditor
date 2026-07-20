import 'dart:io';

/// Represents the Flutter project being audited.
class ProjectContext {
  /// Root directory of the Flutter project.
  final Directory rootDirectory;

  const ProjectContext({
    required this.rootDirectory,
  });

  /// Returns the absolute project path.
  String get rootPath => rootDirectory.path;
}