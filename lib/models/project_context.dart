import 'dart:io';

/// Represents the Flutter project being audited.
class ProjectContext {
  /// Root directory of the Flutter project.
  final Directory rootDirectory;

  const ProjectContext({required this.rootDirectory});

  /// Absolute path to the project.
  String get rootPath => rootDirectory.path;

  /// pubspec.yaml
  File get pubspec => File('$rootPath/pubspec.yaml');

  /// pubspec.lock
  File get pubspecLock => File('$rootPath/pubspec.lock');

  /// lib directory
  Directory get libDirectory => Directory('$rootPath/lib');

  /// android directory
  Directory get androidDirectory => Directory('$rootPath/android');

  /// AndroidManifest.xml
  File get androidManifest =>
      File('$rootPath/android/app/src/main/AndroidManifest.xml');

  /// android/app/build.gradle (Groovy DSL)
  File get androidAppBuildGradle => File('$rootPath/android/app/build.gradle');

  /// android/app/build.gradle.kts (Kotlin DSL)
  File get androidAppBuildGradleKts =>
      File('$rootPath/android/app/build.gradle.kts');

  /// android/key.properties
  File get androidKeyProperties => File('$rootPath/android/key.properties');

  /// .gitignore at the project root
  File get gitignore => File('$rootPath/.gitignore');

  /// Project-level suppression config for flutter_auditor findings.
  File get ignoreConfigFile => File('$rootPath/.flutter_auditor_ignore.yaml');

  /// Accepted-baseline snapshot of pre-existing flutter_auditor findings.
  File get baselineFile => File('$rootPath/.flutter_auditor_baseline.json');

  /// ios directory
  Directory get iosDirectory => Directory('$rootPath/ios');

  /// Info.plist
  File get iosInfoPlist => File('$rootPath/ios/Runner/Info.plist');
}
