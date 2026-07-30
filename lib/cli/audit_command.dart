import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_auditor/audits/audit_registry.dart';
import 'package:flutter_auditor/engine/audit_engine.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/console_reporter.dart';
import 'package:flutter_auditor/reporter/html_reporter.dart';
import 'package:flutter_auditor/scanner/project_scanner.dart';
import 'package:flutter_auditor/utils/ignore_config_helper.dart';

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
      )
      ..addOption(
        'html',
        help: 'Write an HTML report (with charts) to this path.',
        valueHelp: 'audit_report.html',
      )
      ..addFlag(
        'open',
        help: 'Open the generated HTML report in the default browser.',
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
    final rawResults = await engine.run(context);

    final ignoreConfig = await IgnoreConfigHelper.load(context);
    final (results, suppressedCount) = ignoreConfig.apply(rawResults, context);

    if (suppressedCount > 0) {
      print(
        'ⓘ $suppressedCount finding(s) suppressed by .flutter_auditor_ignore.yaml',
      );
      print('');
    }

    final reporter = const ConsoleReporter();

    final verbose = argResults!.flag('verbose');
    final failOnArg = argResults!.option('fail-on')!;
    final failOn = failOnArg == 'none'
        ? null
        : Severity.values.firstWhere((severity) => severity.name == failOnArg);

    final exitCode = reporter.printReport(
      results,
      context: context,
      verbose: verbose,
      failOn: failOn,
    );

    final htmlPath = argResults!.option('html');
    if (htmlPath != null) {
      final htmlReporter = const HtmlReporter();
      final file = htmlReporter.writeReport(
        results,
        context: context,
        outputPath: htmlPath,
      );
      print('');
      print('📊 HTML report written to: ${file.path}');

      if (argResults!.flag('open')) {
        await _openInBrowser(file.path);
      }
    }

    return exitCode;
  }

  Future<void> _openInBrowser(String path) async {
    final String command;
    final List<String> args;
    if (Platform.isMacOS) {
      command = 'open';
      args = [path];
    } else if (Platform.isWindows) {
      command = 'cmd';
      args = ['/c', 'start', '', path];
    } else {
      command = 'xdg-open';
      args = [path];
    }

    try {
      await Process.run(command, args);
    } catch (_) {
      print('  (Could not auto-open the report; open it manually.)');
    }
  }
}
