import 'package:flutter_auditor/cli/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = FlutterAuditorCommandRunner();

  try {
    await runner.run(arguments);
  } catch (e) {
    print(e);
  }
}
