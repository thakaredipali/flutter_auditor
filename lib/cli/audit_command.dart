import 'package:args/command_runner.dart';
import 'package:flutter_audit/scanner/project_scanner.dart';
import 'package:flutter_audit/utils/constants.dart';

/// Executes a Flutter security audit.
class AuditCommand extends Command<int> {
  @override
  String get name => 'audit';

  @override
  String get description => 'Audit a Flutter project for security issues.';

@override
Future<int> run() async {
  print('${AppConstants.appName} v${AppConstants.version}');
  print('');

  final scanner = ProjectScanner();
  final context = scanner.scan();

  if (context == null) {
    print('✗ Current directory is not a Flutter project.');
    return 1;
  }

  print('✓ Flutter project detected.');
  print('');
  print('Starting security audit...');

  return 0;
}
}