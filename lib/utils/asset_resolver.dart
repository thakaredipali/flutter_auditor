import 'dart:io';

import '../data/resolved_asset.dart';
import '../models/project_context.dart';
import 'path_utils.dart';
import 'pubspec_helper.dart';

/// Resolves pubspec.yaml's `flutter.assets` entries (individual files and
/// asset directories) to the files that actually exist on disk.
class AssetResolver {
  const AssetResolver._();

  static Future<List<ResolvedAsset>> resolveDeclaredAssets(
    ProjectContext context,
  ) async {
    final declaredPaths = await PubspecHelper.loadAssetPaths(context);

    if (declaredPaths.isEmpty) {
      return [];
    }

    final resolved = <ResolvedAsset>[];
    final seen = <String>{};

    for (final declaredPath in declaredPaths) {
      if (declaredPath.endsWith('/')) {
        final dir = Directory('${context.rootPath}/$declaredPath');

        if (!dir.existsSync()) {
          continue;
        }

        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            _add(context, entity, seen, resolved);
          }
        }
      } else {
        final file = File('${context.rootPath}/$declaredPath');

        if (file.existsSync()) {
          _add(context, file, seen, resolved);
        }
      }
    }

    return resolved;
  }

  static void _add(
    ProjectContext context,
    File file,
    Set<String> seen,
    List<ResolvedAsset> resolved,
  ) {
    final relativePath = PathUtils.relativeToRoot(file.path, context.rootPath);

    if (seen.add(relativePath)) {
      resolved.add(ResolvedAsset(file: file, relativePath: relativePath));
    }
  }
}
