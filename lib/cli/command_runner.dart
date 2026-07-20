import 'package:args/command_runner.dart';

import 'audit_command.dart';

/// The main command runner for Flutter Audit.
class FlutterAuditCommandRunner extends CommandRunner<int> {
  FlutterAuditCommandRunner()
      : super(
          'flutter_audit',
          'A CLI tool to audit Flutter projects for security issues.',
        ) {
    addCommand(AuditCommand());
  }
}