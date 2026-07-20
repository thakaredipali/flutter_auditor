import '../models/audit_result.dart';

/// Prints audit results to the console.
class ConsoleReporter {
  const ConsoleReporter();

  void printReport(List<AuditResult> results) {
    var totalIssues = 0;

    for (final result in results) {
      if (!result.hasIssues) {
        print('✓ No issues found');
        continue;
      }

      for (final issue in result.issues) {
        totalIssues++;

        print('✗ ${issue.title}');
        print('  Severity : ${issue.severity.label}');
        print('  File     : ${issue.file}');
        print('  Fix      : ${issue.recommendation}');
        print('');
      }
    }

    print('──────────────────────────────');
    print('Total Issues: $totalIssues');
  }
}