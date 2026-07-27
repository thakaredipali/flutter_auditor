import 'package:flutter_auditor/audits/secrets/hardcoded_secrets_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('HardcodedSecretsAudit', () {
    late HardcodedSecretsAudit audit;

    setUp(() {
      audit = HardcodedSecretsAudit();
    });

    test('returns no issues for clean code', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/main.dart': '''
void main() {
  final apiKey = String.fromEnvironment('API_KEY');
  print(apiKey);
}
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects a hardcoded AWS access key', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/aws_config.dart': '''
const awsKey = "AKIAABCDEFGHIJKLMNOP";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.severity, Severity.critical);
    });

    test('detects a hardcoded generic credential assignment', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/config.dart': '''
class Config {
  static const apiKey = "sk_test_51Hh0000000000000000abcdef";
}
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.title, contains('Hardcoded'));
      expect(result.issues.first.severity, Severity.high);
    });

    test(
      'ignores API endpoint path constants named like credentials',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'lib/api_paths.dart': r'''
class ApiPaths {
  static const String authApiPath = "/api/v1/auth";
  static const String generateAccessToken =
      "$authApiPath/login/generateAccessToken";
  static const String keyExchange = "$authApiPath/key-exchange";
}
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );

    test('ignores placeholder values', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/config.dart': '''
const apiKey = "your_api_key_here";
const password = "changeme123";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('detects a hardcoded private key', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/keys.dart': '''
const privateKey = \'\'\'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
-----END RSA PRIVATE KEY-----
\'\'\';
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isNotEmpty);
      expect(result.issues.first.severity, Severity.critical);
    });

    test(
      'does not duplicate a finding already caught by a specific pattern',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'lib/deep/nested_config.dart': '''
class Nested {
  static const token = "AKIAABCDEFGHIJKLMNOP";
}
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(result.issues.first.file, endsWith('nested_config.dart'));
        expect(result.issues.first.line, 2);
      },
    );

    test('scans dart files in nested directories', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/src/services/api_service.dart': '''
const password = "SuperSecretPassw0rd";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.file, contains('src/services'));
    });

    test('ignores firebase_options.dart', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/firebase_options.dart': '''
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLEKEY1234567890abcdefghijk',
    appId: '1:1234567890:android:abcdef1234567890',
  );
}
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores firebase_options flavor variants', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/firebase/firebase_options_uat.dart': '''
class UatFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1234567890abcdefghijklmnopqrstuv',
    appId: '1:1234567890:android:abcdef1234567890',
  );
}
''',
          'lib/firebase/firebase_options_dev.dart': '''
class DevFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1234567890abcdefghijklmnopqrstuw',
    appId: '1:1234567890:android:abcdef1234567890',
  );
}
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores non-dart files', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'lib/notes.txt': '''
const apiKey = "abcdefgh12345678";
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });
  });
}
