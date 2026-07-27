import 'dart:io';

import '../models/project_context.dart';

/// Scans and validates a Flutter project.
class ProjectScanner {
  /// Returns the project context if the current directory is a Flutter project.
  ///
  /// Returns `null` if validation fails.
  ProjectContext? scan() {
    final root = Directory.current;

    final pubspec = File('${root.path}/pubspec.yaml');
    final lib = Directory('${root.path}/lib');

    if (!pubspec.existsSync() || !lib.existsSync()) {
      return null;
    }

    return ProjectContext(rootDirectory: root);
  }
}
