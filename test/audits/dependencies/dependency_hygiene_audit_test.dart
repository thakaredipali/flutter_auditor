import 'package:flutter_auditor/audits/dependencies/dependency_hygiene_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/utils/pub_dev_client.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

/// Canned pub.dev responses, keyed by package name, so tests never touch
/// the network.
class FakePubDevClient extends PubDevClient {
  final Map<String, String> latestVersions;
  final Map<String, List<String>> tagsByPackage;

  FakePubDevClient({
    this.latestVersions = const {},
    this.tagsByPackage = const {},
  });

  @override
  Future<Map<String, dynamic>?> fetchPackageInfo(String name) async {
    final latest = latestVersions[name];

    if (latest == null) {
      return null;
    }

    return {
      'latest': {'version': latest},
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchMetrics(String name) async {
    final tags = tagsByPackage[name];

    if (tags == null) {
      return null;
    }

    return {
      'score': {'tags': tags},
    };
  }
}

void main() {
  group('DependencyHygieneAudit', () {
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

    test('returns no issues for a clean, up-to-date project', () async {
      final client = FakePubDevClient(
        latestVersions: {'foo': '1.0.0'},
        tagsByPackage: {
          'foo': ['is:null-safe', 'license:mit'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'detects a dependency one major version behind as low severity',
      () async {
        final client = FakePubDevClient(
          latestVersions: {'foo': '2.0.0'},
          tagsByPackage: {
            'foo': ['is:null-safe', 'license:mit'],
          },
        );

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
          },
        );

        final result = await DependencyHygieneAudit(
          client: client,
        ).run(context);

        expect(result.issues.length, 1);
        expect(result.issues.first.title, 'Newer Major Version Available: foo');
        expect(result.issues.first.severity, Severity.low);
      },
    );

    test(
      'detects a dependency two or more major versions behind as medium severity',
      () async {
        final client = FakePubDevClient(
          latestVersions: {'foo': '3.0.0'},
          tagsByPackage: {
            'foo': ['is:null-safe', 'license:mit'],
          },
        );

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
          },
        );

        final result = await DependencyHygieneAudit(
          client: client,
        ).run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.title,
          'Dependency Significantly Outdated: foo',
        );
        expect(result.issues.first.severity, Severity.medium);
      },
    );

    test(
      'does not flag a minor/patch-only version lag within the same major',
      () async {
        final client = FakePubDevClient(
          latestVersions: {'foo': '1.2.5'},
          tagsByPackage: {
            'foo': ['is:null-safe', 'license:mit'],
          },
        );

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
          },
        );

        final result = await DependencyHygieneAudit(
          client: client,
        ).run(context);

        expect(result.issues, isEmpty);
      },
    );

    test('detects a discontinued dependency', () async {
      final client = FakePubDevClient(
        latestVersions: {'foo': '1.0.0'},
        tagsByPackage: {
          'foo': ['is:discontinued', 'is:null-safe', 'license:mit'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Discontinued Dependency: foo');
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects a restricted (copyleft) license', () async {
      final client = FakePubDevClient(
        latestVersions: {'foo': '1.0.0'},
        tagsByPackage: {
          'foo': ['is:null-safe', 'license:gpl-3.0'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Restricted License: foo (gpl-3.0)');
      expect(result.issues.first.severity, Severity.medium);
    });

    test('detects a missing license', () async {
      final client = FakePubDevClient(
        latestVersions: {'foo': '1.0.0'},
        tagsByPackage: {
          'foo': ['is:null-safe'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'No License Detected: foo');
      expect(result.issues.first.severity, Severity.low);
    });

    test('detects a very old project SDK constraint', () async {
      final client = FakePubDevClient();

      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ">=2.7.0 <3.0.0"
dependencies:
''',
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Very Old Dart SDK Constraint');
      expect(result.issues.first.severity, Severity.high);
    });

    test('does not flag a modern project SDK constraint', () async {
      final client = FakePubDevClient();

      final context = await createProjectContextWithFiles(
        files: {
          'pubspec.yaml': '''
name: sample_app
environment:
  sdk: ^3.0.0
dependencies:
''',
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores transitive and dev dependencies', () async {
      final client = FakePubDevClient(
        latestVersions: {'foo': '2.0.0', 'bar': '2.0.0'},
        tagsByPackage: {
          'foo': ['is:discontinued', 'is:null-safe', 'license:mit'],
          'bar': ['is:discontinued', 'is:null-safe', 'license:mit'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores sdk-sourced dependencies (e.g. flutter)', () async {
      final client = FakePubDevClient(
        latestVersions: {'flutter': '99.0.0'},
        tagsByPackage: {
          'flutter': ['is:discontinued'],
        },
      );

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
        },
      );

      final result = await DependencyHygieneAudit(client: client).run(context);

      expect(result.issues, isEmpty);
    });
  });
}
