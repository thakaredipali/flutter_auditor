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
}
