import 'package:flutter_auditor/utils/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('PathUtils', () {
    test('relativeToRoot returns a forward-slash relative path', () {
      final result = PathUtils.relativeToRoot(
        '/project/lib/audits/foo.dart',
        '/project',
      );

      expect(result, 'lib/audits/foo.dart');
    });

    test('relativeToRoot handles a file directly at the root', () {
      final result = PathUtils.relativeToRoot(
        '/project/pubspec.yaml',
        '/project',
      );

      expect(result, 'pubspec.yaml');
    });
  });
}
