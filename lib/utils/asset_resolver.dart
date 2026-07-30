import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/resolved_asset.dart';
import '../models/project_context.dart';
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
    // Asset paths are always referenced with forward slashes in Dart
    // source regardless of host OS, so normalize p.relative's
    // platform-separator output before using it as a match key.
    final relativePath = p
        .relative(file.path, from: context.rootPath)
        .replaceAll(r'\', '/');

    if (seen.add(relativePath)) {
      resolved.add(ResolvedAsset(file: file, relativePath: relativePath));
    }
  }
}
