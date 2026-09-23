import 'dart:io';

import 'package:flutter_auditor/audits/android/network_security_config_audit.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

const _manifestWithConfig = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config">
    </application>
</manifest>
''';

const _configPath = 'android/app/src/main/res/xml/network_security_config.xml';

Future<ProjectContext> _contextWithConfig(String config) =>
    createProjectContextWithFiles(
      files: {
        'android/app/src/main/AndroidManifest.xml': _manifestWithConfig,
        _configPath: config,
      },
    );

void main() {
  group('NetworkSecurityConfigAudit', () {
    late NetworkSecurityConfigAudit audit;

    setUp(() {
      audit = NetworkSecurityConfigAudit();
    });

    test('returns no issue when no config is referenced', () async {
      final context = await createProjectContext(
        manifestContent: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
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

    test('flags a referenced config file that does not exist', () async {
      final context = await createProjectContext(
        manifestContent: _manifestWithConfig,
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'android.network_security_config.missing_file',
      );
      expect(result.issues.first.severity, Severity.medium);
    });

    test('flags a config file that is not valid XML', () async {
      final context = await _contextWithConfig('<network-security-config>');

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'android.network_security_config.parse_error',
      );
      expect(result.issues.first.severity, Severity.low);
    });

    test('returns no issue for a secure config', () async {
      final context = await _contextWithConfig('''
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
''');

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('flags cleartext traffic in base-config as high', () async {
      final context = await _contextWithConfig('''
<network-security-config>
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
''');

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'android.network_security_config.cleartext_traffic',
      );
      expect(result.issues.first.severity, Severity.high);
    });

    test('flags cleartext traffic in domain-config as high', () async {
      final context = await _contextWithConfig('''
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">example.com</domain>
    </domain-config>
</network-security-config>
''');

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.high);
    });

    test(
      'downgrades cleartext traffic inside debug-overrides to low',
      () async {
        final context = await _contextWithConfig('''
<network-security-config>
    <debug-overrides cleartextTrafficPermitted="true" />
</network-security-config>
''');

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.id,
          'android.network_security_config.cleartext_traffic_debug',
        );
        expect(result.issues.first.severity, Severity.low);
      },
    );

    test('flags user certificates trusted in base-config as high', () async {
      final context = await _contextWithConfig('''
<network-security-config>
    <base-config>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
''');

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'android.network_security_config.user_certificates',
      );
      expect(result.issues.first.severity, Severity.high);
    });

    test(
      'downgrades user certificates inside debug-overrides to low',
      () async {
        final context = await _contextWithConfig('''
<network-security-config>
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>
''');

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.id,
          'android.network_security_config.user_certificates_debug',
        );
        expect(result.issues.first.severity, Severity.low);
      },
    );
  });
}
