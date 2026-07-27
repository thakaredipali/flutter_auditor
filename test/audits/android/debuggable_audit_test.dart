import 'dart:io';

import 'package:flutter_auditor/audits/android/debuggable_audit.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('DebuggableAudit', () {
    late DebuggableAudit audit;

    setUp(() {
      audit = DebuggableAudit();
    });

    test('returns issue when debuggable is true', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:debuggable="true">
    </application>
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test('returns no issue when debuggable is false', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:debuggable="false">
    </application>
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('returns no issue when AndroidManifest.xml is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'flutter_auditor_test',
      );
      final context = ProjectContext(rootDirectory: tempDir);

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
