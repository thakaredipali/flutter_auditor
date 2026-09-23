import 'package:flutter_auditor/audits/ios/privacy_manifest_audit.dart';
import 'package:flutter_auditor/models/severity.dart';
import 'package:test/test.dart';

import '../../helpers/test_helper.dart';

const _manifestPath = 'ios/Runner/PrivacyInfo.xcprivacy';
const _xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
const _appDelegatePath = 'ios/Runner/AppDelegate.swift';

const _bundledProject = '''
/* Begin PBXFileReference section */
    97C147001CF9000F007C117D /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; path = PrivacyInfo.xcprivacy; };
''';

const _defaultAppDelegate = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
''';

const _userDefaultsAppDelegate = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UserDefaults in a comment must not count.
    UserDefaults.standard.set(true, forKey: "launched")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
''';

String _manifest(String body) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
$body
</dict>
</plist>
''';

String _accessedApi(String category, List<String> reasons) =>
    '''
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>$category</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
${reasons.map((r) => '				<string>$r</string>').join('\n')}
			</array>
		</dict>
	</array>
''';

void main() {
  group('PrivacyManifestAudit', () {
    late PrivacyManifestAudit audit;

    setUp(() {
      audit = PrivacyManifestAudit();
    });

    test('returns no issues for a project without iOS', () async {
      final context = await createProjectContextWithFiles(files: {});

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test(
      'suggests a manifest (info only) when none exists and no APIs are used',
      () async {
        final context = await createProjectContextWithFiles(
          files: {_appDelegatePath: _defaultAppDelegate},
        );

        final result = await audit.run(context);

        expect(result.issues.length, 1);
        expect(result.issues.first.id, 'ios.privacy_manifest.missing');
        expect(result.issues.first.severity, Severity.info);
      },
    );

    test('flags a required-reason API used with no manifest', () async {
      final context = await createProjectContextWithFiles(
        files: {_appDelegatePath: _userDefaultsAppDelegate},
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      final issue = result.issues.first;
      expect(
        issue.id,
        'ios.privacy_manifest.undeclared_api.'
        'NSPrivacyAccessedAPICategoryUserDefaults',
      );
      expect(issue.severity, Severity.medium);
      expect(issue.line, 11);
      expect(issue.description, contains('no privacy manifest'));
    });

    test('flags an API used but not declared in the manifest', () async {
      final context = await createProjectContextWithFiles(
        files: {
          'ios/Runner/DiskHelper.m': '''
#import <Foundation/Foundation.h>

NSNumber *freeSpace(void) {
  NSDictionary *attrs = [[NSFileManager defaultManager]
      attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
  return attrs[NSFileSystemFreeSize];
}
''',
          _manifestPath: _manifest(
            _accessedApi('NSPrivacyAccessedAPICategoryUserDefaults', [
              'CA92.1',
            ]),
          ),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'ios.privacy_manifest.undeclared_api.'
        'NSPrivacyAccessedAPICategoryDiskSpace',
      );
      expect(result.issues.first.line, 6);
    });

    test('returns no issues when every used API is declared', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _appDelegatePath: _userDefaultsAppDelegate,
          _manifestPath: _manifest(
            _accessedApi('NSPrivacyAccessedAPICategoryUserDefaults', [
              'CA92.1',
            ]),
          ),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('flags unrecognized reason codes', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: _manifest(
            _accessedApi('NSPrivacyAccessedAPICategoryUserDefaults', [
              'CA92.1',
              'XXXX.1',
            ]),
          ),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        startsWith('ios.privacy_manifest.invalid_reason'),
      );
      expect(result.issues.first.description, contains('XXXX.1'));
      expect(result.issues.first.description, isNot(contains('CA92.1')));
    });

    test('flags a declared category with no reasons', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: _manifest(
            _accessedApi('NSPrivacyAccessedAPICategoryDiskSpace', []),
          ),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.description, contains('without any reason'));
    });

    test('flags a manifest missing from the Xcode project', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: _manifest(''),
          _xcodeProjectPath: '/* Begin PBXFileReference section */',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.id, 'ios.privacy_manifest.not_bundled');
      expect(result.issues.first.severity, Severity.medium);
    });

    test('flags an unparseable manifest', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: '<plist><dict>',
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(result.issues.first.id, 'ios.privacy_manifest.parse_error');
    });

    test('flags tracking enabled without tracking domains', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: _manifest('''
	<key>NSPrivacyTracking</key>
	<true/>
'''),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues.length, 1);
      expect(
        result.issues.first.id,
        'ios.privacy_manifest.tracking_domains_missing',
      );
    });

    test('accepts tracking with declared tracking domains', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _manifestPath: _manifest('''
	<key>NSPrivacyTracking</key>
	<true/>
	<key>NSPrivacyTrackingDomains</key>
	<array>
		<string>tracker.example.com</string>
	</array>
'''),
          _xcodeProjectPath: _bundledProject,
        },
      );

      final result = await audit.run(context);

      expect(result.issues, isEmpty);
    });

    test('ignores similarly named identifiers', () async {
      final context = await createProjectContextWithFiles(
        files: {
          _appDelegatePath: '''
let state = computeState()
let status = statusBar()
let mySystemSizeLabel = "x"
''',
        },
      );

      final result = await audit.run(context);

      expect(result.issues.map((i) => i.id), ['ios.privacy_manifest.missing']);
    });
  });
}
