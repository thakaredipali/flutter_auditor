import '../data/maintenance_audit_ids.dart';
import '../utils/path_utils.dart';
import 'audit_result.dart';
import 'audit_run_result.dart';
import 'project_context.dart';
import 'security_issue.dart';
import 'severity.dart';

/// A snapshot of findings accepted as pre-existing, loaded from a
/// project's `.flutter_auditor_baseline.json`, so future runs only fail on
/// newly introduced findings.
///
/// Fingerprinted by (audit id, file, description) rather than by line
/// number or byte offset: those shift with unrelated edits elsewhere in
/// the file, which would make the baseline silently "expire" findings it
/// shouldn't. The tradeoff is that two distinct findings of the same type
/// in the same file collapse to one fingerprint — acceptable for a
/// baseline, whose job is deciding what's pre-existing, not deduplicating
/// precisely.
class BaselineConfig {
  final Set<String> fingerprints;

  const BaselineConfig({this.fingerprints = const {}});

  bool get isEmpty => fingerprints.isEmpty;

  static String fingerprintFor(
    String auditId,
    SecurityIssue issue,
    ProjectContext context,
  ) {
    final relativeFile = PathUtils.relativeToRoot(issue.file, context.rootPath);
    return '$auditId|$relativeFile|${issue.description}';
  }

  /// Every fingerprint present in [results], for writing a new baseline.
  static Set<String> fingerprintsFor(
    List<AuditRunResult> results,
    ProjectContext context,
  ) {
    final fingerprints = <String>{};

    for (final run in results) {
      for (final issue in run.result.issues) {
        fingerprints.add(fingerprintFor(run.audit.id, issue, context));
      }
    }

    return fingerprints;
  }

  /// Returns a copy of [results] with baselined issues handled by
  /// severity: medium/low/info baselined issues are removed entirely (like
  /// IgnoreConfig), but critical/high baselined issues stay visible in the
  /// report — a serious finding shouldn't silently vanish just because
  /// it's pre-existing. Their ids are returned in [exemptFromFailOn] so
  /// they don't block the build a second time; the caller is responsible
  /// for excluding them from its fail-on check.
  ///
  /// Maintenance findings (see [maintenanceAuditIds]) are always kept
  /// regardless of severity: they never affect the exit code in the first
  /// place, so there's nothing for the baseline to protect them from —
  /// hiding them would just make dependency/asset hygiene findings vanish
  /// silently the moment someone runs `--update-baseline`.
  ///
  /// [baselinedCount] counts every baselined issue, visible or not — it's
  /// "how many were accepted via baseline," not "how many disappeared."
  (
    List<AuditRunResult> filtered,
    int baselinedCount,
    Set<String> exemptFromFailOn,
  )
  apply(List<AuditRunResult> results, ProjectContext context) {
    if (isEmpty) {
      return (results, 0, {});
    }

    var baselined = 0;
    final exemptFromFailOn = <String>{};
    final filtered = <AuditRunResult>[];

    for (final run in results) {
      final keptIssues = <SecurityIssue>[];

      for (final issue in run.result.issues) {
        final isBaselined = fingerprints.contains(
          fingerprintFor(run.audit.id, issue, context),
        );

        if (!isBaselined) {
          keptIssues.add(issue);
          continue;
        }

        baselined++;

        final isHighSeverity =
            issue.severity == Severity.critical ||
            issue.severity == Severity.high;

        if (isHighSeverity || maintenanceAuditIds.contains(run.audit.id)) {
          keptIssues.add(issue);
        }

        if (isHighSeverity) {
          exemptFromFailOn.add(issue.id);
        }
      }

      filtered.add(
        AuditRunResult(
          audit: run.audit,
          result: AuditResult(issues: keptIssues),
        ),
      );
    }

    return (filtered, baselined, exemptFromFailOn);
  }
}
