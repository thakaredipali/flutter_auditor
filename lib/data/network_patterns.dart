import '../models/severity.dart';
import 'pattern_rule.dart';

/// Known insecure-networking patterns checked by [InsecureNetworkAudit].
final List<PatternRule> networkPatterns = [
  PatternRule(
    name: 'Cleartext HTTP URL',
    pattern: RegExp(
      r'''["']http://(?!localhost|127\.0\.0\.1|10\.\d|172\.(1[6-9]|2\d|3[01])\.|192\.168\.)[^"']+["']''',
      caseSensitive: false,
    ),
    severity: Severity.medium,
    recommendation:
        'Use HTTPS for all network requests to protect data in transit from interception and tampering.',
  ),
  PatternRule(
    name: 'Disabled Certificate Validation',
    pattern: RegExp(
      r'badCertificateCallback\s*=[\s\S]{0,200}?=>\s*true',
      caseSensitive: false,
    ),
    severity: Severity.critical,
    recommendation:
        'Remove the badCertificateCallback override (or restrict it to pinned certificates) so invalid/MITM certificates are rejected.',
  ),
  PatternRule(
    name: 'WebView SSL Error Bypass',
    pattern: RegExp(
      r'on(?:SslAuthError|ReceivedSslError)\s*:[\s\S]{0,200}?\.proceed\(\)',
      caseSensitive: false,
    ),
    severity: Severity.critical,
    recommendation:
        'Do not call proceed() on SSL errors in the WebView; cancel the request instead so invalid certificates are rejected.',
  ),
];
