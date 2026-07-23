import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/info_plist_helper.dart';

/// Checks Info.plist's NSAppTransportSecurity for settings that weaken or
/// disable App Transport Security (iOS's equivalent of Android's
/// cleartext-traffic / network-security-config protections).
class AppTransportSecurityAudit extends Audit {
  static const _weakTlsVersions = ['TLSv1.0', 'TLSv1.1'];

  @override
  String get id => 'ios_app_transport_security';

  @override
  String get name => 'App Transport Security Audit';

  @override
  String get description =>
      'Checks Info.plist for App Transport Security exceptions that allow insecure HTTP traffic.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final plist = await InfoPlistHelper.load(context);

    if (plist == null) {
      return AuditResult(issues: issues);
    }

    final ats = plist['NSAppTransportSecurity'];

    if (ats is! Map<String, dynamic>) {
      return AuditResult(issues: issues);
    }

    final file = context.iosInfoPlist.path;

    _checkArbitraryLoads(ats, file, issues);
    _checkExceptionDomains(ats, file, issues);

    return AuditResult(issues: issues);
  }

  void _checkArbitraryLoads(
    Map<String, dynamic> ats,
    String file,
    List<SecurityIssue> issues,
  ) {
    if (ats['NSAllowsArbitraryLoads'] == true) {
      issues.add(
        SecurityIssue(
          id: 'ios.ats.arbitrary_loads',
          title: 'App Transport Security Disabled',
          description:
              'NSAllowsArbitraryLoads is set to true, which disables App Transport Security app-wide and allows unencrypted HTTP traffic to any host.',
          severity: Severity.high,
          file: file,
          recommendation:
              'Remove NSAllowsArbitraryLoads (or set it to false) and add scoped NSExceptionDomains entries only for domains that genuinely require an exception.',
        ),
      );
    }

    if (ats['NSAllowsArbitraryLoadsInWebContent'] == true) {
      issues.add(
        SecurityIssue(
          id: 'ios.ats.arbitrary_loads_web_content',
          title: 'App Transport Security Disabled for Web Content',
          description:
              'NSAllowsArbitraryLoadsInWebContent is set to true, allowing unencrypted HTTP traffic loaded via WKWebView/UIWebView.',
          severity: Severity.medium,
          file: file,
          recommendation:
              'Remove NSAllowsArbitraryLoadsInWebContent unless the app must load arbitrary HTTP content in a web view.',
        ),
      );
    }
  }

  void _checkExceptionDomains(
    Map<String, dynamic> ats,
    String file,
    List<SecurityIssue> issues,
  ) {
    final exceptionDomains = ats['NSExceptionDomains'];

    if (exceptionDomains is! Map<String, dynamic>) {
      return;
    }

    for (final entry in exceptionDomains.entries) {
      final domain = entry.key;
      final config = entry.value;

      if (config is! Map<String, dynamic>) {
        continue;
      }

      if (config['NSExceptionAllowsInsecureHTTPLoads'] == true) {
        issues.add(
          SecurityIssue(
            id: 'ios.ats.exception_insecure_http.$domain',
            title: 'Insecure HTTP Allowed for "$domain"',
            description:
                'NSExceptionAllowsInsecureHTTPLoads is true for "$domain", allowing unencrypted HTTP traffic to this host.',
            severity: Severity.high,
            file: file,
            recommendation:
                'Remove the NSExceptionAllowsInsecureHTTPLoads exception for "$domain" and use HTTPS instead.',
          ),
        );
      }

      final minTlsVersion = config['NSExceptionMinimumTLSVersion'];

      if (minTlsVersion is String && _weakTlsVersions.contains(minTlsVersion)) {
        issues.add(
          SecurityIssue(
            id: 'ios.ats.weak_tls.$domain',
            title: 'Weak Minimum TLS Version for "$domain"',
            description:
                'NSExceptionMinimumTLSVersion for "$domain" is set to $minTlsVersion, which is deprecated and known to be vulnerable.',
            severity: Severity.medium,
            file: file,
            recommendation:
                'Raise NSExceptionMinimumTLSVersion for "$domain" to TLSv1.2 or higher.',
          ),
        );
      }
    }
  }
}
