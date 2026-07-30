import 'package:flutter_auditor/utils/ignore_config_helper.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

void main() {
  group('IgnoreConfigHelper', () {
    test('returns an empty config when the file is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final config = await IgnoreConfigHelper.load(context);

      expect(config.isEmpty, isTrue);
    });

    test('parses audits, ids, and files lists', () async {
      final context = await createProjectContextWithFiles(
        files: {
          '.flutter_auditor_ignore.yaml': '''
audits:
  - android_release_signing
ids:
  - android.allow_backup
files:
  - test/fixtures/**
''',
        },
      );

      final config = await IgnoreConfigHelper.load(context);

      expect(config.auditIds, {'android_release_signing'});
      expect(config.issueIds, {'android.allow_backup'});
      expect(config.filePatterns, ['test/fixtures/**']);
    });

    test('returns an empty config for malformed YAML', () async {
      final context = await createProjectContextWithFiles(
        files: {'.flutter_auditor_ignore.yaml': ': not: valid: yaml: :'},
      );

      final config = await IgnoreConfigHelper.load(context);

      expect(config.isEmpty, isTrue);
    });

    test('tolerates a missing section', () async {
      final context = await createProjectContextWithFiles(
        files: {
          '.flutter_auditor_ignore.yaml': '''
audits:
  - android_release_signing
''',
        },
      );

      final config = await IgnoreConfigHelper.load(context);

      expect(config.auditIds, {'android_release_signing'});
      expect(config.issueIds, isEmpty);
      expect(config.filePatterns, isEmpty);
    });
  });
}
