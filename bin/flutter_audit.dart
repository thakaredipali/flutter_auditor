import 'package:flutter_audit/cli/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = FlutterAuditCommandRunner();

  try {
    await runner.run(arguments);
  } catch (e) {
    print(e);
  }
}