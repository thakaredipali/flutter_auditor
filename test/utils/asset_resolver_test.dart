import 'package:flutter_auditor/utils/asset_resolver.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

void main() {
  group('AssetResolver', () {
    test('resolves an individually-declared asset', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/logo.png
''',
          'assets/images/logo.png': 'fake',
        },
      );

      final resolved = await AssetResolver.resolveDeclaredAssets(context);

      expect(resolved, hasLength(1));
      expect(resolved.single.relativePath, 'assets/images/logo.png');
    });

    test('expands a declared directory to its files', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/icons/
''',
          'assets/icons/star.png': 'fake',
          'assets/icons/heart.png': 'fake',
        },
      );

      final resolved = await AssetResolver.resolveDeclaredAssets(context);

      final paths = resolved.map((asset) => asset.relativePath).toSet();
      expect(paths, {'assets/icons/star.png', 'assets/icons/heart.png'});
    });

    test('skips a declared path that does not exist on disk', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
flutter:
  assets:
    - assets/images/missing.png
''',
        },
      );

      final resolved = await AssetResolver.resolveDeclaredAssets(context);

      expect(resolved, isEmpty);
    });

    test(
      'returns an empty list when there is no flutter.assets section',
      () async {
        final context = await createProjectContextWithFiles(
          files: {'pubspec.yaml': 'name: my_app\n'},
        );

        final resolved = await AssetResolver.resolveDeclaredAssets(context);

        expect(resolved, isEmpty);
      },
    );
  });
}
