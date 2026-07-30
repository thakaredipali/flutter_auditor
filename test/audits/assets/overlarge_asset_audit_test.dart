import 'package:flutter_auditor/audits/assets/overlarge_asset_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('OverlargeAssetAudit', () {
    late OverlargeAssetAudit audit;

    setUp(() {
      audit = OverlargeAssetAudit();
    });

    test('does not flag a small asset', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/icon.png
''',
          'assets/images/icon.png': 'a' * 1024, // 1 KB
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('flags a >=1MB asset as medium severity', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/photo.png
''',
          'assets/images/photo.png': 'a' * (2 * 1024 * 1024), // 2 MB
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.single;
      expect(issue.severity, Severity.medium);
      expect(issue.title, contains('assets/images/photo.png'));
    });

    test('flags a >=5MB asset as high severity', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/video/intro.mp4
''',
          'assets/video/intro.mp4': 'a' * (6 * 1024 * 1024), // 6 MB
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.single;
      expect(issue.severity, Severity.high);
    });

    test(
      'expands a declared asset directory and checks each file within it',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/
''',
            'assets/images/small.png': 'a' * 1024,
            'assets/images/large.png': 'a' * (2 * 1024 * 1024),
          },
        );

        final result = await audit.run(context);

        final flaggedPaths = result.issues.map((issue) => issue.title).toList();
        expect(flaggedPaths, hasLength(1));
        expect(flaggedPaths.single, contains('assets/images/large.png'));
      },
    );

    test('returns no issues when there is no flutter.assets section', () async {
      final context = await createProjectContextWithFiles(
        files: {'pubspec.yaml': 'name: my_app\n'},
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
