import 'package:flutter_auditor/audits/build/obfuscation_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('ObfuscationAudit', () {
    late ObfuscationAudit audit;

    setUp(() {
      audit = ObfuscationAudit();
    });

    test('detects release build without minifyEnabled (Groovy)', () async {
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

      final issue = result.issues.singleWhere(
        (issue) => issue.id == 'obfuscation.android_minify_disabled',
      );
      expect(issue.severity, Severity.medium);
    });

    test('detects minifyEnabled explicitly set to false', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
android {
    buildTypes {
        release {
            minifyEnabled false
        }
    }
}
''',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) => issue.id == 'obfuscation.android_minify_disabled',
        ),
        isTrue,
      );
    });

    test('does not flag minifyEnabled true (Groovy)', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle': '''
android {
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
''',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) => issue.id == 'obfuscation.android_minify_disabled',
        ),
        isFalse,
      );
    });

    test('does not flag isMinifyEnabled = true (Kotlin DSL)', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'android/app/build.gradle.kts': '''
android {
    buildTypes {
        release {
            isMinifyEnabled = true
        }
    }
}
''',
        },
      );

      final result = await audit.run(context);

      expect(
        result.issues.any(
          (issue) => issue.id == 'obfuscation.android_minify_disabled',
        ),
        isFalse,
      );
    });

    test('does nothing when there is no android directory', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.hasIssues, isFalse);
    });

    test('detects a scripted flutter build missing --obfuscate in a GitHub '
        'Actions workflow', () async {
      final context = await createProjectContextWithFiles(
        files: {
          '.github/workflows/release.yml': '''
jobs:
  build:
    steps:
      - run: flutter build appbundle --release
''',
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.singleWhere(
        (issue) => issue.title.contains('--obfuscate'),
      );
      expect(issue.severity, Severity.low);
      expect(issue.file, contains('release.yml'));
    });

    test(
      'does not flag a flutter build that already passes --obfuscate',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            '.github/workflows/release.yml': '''
jobs:
  build:
    steps:
      - run: flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
''',
          },
        );

        final result = await audit.run(context);

        expect(result.hasIssues, isFalse);
      },
    );

    test('does not flag a flutter build web invocation', () async {
      final context = await createProjectContextWithFiles(
        files: {
          '.github/workflows/release.yml': '''
jobs:
  build:
    steps:
      - run: flutter build web --release
''',
        },
      );

      final result = await audit.run(context);

      expect(result.hasIssues, isFalse);
    });

    test('scans Fastfile, codemagic.yaml, bitrise.yml, and Makefile', () async {
      final context = await createProjectContextWithFiles(
        files: {'fastlane/Fastfile': 'sh("flutter build ios --release")'},
      );

      final result = await audit.run(context);

      expect(
        result.issues.any((issue) => issue.title.contains('--obfuscate')),
        isTrue,
      );
    });
  });
}
