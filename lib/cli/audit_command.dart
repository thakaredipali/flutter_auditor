import 'package:args/command_runner.dart';
import 'package:flutter_audit/audits/audit_registry.dart';
import 'package:flutter_audit/engine/audit_engine.dart';
import 'package:flutter_audit/models/severity.dart';
import 'package:flutter_audit/reporter/console_reporter.dart';
import 'package:flutter_audit/scanner/project_scanner.dart';

/// Executes a Flutter security audit.
class AuditCommand extends Command<int> {
  AuditCommand() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show full detail for low-risk and maintenance findings.',
      )
      ..addOption(
        'fail-on',
        help: 'Minimum severity that causes a non-zero exit code.',
        allowed: ['critical', 'high', 'medium', 'low', 'info', 'none'],
        defaultsTo: 'high',
      );
  }

  @override
  String get name => 'audit';

  @override
  String get description => 'Audit a Flutter project for security issues.';

  @override
  Future<int> run() async {
    final scanner = ProjectScanner();
    final context = scanner.scan();

    if (context == null) {
      print('✗ Current directory is not a Flutter project.');
      return 1;
    }

    final registry = const AuditRegistry();
    final engine = AuditEngine(audits: registry.getAudits());
    final results = await engine.run(context);

    final reporter = const ConsoleReporter();

    final verbose = argResults!.flag('verbose');
    final failOnArg = argResults!.option('fail-on')!;
    final failOn = failOnArg == 'none'
        ? null
        : Severity.values.firstWhere((severity) => severity.name == failOnArg);

    return reporter.printReport(
      results,
      context: context,
      verbose: verbose,
      failOn: failOn,
    );
  }
}
