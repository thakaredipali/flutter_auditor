import 'package:flutter_auditor/audits/ios/app_transport_security_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('AppTransportSecurityAudit', () {
    late AppTransportSecurityAudit audit;

    setUp(() {
      audit = AppTransportSecurityAudit();
    });

    test('returns no issues when Info.plist is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('returns no issues for a plist without ATS exceptions', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects NSAllowsArbitraryLoads', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'App Transport Security Disabled');
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects NSAllowsArbitraryLoadsInWebContent', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoadsInWebContent</key>
		<true/>
	</dict>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.title,
        'App Transport Security Disabled for Web Content',
      );
      expect(result.issues.first.severity, Severity.medium);
    });

    test('detects an exception domain allowing insecure HTTP loads',
        () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>example.com</key>
			<dict>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<true/>
			</dict>
		</dict>
	</dict>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.title,
        'Insecure HTTP Allowed for "example.com"',
      );
      expect(result.issues.first.severity, Severity.high);
    });

    test('detects a weak minimum TLS version for an exception domain',
        () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>legacy.example.com</key>
			<dict>
				<key>NSExceptionMinimumTLSVersion</key>
				<string>TLSv1.0</string>
			</dict>
		</dict>
	</dict>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.title,
        'Weak Minimum TLS Version for "legacy.example.com"',
      );
      expect(result.issues.first.severity, Severity.medium);
    });

    test('does not flag an exception domain pinned to TLSv1.2', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>secure.example.com</key>
			<dict>
				<key>NSExceptionMinimumTLSVersion</key>
				<string>TLSv1.2</string>
			</dict>
		</dict>
	</dict>
</dict>
</plist>
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
