import 'package:flutter_auditor/audits/ios/usage_description_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

void main() {
  group('UsageDescriptionAudit', () {
    late UsageDescriptionAudit audit;

    setUp(() {
      audit = UsageDescriptionAudit();
    });

    test('returns no issues when Info.plist is missing', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'returns no issues for a clean plist with no relevant dependencies',
      () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
''',
            'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSCameraUsageDescription</key>
	<string>We use the camera to scan documents.</string>
</dict>
</plist>
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      },
    );

    group('empty values (check 1)', () {
      test('detects an empty usage-description string', () async {
        final context = await createProjectContextWithFiles(
          files: {
            'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSCameraUsageDescription</key>
	<string></string>
</dict>
</plist>
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(
          result.issues.first.title,
          'Empty Usage Description: NSCameraUsageDescription',
        );
        expect(result.issues.first.severity, Severity.medium);
      });

      test('does not flag a non-empty usage-description string', () async {
        final context = await createProjectContextWithFiles(
          files: {
            'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSCameraUsageDescription</key>
	<string>We use the camera to scan documents.</string>
</dict>
</plist>
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      });
    });

    group('required pairings (check 3)', () {
      test(
        'detects NSLocationAlwaysAndWhenInUseUsageDescription without NSLocationWhenInUseUsageDescription',
        () async {
          final context = await createProjectContextWithFiles(
            files: {
              'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>We use your location in the background to track deliveries.</string>
</dict>
</plist>
''',
            },
          );

          final result = await audit.run(context);

          expect(result.issues.length, 1);
          expect(
            result.issues.first.title,
            'Missing Paired Usage Description: NSLocationWhenInUseUsageDescription',
          );
          expect(result.issues.first.severity, Severity.high);
        },
      );

      test('does not flag when both location keys are present', () async {
        final context = await createProjectContextWithFiles(
          files: {
            'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>We use your location in the background to track deliveries.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>We use your location to show nearby stores.</string>
</dict>
</plist>
''',
          },
        );

        final result = await audit.run(context);

        expect(result.issues, isEmpty);
      });
    });

    group('missing for used packages (check 2)', () {
      test('detects a missing key required by a pubspec dependency', () async {
        final context = await createProjectContextWithFiles(
          files: {
            'pubspec.yaml': '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.0
''',
            'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
</dict>
</plist>
''',
          },
        );

        final result = await audit.run(context);

        final titles = result.issues.map((issue) => issue.title).toList();
        expect(
          titles,
          containsAll([
            'Missing Usage Description: NSCameraUsageDescription',
            'Missing Usage Description: NSPhotoLibraryUsageDescription',
            'Missing Usage Description: NSPhotoLibraryAddUsageDescription',
          ]),
        );
        expect(
          result.issues
              .firstWhere((i) => i.title.contains('NSCameraUsageDescription'))
              .severity,
          Severity.high,
        );
      });

      test(
        'does not flag the Always location key just because geolocator is a dependency when only when-in-use is declared',
        () async {
          final context = await createProjectContextWithFiles(
            files: {
              'pubspec.yaml': '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
  geolocator: ^10.0.0
''',
              'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>We use your location to show nearby stores.</string>
</dict>
</plist>
''',
            },
          );

          final result = await audit.run(context);

          expect(result.issues, isEmpty);
        },
      );

      test(
        'does not flag a key required by a package that is not a dependency',
        () async {
          final context = await createProjectContextWithFiles(
            files: {
              'pubspec.yaml': '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
''',
              'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
</dict>
</plist>
''',
            },
          );

          final result = await audit.run(context);

          expect(result.issues, isEmpty);
        },
      );

      test(
        'does not double-report a key already flagged by the pairing check',
        () async {
          final context = await createProjectContextWithFiles(
            files: {
              'pubspec.yaml': '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
  geolocator: ^10.0.0
''',
              'ios/Runner/Info.plist': '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>We use your location in the background to track deliveries.</string>
</dict>
</plist>
''',
            },
          );

          final result = await audit.run(context);

          final locationIssues = result.issues
              .where(
                (issue) =>
                    issue.title.contains('NSLocationWhenInUseUsageDescription'),
              )
              .toList();

          expect(locationIssues.length, 1);
          expect(
            locationIssues.first.title,
            'Missing Paired Usage Description: NSLocationWhenInUseUsageDescription',
          );
        },
      );
    });
  });
}
