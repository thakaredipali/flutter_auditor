import 'package:flutter_auditor/audits/android/release_signing_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('ReleaseSigningAudit', () {
    late ReleaseSigningAudit audit;

    setUp(() {
      audit = ReleaseSigningAudit();
    });

    test('detects release build signed with the debug key (Groovy)', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
android {
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
''',
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.singleWhere(
        (issue) => issue.id == 'android.release_signing.debug_key_for_release',
      );
      expect(issue.severity, Severity.high);
    });

    test(
      'detects release build signed with the debug key (Kotlin DSL)',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'android/app/build.gradle.kts': '''
android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
''',
          },
        );

        final result = await audit.run(context);

        expect(
          result.issues.any(
            (issue) =>
                issue.id == 'android.release_signing.debug_key_for_release',
          ),
          isTrue,
        );
      },
    );

    test('does not flag a real release signing config', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
''',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) =>
              issue.id == 'android.release_signing.debug_key_for_release',
        ),
        isFalse,
      );
    });

    test('detects a hardcoded store password', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
signingConfigs {
    release {
        storePassword 'MySecretPass123'
        keyAlias 'upload'
    }
}
''',
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.singleWhere(
        (issue) => issue.title.contains('storePassword'),
      );
      expect(issue.severity, Severity.critical);
    });

    test('does not flag a password loaded from a properties map', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
signingConfigs {
    release {
        storePassword keystoreProperties['storePassword']
        keyPassword keystoreProperties['keyPassword']
    }
}
''',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.where(
          (issue) => issue.title.contains('Hardcoded Signing Credential'),
        ),
        isEmpty,
      );
    });

    test('flags key.properties that is not covered by .gitignore', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/key.properties': 'storePassword=secret\n',
          '.gitignore': 'build/\n',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) =>
              issue.id == 'android.release_signing.key_properties_not_ignored',
        ),
        isTrue,
      );
    });

    test('does not flag key.properties that is gitignored', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/key.properties': 'storePassword=secret\n',
          '.gitignore': 'key.properties\n',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) =>
              issue.id == 'android.release_signing.key_properties_not_ignored',
        ),
        isFalse,
      );
    });

    test('returns no issues when build.gradle is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
