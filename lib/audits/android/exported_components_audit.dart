import 'package:xml/xml.dart';

import '../../models/audit.dart';
import '../../models/audit_result.dart';
import '../../models/project_context.dart';
import '../../models/security_issue.dart';
import '../../models/severity.dart';
import '../../utils/android_manifest_helper.dart';

class ExportedComponentsAudit extends Audit {
  @override
 String get id => 'android_exported_components';

  @override
  String get name => 'Exported Components';

  @override
  String get description =>
      'Checks for exported Android activities, services, receivers, and providers.';

  @override
  Future<AuditResult> run(ProjectContext context) async {
    final document = await AndroidManifestHelper.load(context);

    if (document == null) {
      return const AuditResult(issues: []);
    }

    final issues = <SecurityIssue>[];

    _checkComponents(
      document: document,
      tagName: 'activity',
      componentType: 'Activity',
      manifestPath: context.androidManifest.path,
      issues: issues,
    );

    _checkComponents(
      document: document,
      tagName: 'service',
      componentType: 'Service',
      manifestPath: context.androidManifest.path,
      issues: issues,
    );

    _checkComponents(
      document: document,
      tagName: 'receiver',
      componentType: 'Receiver',
      manifestPath: context.androidManifest.path,
      issues: issues,
    );

    _checkComponents(
      document: document,
      tagName: 'provider',
      componentType: 'Provider',
      manifestPath: context.androidManifest.path,
      issues: issues,
    );

    return AuditResult(issues: issues);
  }

  void _checkComponents({
    required XmlDocument document,
    required String tagName,
    required String componentType,
    required String manifestPath,
    required List<SecurityIssue> issues,
  }) {
    const androidNamespace = 'http://schemas.android.com/apk/res/android';

    final components = document.findAllElements(tagName);

    for (final component in components) {
      final exported = component.getAttribute(
        'exported',
        namespace: androidNamespace,
      );

      if (exported != 'true') {
        continue;
      }

      final componentName =
          component.getAttribute(
            'name',
            namespace: androidNamespace,
          ) ??
          'Unknown';

      issues.add(
        SecurityIssue(
          id: '${id}_${tagName}_$componentName',
          title: 'Exported $componentType',
          description:
              '$componentType "$componentName" is exported and may be accessible by other applications.',
          severity: Severity.high,
          file: manifestPath,
          recommendation:
              'Ensure this $componentType is exported only when required and protected with appropriate permissions.',
        ),
      );
    }
  }
}