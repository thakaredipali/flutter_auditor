import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_auditor/cli/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = FlutterAuditorCommandRunner();

  try {
    exitCode = await runner.run(arguments) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64; // EX_USAGE
  } catch (e) {
    stderr.writeln(e);
    exitCode = 2;
  }
}
