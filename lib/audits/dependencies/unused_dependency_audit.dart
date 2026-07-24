import 'dart:io';

import '../../data/unused_dependency_ignore_list.dart';
import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/pub_lock_helper.dart';

/// Flags direct pub.dev dependencies declared in pubspec.yaml that no Dart
/// file in the project imports or exports. Unused dependencies add
/// unnecessary size to the app and bloat the dependency tree.
///
/// Purely local (no network needed): scans every .dart file in the project
/// for `import`/`export package:<name>/...` statements.
class UnusedDependencyAudit extends Audit {
  static final _packageImportPattern = RegExp(
    r'''(?:import|export)\s+["']package:([a-zA-Z0-9_]+)/''',
  );

  @override
  String get id => 'unused_dependency';

  @override
  String get name => 'Unused Dependency Audit';

  @override
  String get description =>
      'Checks for dependencies declared in pubspec.yaml that no Dart file in the project imports.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final issues = <SecurityIssue>[];

    final dependencies = await PubLockHelper.loadLockedDependencies(context);

    final candidates = dependencies
        .where((dependency) => dependency.isDirectMain && dependency.isHosted)
        .where(
          (dependency) => !unusedDependencyIgnoreList.contains(dependency.name),
        )
        .toList();

    if (candidates.isEmpty) {
      return AuditResult(issues: issues);
    }

    final importedPackages = await _collectImportedPackages(context);

    for (final dependency in candidates) {
      if (importedPackages.contains(dependency.name)) {
        continue;
      }

      issues.add(
        SecurityIssue(
          id: 'unused_dependency.${dependency.name}',
          title: 'Unused Dependency: ${dependency.name}',
          description:
              '${dependency.name} is listed in pubspec.yaml, but no Dart file in the project imports or exports it. Unused dependencies add unnecessary size to the app and bloat the dependency tree.',
          severity: Severity.low,
          file: context.pubspec.path,
          recommendation:
              'Remove ${dependency.name} from pubspec.yaml if it is genuinely unused, or add the missing import if it is still needed.',
        ),
      );
    }

    return AuditResult(issues: issues);
  }

  Future<Set<String>> _collectImportedPackages(ProjectContext context) async {
    final imported = <String>{};

    if (!context.rootDirectory.existsSync()) {
      return imported;
    }

    final sep = Platform.pathSeparator;

    final dartFiles = context.rootDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.contains('$sep.dart_tool$sep') &&
              !file.path.contains('${sep}build$sep'),
        );

    for (final file in dartFiles) {
      String content;
      try {
        content = await file.readAsString();
      } catch (_) {
        continue;
      }

      for (final match in _packageImportPattern.allMatches(content)) {
        final packageName = match.group(1);

        if (packageName != null) {
          imported.add(packageName);
        }
      }
    }

    return imported;
  }
}
