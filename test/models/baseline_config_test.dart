import 'package:flutter_auditor/models/audit.dart';
import 'package:flutter_auditor/models/audit_result.dart';
import 'package:flutter_auditor/models/audit_run_result.dart';
import 'package:flutter_auditor/models/baseline_config.dart';
import 'package:flutter_auditor/models/project_context.dart';
import 'package:flutter_auditor/models/security_issue.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

class _FakeAudit extends Audit {
  _FakeAudit(this.id);

  @override
  final String id;

  @override
  String get name => id;

  @override
  String get description => 'Fake audit for testing.';

  @override
  Future<AuditResult> run(ProjectContext context) async =>
      const AuditResult(issues: []);
}

SecurityIssue _issue({
  required String id,
  required String file,
  String description = 'Description',
  Severity severity = Severity.medium,
  int? line,
}) {
  return SecurityIssue(
    id: id,
    title: 'Title',
    description: description,
    severity: severity,
    file: file,
    line: line,
    recommendation: 'Fix it',
  );
}

void main() {
  group('BaselineConfig', () {
    late ProjectContext context;

    setUp(() async {
      context = await createProjectContextWithFiles(files: {});
    });

    test('an empty baseline filters nothing', () {
      const config = BaselineConfig();
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.one', file: '${context.rootPath}/lib/x.dart'),
            ],
          ),
        ),
      ];

      final (filtered, baselined, exempt) = config.apply(results, context);

      expect(baselined, 0);
      expect(exempt, isEmpty);
      expect(filtered[0].result.issues, hasLength(1));
    });

    test('fully hides a baselined medium-severity issue', () {
      final issue = _issue(
        id: 'a.one',
        file: '${context.rootPath}/lib/x.dart',
        severity: Severity.medium,
      );
      final fingerprint = BaselineConfig.fingerprintFor('a', issue, context);
      final config = BaselineConfig(fingerprints: {fingerprint});

      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(issues: [issue]),
        ),
      ];

      final (filtered, baselined, exempt) = config.apply(results, context);

      expect(baselined, 1);
      expect(exempt, isEmpty);
      expect(filtered[0].result.issues, isEmpty);
    });

    test('fully hides a baselined low-severity issue', () {
      final issue = _issue(
        id: 'a.one',
        file: '${context.rootPath}/lib/x.dart',
        severity: Severity.low,
      );
      final fingerprint = BaselineConfig.fingerprintFor('a', issue, context);
      final config = BaselineConfig(fingerprints: {fingerprint});

      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(issues: [issue]),
        ),
      ];

      final (filtered, baselined, exempt) = config.apply(results, context);

      expect(baselined, 1);
      expect(exempt, isEmpty);
      expect(filtered[0].result.issues, isEmpty);
    });

    test(
      'keeps a baselined high-severity issue visible but exempt from fail-on',
      () {
        final issue = _issue(
          id: 'a.one',
          file: '${context.rootPath}/lib/x.dart',
          severity: Severity.high,
        );
        final fingerprint = BaselineConfig.fingerprintFor('a', issue, context);
        final config = BaselineConfig(fingerprints: {fingerprint});

        final results = [
          AuditRunResult(
            audit: _FakeAudit('a'),
            result: AuditResult(issues: [issue]),
          ),
        ];

        final (filtered, baselined, exempt) = config.apply(results, context);

        expect(baselined, 1);
        expect(exempt, {'a.one'});
        expect(filtered[0].result.issues, hasLength(1));
      },
    );

    test(
      'keeps a baselined critical-severity issue visible but exempt from fail-on',
      () {
        final issue = _issue(
          id: 'a.one',
          file: '${context.rootPath}/lib/x.dart',
          severity: Severity.critical,
        );
        final fingerprint = BaselineConfig.fingerprintFor('a', issue, context);
        final config = BaselineConfig(fingerprints: {fingerprint});

        final results = [
          AuditRunResult(
            audit: _FakeAudit('a'),
            result: AuditResult(issues: [issue]),
          ),
        ];

        final (filtered, baselined, exempt) = config.apply(results, context);

        expect(baselined, 1);
        expect(exempt, {'a.one'});
        expect(filtered[0].result.issues, hasLength(1));
      },
    );

    test(
      'keeps a baselined maintenance finding visible despite low severity',
      () {
        final issue = _issue(
          id: 'unused_asset.one',
          file: '${context.rootPath}/lib/x.dart',
          severity: Severity.low,
        );
        final fingerprint = BaselineConfig.fingerprintFor(
          'unused_asset',
          issue,
          context,
        );
        final config = BaselineConfig(fingerprints: {fingerprint});

        final results = [
          AuditRunResult(
            audit: _FakeAudit('unused_asset'),
            result: AuditResult(issues: [issue]),
          ),
        ];

        final (filtered, baselined, exempt) = config.apply(results, context);

        expect(baselined, 1);
        expect(exempt, isEmpty);
        expect(filtered[0].result.issues, hasLength(1));
      },
    );

    test(
      'still matches after the line number shifts (unrelated edits above it)',
      () {
        final originalIssue = _issue(
          id: 'a.one',
          file: '${context.rootPath}/lib/x.dart',
          description: 'Hardcoded AWS Access Key ID found',
          line: 10,
        );
        final fingerprint = BaselineConfig.fingerprintFor(
          'a',
          originalIssue,
          context,
        );
        final config = BaselineConfig(fingerprints: {fingerprint});

        // Same audit/file/description, but the line shifted because code
        // was inserted above it in a later commit.
        final shiftedIssue = _issue(
          id: 'a.one',
          file: '${context.rootPath}/lib/x.dart',
          description: 'Hardcoded AWS Access Key ID found',
          line: 25,
        );
        final results = [
          AuditRunResult(
            audit: _FakeAudit('a'),
            result: AuditResult(issues: [shiftedIssue]),
          ),
        ];

        final (filtered, baselined, exempt) = config.apply(results, context);

        expect(baselined, 1);
        expect(exempt, isEmpty);
        expect(filtered[0].result.issues, isEmpty);
      },
    );

    test('does not match a different audit producing the same description', () {
      final issue = _issue(
        id: 'a.one',
        file: '${context.rootPath}/lib/x.dart',
        description: 'Same description',
      );
      final fingerprint = BaselineConfig.fingerprintFor('a', issue, context);
      final config = BaselineConfig(fingerprints: {fingerprint});

      final otherAuditIssue = _issue(
        id: 'b.one',
        file: '${context.rootPath}/lib/x.dart',
        description: 'Same description',
      );
      final results = [
        AuditRunResult(
          audit: _FakeAudit('b'),
          result: AuditResult(issues: [otherAuditIssue]),
        ),
      ];

      final (filtered, baselined, exempt) = config.apply(results, context);

      expect(baselined, 0);
      expect(exempt, isEmpty);
      expect(filtered[0].result.issues, hasLength(1));
    });

    test('fingerprintsFor collects one fingerprint per issue', () {
      final results = [
        AuditRunResult(
          audit: _FakeAudit('a'),
          result: AuditResult(
            issues: [
              _issue(id: 'a.one', file: '${context.rootPath}/lib/x.dart'),
              _issue(id: 'a.two', file: '${context.rootPath}/lib/y.dart'),
            ],
          ),
        ),
      ];

      final fingerprints = BaselineConfig.fingerprintsFor(results, context);

      expect(fingerprints, hasLength(2));
    });
  });
}
