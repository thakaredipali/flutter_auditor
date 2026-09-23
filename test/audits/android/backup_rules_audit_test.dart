import 'dart:io';

import 'package:flutter_auditor/audits/android/backup_rules_audit.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _xmlDir = 'android/app/src/main/res/xml';

void main() {
  group('BackupRulesAudit', () {
    late BackupRulesAudit audit;

    setUp(() {
      audit = BackupRulesAudit();
    });

    test('returns no issue when allowBackup is false', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:allowBackup="false">
    </application>
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('returns no issue when AndroidManifest.xml is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'flutter_auditor_test',
      );
      final context = ProjectContext(rootDirectory: tempDir);

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'flags missing fullBackupContent when backups are enabled by default',
      () async {
        final context = await createProjectContext(
          manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
    </application>
</manifest>
''',
        );

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.id,
          'android.backup_rules.missing_full_backup_content',
        );
        expect(result.issues.first.severity, Severity.medium);
      },
    );

    test('flags a referenced backup rules file that does not exist', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:fullBackupContent="@xml/backup_rules">
    </application>
</manifest>
''',
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'android.backup_rules.missing_backup_rules_file',
      );
    });

    test(
      'flags a referenced data extraction rules file that does not exist',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            _manifestPath: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules">
    </application>
</manifest>
''',
            '$_xmlDir/backup_rules.xml': '<full-backup-content />',
          },
        );

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.id,
          'android.backup_rules.missing_data_extraction_rules',
        );
      },
    );

    test('returns no issue when all referenced rule files exist', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules">
    </application>
</manifest>
''',
          '$_xmlDir/backup_rules.xml': '<full-backup-content />',
          '$_xmlDir/data_extraction_rules.xml': '<data-extraction-rules />',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'ignores fullBackupContent values that are not @xml references',
      () async {
        final context = await createProjectContext(
          manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:fullBackupContent="false">
    </application>
</manifest>
''',
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );
  });
}
