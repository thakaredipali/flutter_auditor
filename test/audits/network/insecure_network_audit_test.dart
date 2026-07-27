import 'package:flutter_auditor/audits/network/insecure_network_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('InsecureNetworkAudit', () {
    late InsecureNetworkAudit audit;

    setUp(() {
      audit = InsecureNetworkAudit();
    });

    test('returns no issues for clean code', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/api_client.dart': '''
const baseUrl = "https://api.example.com";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects a hardcoded cleartext HTTP URL', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/api_client.dart': '''
const baseUrl = "http://api.example.com/v1";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Cleartext HTTP URL');
      expect(result.issues.first.severity, Severity.medium);
    });

    test('ignores localhost and private-network HTTP URLs', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/api_client.dart': '''
const devUrl = "http://localhost:8080";
const emulatorUrl = "http://10.0.2.2:8080";
const lanUrl = "http://192.168.1.10:8080";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects a disabled certificate validation callback', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/http_client.dart': '''
final client = HttpClient()
  ..badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'Disabled Certificate Validation');
      expect(result.issues.first.severity, Severity.critical);
    });

    test(
      'does not flag a certificate callback that verifies pinning',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'lib/http_client.dart': '''
final client = HttpClient()
  ..badCertificateCallback =
      (cert, host, port) => cert.sha1 == pinnedSha1;
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );

    test('detects a WebView SSL error bypass', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/web_view.dart': '''
WebView(
  onSslAuthError: (SslAuthError handler) {
    handler.proceed();
  },
);
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, 'WebView SSL Error Bypass');
      expect(result.issues.first.severity, Severity.critical);
    });

    test('ignores non-dart files', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/notes.txt': '''
const baseUrl = "http://api.example.com";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
