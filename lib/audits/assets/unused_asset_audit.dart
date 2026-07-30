import 'dart:io';

import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/asset_resolver.dart';

/// Flags asset files declared in pubspec.yaml's `flutter.assets` that no
/// Dart file in the project references by path. Unused assets add
/// unnecessary size to the app bundle.
///
/// Best-effort static scan, in the same spirit as UnusedDependencyAudit:
/// an asset path built dynamically (e.g. string interpolation, a
/// generated asset class) won't be recognized as used, so this may
/// produce false positives for such projects.
class UnusedAssetAudit extends Audit {
  @override
  String get id => 'unused_asset';

  @override
  String get name => 'Unused Asset Audit';

  @override
  String get description =>
      'Checks for assets declared in pubspec.yaml that no Dart file in the project references.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final candidates = await AssetResolver.resolveDeclaredAssets(context);

    if (candidates.isEmpty) {
      return AuditResult(issues: issues);
    }

    final source = await _collectDartSource(context);

    for (final asset in candidates) {
      if (source.contains(asset.relativePath)) {
        continue;
      }

      issues.add(
        SecurityIssue(
          id: 'unused_asset.${asset.relativePath}',
          title: 'Unused Asset: ${asset.relativePath}',
          description:
              '${asset.relativePath} is declared in pubspec.yaml, but no '
              'Dart file in the project references it. Unused assets add '
              'unnecessary size to the app bundle.',
          severity: Severity.low,
          file: asset.file.path,
          recommendation:
              'Remove ${asset.relativePath} from the project and '
              'pubspec.yaml if it is genuinely unused, or reference it if '
              'it is still needed.',
        ),
      );
    }

    return AuditResult(issues: issues);
  }

  Future<String> _collectDartSource(ProjectContext context) async {
    if (!context.rootDirectory.existsSync()) {
      return '';
    }

    final sep = Platform.pathSeparator;

    final dartFiles = context.rootDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.contains('$sep.dart_tool$sep') &&
              !file.path.contains('${sep}build$sep'),
        );

    final buffer = StringBuffer();

    for (final file in dartFiles) {
      try {
        buffer.writeln(await file.readAsString());
      } catch (_) {
        continue;
      }
    }

    return buffer.toString();
  }
}
