import 'dart:io';

import 'package:flutter_audit/models/audit.dart';
import 'package:flutter_audit/models/audit_result.dart';
import 'package:flutter_audit/models/project_context.dart';
import 'package:flutter_audit/models/security_issue.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:flutter_audit/utils/android_manifest_helper.dart';
import 'package:xml/xml.dart';

class NetworkSecurityConfigAudit extends Audit {
  static const _androidNamespace =
      'http://schemas.android.com/apk/res/android';

  @override
  String get id => 'network_security_config';

  @override
  String get name => 'Network Security Config Audit';

  @override
  String get description =>
      'Checks the Android Network Security Configuration for insecure settings.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final manifest = await AndroidManifestHelper.load(context);

    if (manifest == null) {
      return AuditResult(issues: issues);
    }

    final application = manifest.findAllElements('application').firstOrNull;

    if (application == null) {
      return AuditResult(issues: issues);
    }

    final configReference = application.getAttribute(
      'networkSecurityConfig',
      namespace: _androidNamespace,
    );

    if (configReference == null || !configReference.startsWith('@xml/')) {
      // No custom config referenced — Android's default secure behavior applies
      // (cleartext traffic blocked by default on API 28+).
      return AuditResult(issues: issues);
    }

    final configFile = File(
      '${context.rootPath}/android/app/src/main/res/xml/'
      '${configReference.replaceFirst('@xml/', '')}.xml',
    );

    if (!configFile.existsSync()) {
      issues.add(
        SecurityIssue(
          id: 'android.network_security_config.missing_file',
          severity: Severity.medium,
          title: 'Missing Network Security Configuration',
          description:
              'The manifest references "$configReference", but the file does not exist.',
          recommendation:
              'Create the referenced network security configuration file or remove the attribute.',
          file: context.androidManifest.path,
        ),
      );

      return AuditResult(issues: issues);
    }

    // --- Parse XML safely ---
    XmlDocument document;
    try {
      document = XmlDocument.parse(await configFile.readAsString());
    } catch (e) {
      issues.add(
        SecurityIssue(
          id: 'android.network_security_config.parse_error',
          severity: Severity.low,
          title: 'Unable to Parse Network Security Configuration',
          description:
              'The file at "${configFile.path}" could not be parsed as valid XML: $e',
          recommendation:
              'Verify the XML syntax of the network security configuration file.',
          file: configFile.path,
        ),
      );

      return AuditResult(issues: issues);
    }

    _checkCleartextTraffic(document, configFile.path, issues);
    _checkUserCertificates(document, configFile.path, issues);

    return AuditResult(issues: issues);
  }

  /// Checks for `cleartextTrafficPermitted="true"` in `base-config` and
  /// `domain-config` blocks. Entries found only inside `debug-overrides`
  /// are downgraded, since that block is stripped from release builds
  /// automatically by the Android Gradle plugin.
  void _checkCleartextTraffic(
    XmlDocument document,
    String file,
    List<SecurityIssue> issues,
  ) {
    final root = document.rootElement;

    for (final section in root.childElements) {
      final isDebugOnly = section.name.local == 'debug-overrides';

      if (section.name.local != 'base-config' &&
          section.name.local != 'domain-config' &&
          !isDebugOnly) {
        continue;
      }

      // For debug-overrides, look one level deeper for nested configs too.
      final configs = isDebugOnly
          ? [section, ...section.findAllElements('domain-config')]
          : [section];

      for (final config in configs) {
        final cleartext = config.getAttribute('cleartextTrafficPermitted');

        if (cleartext == 'true') {
          issues.add(
            SecurityIssue(
              id: isDebugOnly
                  ? 'android.network_security_config.cleartext_traffic_debug'
                  : 'android.network_security_config.cleartext_traffic',
              severity: isDebugOnly ? Severity.low : Severity.high,
              title: isDebugOnly
                  ? 'Cleartext Traffic Allowed (debug-overrides only)'
                  : 'Cleartext Traffic Allowed',
              description: isDebugOnly
                  ? 'Cleartext traffic is permitted inside debug-overrides, which is normal for local debug testing and is stripped from release builds automatically.'
                  : 'The Network Security Configuration permits unencrypted HTTP traffic in a production config block.',
              recommendation: isDebugOnly
                  ? 'No action needed if this remains inside debug-overrides only.'
                  : 'Disable cleartext traffic unless it is explicitly required, and scope it to specific domains only if necessary.',
              file: file,
            ),
          );
        }
      }
    }
  }

  /// Checks for `<certificates src="user"/>` trust anchors. Entries found
  /// only inside `debug-overrides` are downgraded, since that block is
  /// stripped from release builds automatically and is a normal way to
  /// test with local MITM proxies (e.g., Charles, Burp) during development.
  void _checkUserCertificates(
    XmlDocument document,
    String file,
    List<SecurityIssue> issues,
  ) {
    final root = document.rootElement;

    for (final section in root.childElements) {
      final isDebugOnly = section.name.local == 'debug-overrides';
      final certificates = section.findAllElements('certificates');

      for (final certificate in certificates) {
        if (certificate.getAttribute('src') == 'user') {
          issues.add(
            SecurityIssue(
              id: isDebugOnly
                  ? 'android.network_security_config.user_certificates_debug'
                  : 'android.network_security_config.user_certificates',
              severity: isDebugOnly ? Severity.low : Severity.high,
              title: isDebugOnly
                  ? 'User Certificates Trusted (debug-overrides only)'
                  : 'User-installed Certificates Trusted in Production',
              description: isDebugOnly
                  ? 'debug-overrides trusts user-installed CA certificates — this is normal for debug builds and is automatically stripped from release builds.'
                  : 'The application trusts user-installed CA certificates in a production config block, which can enable man-in-the-middle attacks if a malicious certificate is installed on the device.',
              recommendation: isDebugOnly
                  ? 'No action needed if this trust anchor stays inside debug-overrides only.'
                  : 'Remove user certificate trust from base-config/domain-config unless explicitly required for a compelling, justified use case.',
              file: file,
            ),
          );
        }
      }
    }
  }
}