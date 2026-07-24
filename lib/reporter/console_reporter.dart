import 'package:path/path.dart' as p;

import '../data/maintenance_audit_ids.dart';
import '../models/audit.dart';
import '../models/audit_run_result.dart';
import '../models/project_context.dart';
import '../models/security_issue.dart';
import '../models/severity.dart';

/// Prints a formatted security & dependency audit report to the console.
class ConsoleReporter {
  static const _divider =
      '──────────────────────────────────────────────────────────────────';
  static const _doubleDivider =
      '══════════════════════════════════════════════════════════════════';

  const ConsoleReporter();

  /// Prints the full report and returns the process exit code: 0 if no
  /// issue meets [failOn], 1 otherwise. Maintenance findings never affect
  /// the exit code. Pass `failOn: null` to always exit 0.
  int printReport(
    List<AuditRunResult> results, {
    required ProjectContext context,
    bool verbose = false,
    Severity? failOn = Severity.high,
  }) {
    final securityIssues = <SecurityIssue>[];
    final maintenanceIssues = <SecurityIssue>[];
    final passedAudits = <Audit>[];

    for (final run in results) {
      if (!run.result.hasIssues) {
        passedAudits.add(run.audit);
        continue;
      }

      if (maintenanceAuditIds.contains(run.audit.id)) {
        maintenanceIssues.addAll(run.result.issues);
      } else {
        securityIssues.addAll(run.result.issues);
      }
    }

    final highRisk = securityIssues
        .where(
          (issue) =>
              issue.severity == Severity.critical ||
              issue.severity == Severity.high,
        )
        .toList();
    final mediumRisk = securityIssues
        .where((issue) => issue.severity == Severity.medium)
        .toList();
    final lowRisk = securityIssues
        .where(
          (issue) =>
              issue.severity == Severity.low || issue.severity == Severity.info,
        )
        .toList();

    _printHeader(context);
    _printSummary(
      highRisk,
      mediumRisk,
      lowRisk,
      maintenanceIssues,
      passedAudits,
    );

    var itemNumber = 1;
    itemNumber = _printRiskSection('HIGH RISK', '✗', highRisk, itemNumber);
    itemNumber = _printRiskSection('MEDIUM RISK', '⚠', mediumRisk, itemNumber);

    _printLowRiskSection(lowRisk, verbose: verbose);
    _printMaintenanceSection(maintenanceIssues, verbose: verbose);
    _printPassedSection(passedAudits);

    final hasFailingIssue =
        failOn != null &&
        securityIssues.any(
          (issue) => issue.severity.isAtLeastAsSevereAs(failOn),
        );
    final exitCode = hasFailingIssue ? 1 : 0;

    _printFooter(
      highRisk.length,
      mediumRisk.length,
      lowRisk.length,
      maintenanceIssues.length,
      exitCode,
    );

    return exitCode;
  }

  void _printHeader(ProjectContext context) {
    final projectName = p.basename(context.rootPath);
    final scanned = <String>[
      if (context.androidDirectory.existsSync()) 'android/',
      if (context.iosDirectory.existsSync()) 'ios/',
      if (context.libDirectory.existsSync()) 'lib/',
      if (context.pubspec.existsSync()) 'pubspec.yaml',
    ].join(', ');
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    print('╔══════════════════════════════════════════════════════════════╗');
    print(
      '║              FLUTTER APP SECURITY & DEPENDENCY AUDIT            ║',
    );
    print('╚══════════════════════════════════════════════════════════════╝');
    print('');
    print('📁 Project   : $projectName');
    print('📄 Scanned   : $scanned');
    print('🕐 Date      : $date');
    print('');
  }

  void _printSummary(
    List<SecurityIssue> highRisk,
    List<SecurityIssue> mediumRisk,
    List<SecurityIssue> lowRisk,
    List<SecurityIssue> maintenanceIssues,
    List<Audit> passedAudits,
  ) {
    print(_divider);
    print(' SUMMARY');
    print(_divider);
    print('  ✗  High Risk        : ${highRisk.length}');
    print('  ⚠  Medium Risk       : ${mediumRisk.length}');
    print('  ⚠  Low Risk          : ${lowRisk.length}');
    print(
      '  ⓘ  Maintenance       : ${maintenanceIssues.length}   (outdated/unused deps, licenses)',
    );
    print('  ✔  Passed Checks     : ${passedAudits.length}');
    print('');
    print('  Overall Status: ${_overallStatus(highRisk, mediumRisk, lowRisk)}');
    print('');
  }

