import 'dart:io';

import '../models/project_context.dart';

/// Shared helpers for audits that need to parse the Android app-level
/// build.gradle (Groovy or Kotlin DSL).
class GradleHelper {
  GradleHelper._();

  /// Returns the app-level build.gradle file, preferring the Groovy DSL
  /// (`build.gradle`) over the Kotlin DSL (`build.gradle.kts`) when both
  /// exist. Returns null if neither is present.
  static File? findAppBuildGradle(ProjectContext context) {
    if (context.androidAppBuildGradle.existsSync()) {
      return context.androidAppBuildGradle;
    }

    if (context.androidAppBuildGradleKts.existsSync()) {
      return context.androidAppBuildGradleKts;
    }

    return null;
  }

  /// Extracts the content between the first top-level `<blockName> {` and
  /// its matching closing brace, tracking nested braces so unrelated `{}`
  /// pairs inside the block (conditionals, nested blocks) don't truncate
  /// the match early. Returns null if the block isn't found.
  static String? extractBlock(String content, String blockName) {
    final startMatch = RegExp('$blockName\\s*\\{').firstMatch(content);

    if (startMatch == null) {
      return null;
    }

    var depth = 1;
    var i = startMatch.end;

    while (i < content.length && depth > 0) {
      if (content[i] == '{') {
        depth++;
      } else if (content[i] == '}') {
        depth--;
      }
      i++;
    }

    return content.substring(startMatch.end, depth == 0 ? i - 1 : i);
  }
}
