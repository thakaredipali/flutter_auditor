import 'package:flutter_audit/audits/android/exported_components_audit.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('ExportedComponentsAudit', () {
    late ExportedComponentsAudit audit;

    setUp(() {
      audit = ExportedComponentsAudit();
    });

    test('returns no issues when no components are exported', () async {

final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name=".MainActivity"
            android:exported="true" />
    </application>
</manifest>
''',
);

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects exported activity', () async {

final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name=".MainActivity"
            android:exported="true" />
    </application>
</manifest>
''',
);

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects exported service', () async {

final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <service
            android:name=".SyncService"
            android:exported="true" />
    </application>
</manifest>
''',
);

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects exported receiver', () async {
final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <receiver
            android:name=".BootReceiver"
            android:exported="true" />
    </application>
</manifest>
''',
);

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects exported provider', () async {


final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <provider
            android:name=".DataProvider"
            android:exported="true" />
    </application>
</manifest>
''',
);


      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects multiple exported components', () async {
      final context = await createProjectContext( 
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name=".MainActivity"
            android:exported="true" />

        <service
            android:name=".SyncService"
            android:exported="true" />

        <receiver
            android:name=".BootReceiver"
            android:exported="true" />
    </application>
</manifest>
''');




      final result = await audit.run(context);

      expect(result.issues.length, 3);
    });

    test('ignores components without exported attribute', () async {

final context = await createProjectContext(
  manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''',
);



      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}