  String _overallStatus(
    List<SecurityIssue> highRisk,
    List<SecurityIssue> mediumRisk,
    List<SecurityIssue> lowRisk,
  ) {
    if (highRisk.isNotEmpty) {
      return '⚠️  ACTION REQUIRED (high-risk issues present)';
    }
    if (mediumRisk.isNotEmpty) {
      return '⚠️  REVIEW RECOMMENDED (medium-risk issues present)';
    }
    if (lowRisk.isNotEmpty) {
      return 'ℹ️  MINOR ISSUES (low-risk items present)';
    }
    return '✅ ALL CLEAR (no security issues found)';
  }

  int _printRiskSection(
    String title,
    String marker,
    List<SecurityIssue> issues,
    int startingNumber,
  ) {
    if (issues.isEmpty) {
      return startingNumber;
    }

    var itemNumber = startingNumber;

    print(_divider);
    print(' $marker $title (${issues.length})');
    print(_divider);
    print('');

    for (final issue in issues) {
      print('[$itemNumber] ${issue.title}');
      print(
        '    📍 ${issue.file}${issue.line != null ? ':${issue.line}' : ''}',
      );
      print('    ⚠️  ${issue.description}');
      print('    ✅ Fix: ${issue.recommendation}');
      print('');
      itemNumber++;
    }

    return itemNumber;
  }

  void _printLowRiskSection(
    List<SecurityIssue> issues, {
    required bool verbose,
  }) {
    if (issues.isEmpty) {
      return;
    }

    print(_divider);
    print(
      ' ⚠ LOW RISK (${issues.length}) — informational, collapsed by default',
    );
    print(_divider);

    if (verbose) {
      print('');
      for (final issue in issues) {
        _printDetailedItem(issue);
      }
    } else {
      print('  ℹ️  ${issues.length} low-risk item(s) found:');
      for (final issue in issues) {
        print('     • ${issue.title}');
      }
      print('');
      print('  Run with --verbose to see full detail.');
      print('');
    }
  }

  void _printMaintenanceSection(
    List<SecurityIssue> issues, {
    required bool verbose,
  }) {
    if (issues.isEmpty) {
      return;
    }

    print(_divider);
    print(' ⓘ MAINTENANCE (${issues.length}) — dependency hygiene, non-urgent');
    print(_divider);

    if (verbose) {
      print('');
      for (final issue in issues) {
        _printDetailedItem(issue);
      }
    } else {
      for (final issue in issues) {
        print('  ⓘ  ${issue.title}');
      }
      print('');
      print('  Run with --verbose for upgrade paths and changelog links.');
      print('');
    }
  }

  void _printDetailedItem(SecurityIssue issue) {
    print('  • ${issue.title}');
    print('    📍 ${issue.file}${issue.line != null ? ':${issue.line}' : ''}');
    print('    ⚠️  ${issue.description}');
    print('    ✅ Fix: ${issue.recommendation}');
    print('');
  }

  void _printPassedSection(List<Audit> passedAudits) {
    if (passedAudits.isEmpty) {
      return;
    }

    print(_divider);
    print(' ✔ PASSED (${passedAudits.length})');
    print(_divider);
    for (final audit in passedAudits) {
      print('  ✔ ${audit.name} — no issues found');
    }
    print('');
  }

  void _printFooter(
    int highCount,
    int mediumCount,
    int lowCount,
    int maintenanceCount,
    int exitCode,
  ) {
    print(_doubleDivider);
    print(
      '  Scan complete: $highCount high, $mediumCount medium, $lowCount low, '
      '$maintenanceCount maintenance item(s).',
    );
    print(
      '  Exit code: $exitCode'
      '${exitCode != 0 ? ' (high-risk issues present — see --fail-on to adjust)' : ''}',
    );
    print(_doubleDivider);
  }
}
