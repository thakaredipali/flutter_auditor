import 'package:flutter_audit/audits/ios/file_sharing_audit.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('FileSharingAudit', () {
    late FileSharingAudit audit;

    setUp(() {
      audit = FileSharingAudit();
    });

    test('returns no issues when Info.plist is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('returns no issues when file sharing is not enabled', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>UIFileSharingEnabled</key>
	<false/>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects UIFileSharingEnabled', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>UIFileSharingEnabled</key>
	<true/>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'File Sharing Enabled');
      expect(result.issues.first.severity, Severity.medium);
      expect(
        result.issues.first.description,
        isNot(contains('LSSupportsOpeningDocumentsInPlace')),
      );
    });

    test(
        'mentions LSSupportsOpeningDocumentsInPlace when also enabled',
        () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>UIFileSharingEnabled</key>
	<true/>
	<key>LSSupportsOpeningDocumentsInPlace</key>
	<true/>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.description,
        contains('LSSupportsOpeningDocumentsInPlace'),
      );
    });
  });
}
