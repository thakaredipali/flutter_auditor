import 'package:yaml/yaml.dart';

import '../data/locked_dependency.dart';
import '../models/project_context.dart';

/// Reads resolved dependency versions from a project's pubspec.lock.
class PubLockHelper {
  const PubLockHelper._();

  static Future<List<LockedDependency>> loadLockedDependencies(
    ProjectContext context,
  ) async {
    final lockFile = context.pubspecLock;

    if (!await lockFile.exists()) {
      return [];
    }

    final dynamic document;
    try {
      document = loadYaml(await lockFile.readAsString());
    } catch (_) {
      return [];
    }

    if (document is! YamlMap) {
      return [];
    }

    final packages = document['packages'];

    if (packages is! YamlMap) {
      return [];
    }

    final result = <LockedDependency>[];

    for (final entry in packages.entries) {
      final name = entry.key.toString();
      final details = entry.value;

      if (details is! YamlMap) {
        continue;
      }

      final version = details['version'];
      final source = details['source'];
      final dependencyType = details['dependency'];

      if (version is! String ||
          source is! String ||
          dependencyType is! String) {
        continue;
      }

      result.add(
        LockedDependency(
          name: name,
          version: version,
          source: source,
          dependencyType: dependencyType,
        ),
      );
    }

    return result;
  }
}
