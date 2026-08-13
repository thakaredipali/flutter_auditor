import 'package:path/path.dart' as p;

import '../utils/path_utils.dart';
import 'audit_result.dart';
import 'audit_run_result.dart';
import 'project_context.dart';
import 'security_issue.dart';

/// Suppression rules loaded from a project's `.flutter_auditor_ignore.yaml`.
///
/// A finding is suppressed if it matches any rule: its producing audit's
/// [id][auditIds], its own [SecurityIssue.file] against a glob in
/// [filePatterns] (matched relative to the project root), or its own
/// [SecurityIssue.id] in [issueIds].
class IgnoreConfig {
  final Set<String> auditIds;
  final Set<String> issueIds;
  final List<String> filePatterns;

  const IgnoreConfig({
    this.auditIds = const {},
    this.issueIds = const {},
    this.filePatterns = const [],
  });

  bool get isEmpty =>
      auditIds.isEmpty && issueIds.isEmpty && filePatterns.isEmpty;

  /// Returns a copy of [results] with every suppressed issue removed, along
  /// with how many issues were suppressed in total. An audit whose findings
  /// are all suppressed is still reported (with an empty issue list), so it
  /// shows up as passed rather than silently disappearing.
  (List<AuditRunResult> filtered, int suppressedCount) apply(
    List<AuditRunResult> results,
    ProjectContext context,
  ) {
    if (isEmpty) {
      return (results, 0);
    }

    var suppressed = 0;
    final filtered = <AuditRunResult>[];

    for (final run in results) {
      final keptIssues = <SecurityIssue>[];

      for (final issue in run.result.issues) {
        if (_matches(run.audit.id, issue, context)) {
          suppressed++;
        } else {
          keptIssues.add(issue);
        }
      }

      filtered.add(
        AuditRunResult(
          audit: run.audit,
          result: AuditResult(issues: keptIssues),
        ),
      );
    }

    return (filtered, suppressed);
  }

  bool _matches(String auditId, SecurityIssue issue, ProjectContext context) {
    if (auditIds.contains(auditId)) {
      return true;
    }

    if (issueIds.contains(issue.id)) {
      return true;
    }

    final relativeFile = PathUtils.relativeToRoot(issue.file, context.rootPath);

    return filePatterns.any((pattern) => _matchesGlob(relativeFile, pattern));
  }

  bool _matchesGlob(String path, String pattern) {
    final normalizedPath = p.normalize(path);
    final normalizedPattern = p.normalize(pattern);

    final regexSource = RegExp.escape(
      normalizedPattern,
    ).replaceAll(r'\*\*', '.*').replaceAll(r'\*', '[^/]*');

    return RegExp('^$regexSource\$').hasMatch(normalizedPath);
  }
}
