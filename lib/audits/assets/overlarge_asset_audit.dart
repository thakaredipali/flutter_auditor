import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/asset_resolver.dart';

/// Flags declared assets large enough to meaningfully bloat the app
/// bundle. Thresholds are deliberately conservative — a flagged asset is
/// worth reviewing/compressing, not necessarily wrong.
class OverlargeAssetAudit extends Audit {
  static const _highThresholdBytes = 5 * 1024 * 1024; // 5 MB
  static const _mediumThresholdBytes = 1 * 1024 * 1024; // 1 MB

  @override
  String get id => 'overlarge_asset';

  @override
  String get name => 'Overlarge Asset Audit';

  @override
  String get description =>
      'Checks assets declared in pubspec.yaml for file sizes large enough to meaningfully bloat the app bundle.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final assets = await AssetResolver.resolveDeclaredAssets(context);

    for (final asset in assets) {
      final sizeInBytes = await asset.file.length();
      final severity = _severityFor(sizeInBytes);

      if (severity == null) {
        continue;
      }

      final formattedSize = _formatSize(sizeInBytes);

      issues.add(
        SecurityIssue(
          id: 'overlarge_asset.${asset.relativePath}',
          title: 'Overlarge Asset: ${asset.relativePath} ($formattedSize)',
          description:
              '${asset.relativePath} is $formattedSize, which will '
              'meaningfully increase the app bundle size.',
          severity: severity,
          file: asset.file.path,
          recommendation:
              'Compress or downsize this asset (e.g. re-encode images at a '
              'lower resolution/quality, or use a more efficient format '
              'such as WebP), or load it on demand instead of bundling it.',
        ),
      );
    }

    return AuditResult(issues: issues);
  }

  Severity? _severityFor(int bytes) {
    if (bytes >= _highThresholdBytes) {
      return Severity.high;
    }
    if (bytes >= _mediumThresholdBytes) {
      return Severity.medium;
    }
    return null;
  }

  String _formatSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);

    if (megabytes >= 1) {
      return '${megabytes.toStringAsFixed(1)} MB';
    }

    final kilobytes = bytes / 1024;
    return '${kilobytes.toStringAsFixed(0)} KB';
  }
}
