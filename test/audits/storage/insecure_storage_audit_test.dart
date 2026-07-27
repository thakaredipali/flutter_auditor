import 'package:flutter_auditor/audits/storage/insecure_storage_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('InsecureStorageAudit', () {
    late InsecureStorageAudit audit;

    setUp(() {
      audit = InsecureStorageAudit();
    });

    test('returns no issues for clean code', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/settings.dart': '''
await prefs.setBool("isLoggedIn", true);
await prefs.setString("theme_mode", "dark");
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects sensitive data stored via SharedPreferences', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/auth_storage.dart': '''
await prefs.setString("auth_token", token);
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.title,
        'Sensitive Data in SharedPreferences',
      );
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects sensitive data stored in an unencrypted Hive box',
        () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/hive_setup.dart': '''
final box = await Hive.openBox("authTokens");
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.title,
        'Sensitive Data in Unencrypted Hive Box',
      );
      expect(result.issues.first.severity, Severity.high);
    });

    test('ignores non-sensitive Hive box names', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/hive_setup.dart': '''
final box = await Hive.openBox("settingsBox");
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores non-dart files', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/notes.txt': '''
await prefs.setString("auth_token", token);
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
