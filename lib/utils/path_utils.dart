import 'package:path/path.dart' as p;

/// Shared path-normalization helpers used across audits and reporters.
class PathUtils {
  const PathUtils._();

  /// Converts an absolute file path to one relative to [rootPath], with
  /// forward slashes regardless of host OS — matching how paths are
  /// referenced in Dart source, ignore/baseline config, and JSON/SARIF
  /// output.
  static String relativeToRoot(String filePath, String rootPath) {
    return p.relative(filePath, from: rootPath).replaceAll(r'\', '/');
  }
}
