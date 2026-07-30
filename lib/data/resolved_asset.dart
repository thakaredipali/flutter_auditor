import 'dart:io';

/// A declared pubspec.yaml asset resolved to an actual file on disk, with
/// its path normalized relative to the project root (forward-slash,
/// matching how Dart source references assets regardless of host OS).
class ResolvedAsset {
  final File file;
  final String relativePath;

  const ResolvedAsset({required this.file, required this.relativePath});
}
