import 'dart:io';

import 'package:flutter_auditor/audits/audit_registry.dart';
import 'package:flutter_auditor/engine/audit_engine.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/reporter/console_reporter.dart';

/// Runs every registered audit against the Flutter project in the current
/// working directory and prints a console report.
///
/// Run from the root of a Flutter project:
///
/// ```
/// dart run flutter_auditor:flutter_auditor_example
/// ```
Future<void> main() async {
  final context = ProjectContext(rootDirectory: Directory.current);

  const registry = AuditRegistry();
  final engine = AuditEngine(audits: registry.getAudits());
  final results = await engine.run(context);

  const ConsoleReporter().printReport(results, context: context);
}
