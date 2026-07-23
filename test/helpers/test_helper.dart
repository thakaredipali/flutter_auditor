import 'dart:io';

import 'package:flutter_audit/models/project_context.dart';

Future<ProjectContext> createProjectContext({
  required String manifestContent,
}) async {
  final tempDir = await Directory.systemTemp.createTemp('flutter_audit_test');

  final manifestFile = File(
    '${tempDir.path}/android/app/src/main/AndroidManifest.xml',
  );

  await manifestFile.parent.create(recursive: true);

  await manifestFile.writeAsString(manifestContent);

  return ProjectContext(
    rootDirectory: tempDir,
  );
}

/// Creates a temporary project context populated with the given files.
///
/// Keys are paths relative to the project root (e.g. `lib/main.dart`).
Future<ProjectContext> createProjectContextWithFiles({
  required Map<String, String> files,
}) async {
  final tempDir = await Directory.systemTemp.createTemp('flutter_audit_test');

  for (final entry in files.entries) {
    final file = File('${tempDir.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }

  return ProjectContext(
    rootDirectory: tempDir,
  );
}