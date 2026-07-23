import 'dart:io';

/// Represents the Flutter project being audited.
class ProjectContext {
  /// Root directory of the Flutter project.
  final Directory rootDirectory;

  const ProjectContext({
    required this.rootDirectory,
  });

  /// Absolute path to the project.
  String get rootPath => rootDirectory.path;

  /// pubspec.yaml
  File get pubspec =>
      File('$rootPath/pubspec.yaml');

  /// lib directory
  Directory get libDirectory =>
      Directory('$rootPath/lib');

  /// android directory
  Directory get androidDirectory =>
      Directory('$rootPath/android');

  /// AndroidManifest.xml
  File get androidManifest =>
      File(
        '$rootPath/android/app/src/main/AndroidManifest.xml',
      );

  /// ios directory
  Directory get iosDirectory =>
      Directory('$rootPath/ios');

  /// Info.plist
  File get iosInfoPlist =>
      File('$rootPath/ios/Runner/Info.plist');
}