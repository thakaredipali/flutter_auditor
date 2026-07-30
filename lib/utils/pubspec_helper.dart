import 'package:yaml/yaml.dart';

import '../models/project_context.dart';

/// Reads dependency names declared in a project's pubspec.yaml.
class PubspecHelper {
  const PubspecHelper._();

  static Future<Set<String>> loadDependencyNames(ProjectContext context) async {
    final pubspec = context.pubspec;

    if (!await pubspec.exists()) {
      return {};
    }

    final dynamic document;
    try {
      document = loadYaml(await pubspec.readAsString());
    } catch (_) {
      return {};
    }

    if (document is! YamlMap) {
      return {};
    }

    final dependencies = document['dependencies'];

    if (dependencies is! YamlMap) {
      return {};
    }

    return dependencies.keys.map((key) => key.toString()).toSet();
  }

  /// Reads `flutter.assets` paths declared in a project's pubspec.yaml.
  /// Entries ending in `/` are asset directories; others are individual
  /// files.
  static Future<List<String>> loadAssetPaths(ProjectContext context) async {
    final pubspec = context.pubspec;

    if (!await pubspec.exists()) {
      return [];
    }

    final dynamic document;
    try {
      document = loadYaml(await pubspec.readAsString());
    } catch (_) {
      return [];
    }

    if (document is! YamlMap) {
      return [];
    }

    final flutterSection = document['flutter'];

    if (flutterSection is! YamlMap) {
      return [];
    }

    final assets = flutterSection['assets'];

    if (assets is! YamlList) {
      return [];
    }

    return assets.map((asset) => asset.toString()).toList();
  }
}
