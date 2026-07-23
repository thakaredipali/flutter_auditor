import '../models/severity.dart';
import 'pattern_rule.dart';

/// Known insecure-storage patterns checked by [InsecureStorageAudit].
final List<PatternRule> storagePatterns = [
  PatternRule(
    name: 'Sensitive Data in SharedPreferences',
    pattern: RegExp(
      r'''\.set(?:String|Int|Bool|Double|StringList)\(\s*["'][^"']*(?:token|password|secret|pin|credential|auth)[^"']*["']''',
      caseSensitive: false,
    ),
    severity: Severity.high,
    recommendation:
        'SharedPreferences stores data in plaintext. Use flutter_secure_storage (backed by Keychain/Keystore) for tokens, passwords, and other sensitive values.',
  ),
  PatternRule(
    name: 'Sensitive Data in Unencrypted Hive Box',
    pattern: RegExp(
      r'''Hive\.(?:open)?[Bb]ox(?:<[^>]*>)?\(\s*["'][^"']*(?:token|password|secret|pin|credential|auth)[^"']*["']''',
      caseSensitive: false,
    ),
    severity: Severity.high,
    recommendation:
        'Open this Hive box with an encryptionCipher (HiveAesCipher) or move the sensitive value to flutter_secure_storage instead of storing it in plaintext.',
  ),
];
