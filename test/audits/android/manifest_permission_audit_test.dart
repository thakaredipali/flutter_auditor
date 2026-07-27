import 'package:flutter_auditor/audits/android/manifest_permission_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';


void main() {
  group('ManifestPermissionAudit', () {
    late ManifestPermissionAudit audit;

    setUp(() {
      audit = ManifestPermissionAudit();
    });

    test('returns no issues when manifest has no permissions', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects high-risk permission', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.READ_SMS"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, hasLength(1));

      final issue = result.issues.first;

      expect(issue.severity, Severity.high);
      expect(issue.title, contains('READ_SMS'));
      expect(issue.description, isNotEmpty);
      expect(issue.recommendation, isNotEmpty);
    });

    test('detects medium-risk permission', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, hasLength(1));

      final issue = result.issues.first;

      expect(issue.severity, Severity.medium);
      expect(issue.title, contains('CAMERA'));
    });

    test('ignores low-risk permissions', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores unknown permissions', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.UNKNOWN_PERMISSION"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects multiple risky permissions', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.READ_SMS"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.INTERNET"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, hasLength(2));

      expect(
        result.issues.any((e) => e.severity == Severity.high),
        isTrue,
      );

      expect(
        result.issues.any((e) => e.severity == Severity.medium),
        isTrue,
      );
    });

    test('handles duplicate permissions', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.CAMERA"/>

    <application />
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, hasLength(2));
    });
  });
}