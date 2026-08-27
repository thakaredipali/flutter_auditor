import 'dart:async';
import 'dart:io';

/// A terminal spinner shown while a long-running operation (e.g. running
/// all audits, some of which hit the network) is in progress.
///
/// Falls back to a single printed line when stdout isn't a terminal (piped
/// output, CI logs) instead of spamming carriage-return control characters.
class Spinner {
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  final String message;
  Timer? _timer;
  int _frameIndex = 0;

  Spinner(this.message);

  void start() {
    if (!stdout.hasTerminal) {
      print(message);
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      stdout.write('\r${_frames[_frameIndex % _frames.length]} $message');
      _frameIndex++;
    });
  }

  /// Stops the spinner and clears its line, leaving nothing behind for the
  /// next print to overwrite.
  void stop() {
    final timer = _timer;
    _timer = null;

    if (timer == null) {
      return;
    }

    timer.cancel();
    stdout.write('\r${' ' * (message.length + 2)}\r');
  }
}
