import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_auditor/audits/audit_registry.dart';
import 'package:flutter_auditor/engine/audit_engine.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:flutter_auditor/reporter/console_reporter.dart';
import 'package:flutter_auditor/reporter/html_reporter.dart';
import 'package:flutter_auditor/reporter/json_reporter.dart';
import 'package:flutter_auditor/reporter/sarif_reporter.dart';
import 'package:flutter_auditor/scanner/project_scanner.dart';
import 'package:flutter_auditor/utils/baseline_helper.dart';
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
      )
      ..addOption(
        'json',
        help: 'Write a JSON report to this path.',
        valueHelp: 'audit_report.json',
      )
      ..addOption(
        'sarif',
        help:
            'Write a SARIF report to this path (consumed by GitHub code '
            'scanning and other SARIF tooling).',
        valueHelp: 'audit_report.sarif',
      )
      ..addFlag(
        'update-baseline',
        help:
            'Write current findings to .flutter_auditor_baseline.json as '
            'the accepted baseline, then exit. Future runs only fail on '
            'newly introduced findings.',
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
    final (afterIgnore, suppressedCount) = ignoreConfig.apply(
      rawResults,
      context,
    );

    if (suppressedCount > 0) {
      print(
        'ⓘ $suppressedCount finding(s) suppressed by .flutter_auditor_ignore.yaml',
      );
      print('');
    }

    if (argResults!.flag('update-baseline')) {
      await BaselineHelper.write(afterIgnore, context);
      final total = afterIgnore.fold<int>(
        0,
        (sum, run) => sum + run.result.issues.length,
      );
      print(
        '✅ Baseline written to ${context.baselineFile.path} '
        '($total finding(s) recorded).',
      );
      print('   Future runs will only fail on newly introduced findings.');
      return 0;
    }

    final baselineConfig = await BaselineHelper.load(context);
    final (results, baselinedCount, exemptFromFailOn) = baselineConfig.apply(
      afterIgnore,
      context,
    );

    if (baselinedCount > 0) {
      final visibleCount = exemptFromFailOn.length;
      print(
        'ⓘ $baselinedCount pre-existing finding(s) accepted via '
        '.flutter_auditor_baseline.json'
        '${visibleCount > 0 ? ' ($visibleCount critical/high still shown, non-blocking)' : ''}',
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
      exemptFromFailOn: exemptFromFailOn,
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

    final jsonPath = argResults!.option('json');
    if (jsonPath != null) {
      final jsonReporter = const JsonReporter();
      final file = jsonReporter.writeReport(
        results,
        context: context,
        outputPath: jsonPath,
      );
      print('');
      print('📄 JSON report written to: ${file.path}');
    }

    final sarifPath = argResults!.option('sarif');
    if (sarifPath != null) {
      final sarifReporter = const SarifReporter();
      final file = sarifReporter.writeReport(
        results,
        context: context,
        outputPath: sarifPath,
      );
      print('');
      print('📄 SARIF report written to: ${file.path}');
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
