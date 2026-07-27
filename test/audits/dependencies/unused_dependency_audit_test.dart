import 'package:flutter_auditor/audits/dependencies/unused_dependency_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('UnusedDependencyAudit', () {
    late UnusedDependencyAudit audit;

    String lockFileFor(Map<String, String> versions) {
      final buffer = StringBuffer('packages:\n');

      for (final entry in versions.entries) {
        buffer.writeln('''
  ${entry.key}:
    dependency: "direct main"
    description:
      name: ${entry.key}
      url: "https://pub.dev"
    source: hosted
    version: "${entry.value}"''');
      }

      return buffer.toString();
    }

    setUp(() {
      audit = UnusedDependencyAudit();
    });

    test('returns no issues when pubspec.lock is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects an unused dependency', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  foo: ^1.0.0
''',
          'pubspec.lock': lockFileFor({'foo': '1.0.0'}),
          'lib/main.dart': 'void main() {}\n',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Unused Dependency: foo');
      expect(result.issues.first.severity, Severity.low);
      expect(result.issues.first.file, endsWith('pubspec.yaml'));
    });

    test('does not flag a dependency imported directly', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  foo: ^1.0.0
''',
          'pubspec.lock': lockFileFor({'foo': '1.0.0'}),
          'lib/main.dart': "import 'package:foo/foo.dart';\n",
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('does not flag a dependency imported via export', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  foo: ^1.0.0
''',
          'pubspec.lock': lockFileFor({'foo': '1.0.0'}),
          'lib/barrel.dart': "export 'package:foo/foo.dart';\n",
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'does not flag a dependency imported only in a nested directory',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  foo: ^1.0.0
''',
            'pubspec.lock': lockFileFor({'foo': '1.0.0'}),
            'lib/src/widgets/thing.dart': "import 'package:foo/foo.dart';\n",
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );

    test('does not flag ignore-listed packages like cupertino_icons', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  cupertino_icons: ^1.0.0
''',
          'pubspec.lock': lockFileFor({'cupertino_icons': '1.0.0'}),
          'lib/main.dart': 'void main() {}\n',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores transitive and dev dependencies', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
''',
          'pubspec.lock': '''
packages:
  foo:
    dependency: transitive
    description:
      name: foo
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  bar:
    dependency: "direct dev"
    description:
      name: bar
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
''',
          'lib/main.dart': 'void main() {}\n',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores sdk-sourced dependencies (e.g. flutter)', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
''',
          'pubspec.lock': '''
packages:
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
''',
          'lib/main.dart': 'void main() {}\n',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
