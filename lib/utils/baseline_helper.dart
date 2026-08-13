import 'dart:convert';

import '../models/audit_run_result.dart';
import '../models/baseline_config.dart';
import '../models/project_context.dart';

/// Loads and writes a project's `.flutter_auditor_baseline.json`.
class BaselineHelper {
  const BaselineHelper._();

  static Future<BaselineConfig> load(ProjectContext context) async {
    final file = context.baselineFile;

    if (!await file.exists()) {
      return const BaselineConfig();
    }

    try {
      final decoded = jsonDecode(await file.readAsString());

      if (decoded is! Map<String, dynamic>) {
        return const BaselineConfig();
      }

      final fingerprints = decoded['fingerprints'];

      if (fingerprints is! List) {
        return const BaselineConfig();
      }

      return BaselineConfig(
        fingerprints: fingerprints.map((entry) => entry.toString()).toSet(),
      );
    } catch (_) {
      return const BaselineConfig();
    }
  }

  /// Writes [results] to the project's baseline file, overwriting any
  /// existing baseline.
  static Future<void> write(
    List<AuditRunResult> results,
    ProjectContext context,
  ) async {
    final fingerprints = BaselineConfig.fingerprintsFor(results, context);

    final document = {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'fingerprints': fingerprints.toList()..sort(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(document);

    await context.baselineFile.writeAsString('$json\n');
  }
}
