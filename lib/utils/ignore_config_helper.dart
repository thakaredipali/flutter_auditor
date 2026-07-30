import 'package:yaml/yaml.dart';

import '../models/ignore_config.dart';
import '../models/project_context.dart';

/// Loads a project's `.flutter_auditor_ignore.yaml` suppression config.
class IgnoreConfigHelper {
  const IgnoreConfigHelper._();

  static Future<IgnoreConfig> load(ProjectContext context) async {
    final file = context.ignoreConfigFile;

    if (!await file.exists()) {
      return const IgnoreConfig();
    }

    final dynamic document;
    try {
      document = loadYaml(await file.readAsString());
    } catch (_) {
      return const IgnoreConfig();
    }

    if (document is! YamlMap) {
      return const IgnoreConfig();
    }

    return IgnoreConfig(
      auditIds: _stringSet(document['audits']),
      issueIds: _stringSet(document['ids']),
      filePatterns: _stringSet(document['files']).toList(),
    );
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! YamlList) {
      return {};
    }

    return value.map((entry) => entry.toString()).toSet();
  }
}
