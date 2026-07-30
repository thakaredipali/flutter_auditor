import 'package:flutter_auditor/audits/assets/unused_asset_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('UnusedAssetAudit', () {
    late UnusedAssetAudit audit;

    setUp(() {
      audit = UnusedAssetAudit();
    });

    test('detects an unused individually-declared asset', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/logo.png
''',
          'assets/images/logo.png': 'fake image bytes',
          'lib/main.dart': 'void main() {}',
        },
      );

      final result = await audit.run(context);

      final issue = result.issues.single;
      expect(issue.title, contains('assets/images/logo.png'));
      expect(issue.severity, Severity.low);
    });

    test('does not flag an asset referenced in Dart source', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/logo.png
''',
          'assets/images/logo.png': 'fake image bytes',
          'lib/main.dart': "Image.asset('assets/images/logo.png');",
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'expands a declared asset directory and flags unused files within it',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
flutter:
  assets:
    - assets/icons/
''',
            'assets/icons/star.png': 'fake',
            'assets/icons/heart.png': 'fake',
            'lib/main.dart': "Image.asset('assets/icons/star.png');",
          },
        );

        final result = await audit.run(context);

        final unusedPaths = result.issues.map((issue) => issue.title).toSet();
        expect(unusedPaths, {'Unused Asset: assets/icons/heart.png'});
      },
    );

    test(
      'does not flag a declared asset that does not exist on disk',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/missing.png
''',
            'lib/main.dart': 'void main() {}',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );

    test('returns no issues when there is no flutter.assets section', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': 'name: my_app\n',
          'lib/main.dart': 'void main() {}',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
