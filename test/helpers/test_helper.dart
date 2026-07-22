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