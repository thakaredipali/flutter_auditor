import 'package:args/command_runner.dart';

import 'audit_command.dart';

/// The main command runner for Flutter Auditor.
class FlutterAuditorCommandRunner extends CommandRunner<int> {
  FlutterAuditorCommandRunner()
    : super(
        'flutter_auditor',
        'A CLI tool to audit Flutter projects for security issues.',
      ) {
    addCommand(AuditCommand());
  }
}
