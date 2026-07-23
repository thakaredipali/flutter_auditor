import '../models/severity.dart';
import 'secret_pattern.dart';

/// Known secret patterns checked by [HardcodedSecretsAudit].
final List<SecretPattern> secretPatterns = [
  SecretPattern(
    name: 'AWS Access Key ID',
    pattern: RegExp(r'AKIA[0-9A-Z]{16}'),
    severity: Severity.critical,
    recommendation:
        'Remove the AWS access key from source control, rotate it, and load credentials from a secure secret manager or environment variable.',
  ),
  SecretPattern(
    name: 'Google API Key',
    pattern: RegExp(r'AIza[0-9A-Za-z\-_]{35}'),
    severity: Severity.high,
    recommendation:
        'Move the Google API key out of source code and restrict its usage via the Google Cloud Console.',
  ),
  SecretPattern(
    name: 'Stripe Live Secret Key',
    pattern: RegExp(r'sk_live_[0-9a-zA-Z]{16,}'),
    severity: Severity.critical,
    recommendation:
        'Revoke this Stripe key immediately and load secret keys from a secure secret manager.',
  ),
  SecretPattern(
    name: 'Slack Token',
    pattern: RegExp(r'xox[baprs]-[0-9A-Za-z-]{10,48}'),
    severity: Severity.high,
    recommendation:
        'Revoke the Slack token and store credentials outside of source control.',
  ),
  SecretPattern(
    name: 'Private Key',
    pattern: RegExp(r'-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'),
    severity: Severity.critical,
    recommendation:
        'Remove the private key from source control and rotate the compromised key pair.',
  ),
  SecretPattern(
    name: 'JSON Web Token',
    pattern: RegExp(
      r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
    ),
    severity: Severity.medium,
    recommendation:
        'Avoid hardcoding JWTs in source code; issue and store tokens securely at runtime.',
  ),
  SecretPattern(
    name: 'Hardcoded Credential',
    pattern: RegExp(
      // Excludes "/" from the captured value so API endpoint path constants
      // (e.g. `generateAccessToken = "$authApiPath/login/generateAccessToken"`)
      // aren't mistaken for a hardcoded secret value.
      r'''(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|access[_-]?token|auth[_-]?token|token|password|passwd|pwd)\s*[:=]\s*["']([^"'/]{8,})["']''',
      caseSensitive: false,
    ),
    severity: Severity.high,
    recommendation:
        'Remove the hardcoded credential and load it from a secure secret store or environment variable.',
    isGeneric: true,
  ),
];
