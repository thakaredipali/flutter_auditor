import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/info_plist_helper.dart';

/// Checks Info.plist for UIFileSharingEnabled, which exposes the app's
/// Documents directory to the user via the Files app, Finder, and iTunes.
class FileSharingAudit extends Audit {
  @override
  String get id => 'ios_file_sharing';

  @override
  String get name => 'File Sharing Audit';

  @override
  String get description =>
      'Checks whether UIFileSharingEnabled exposes the app\'s Documents directory to external file access.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final plist = await InfoPlistHelper.load(context);

    if (plist == null || plist['UIFileSharingEnabled'] != true) {
      return AuditResult(issues: issues);
    }

    final supportsOpeningInPlace =
        plist['LSSupportsOpeningDocumentsInPlace'] == true;

    issues.add(
      SecurityIssue(
        id: 'ios.file_sharing.enabled',
        title: 'File Sharing Enabled',
        description: supportsOpeningInPlace
            ? 'UIFileSharingEnabled and LSSupportsOpeningDocumentsInPlace are both true, exposing the app\'s Documents directory to the Files app, Finder, and iTunes, and allowing other apps to open and edit those files directly.'
            : 'UIFileSharingEnabled is true, exposing the app\'s Documents directory to the Files app, Finder, and iTunes.',
        severity: Severity.medium,
        file: context.iosInfoPlist.path,
        recommendation:
            'Set UIFileSharingEnabled to false unless the app must share files with users this way, and never store sensitive data (tokens, credentials, private user data) in the Documents directory while it is enabled.',
      ),
    );

    return AuditResult(issues: issues);
  }
}
