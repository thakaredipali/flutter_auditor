/// One of Apple's "required reason API" categories. Apps whose own code
/// calls an API in a category must declare it, with an approved reason,
/// in their PrivacyInfo.xcprivacy — otherwise App Store Connect rejects
/// the upload (ITMS-91053).
///
/// See https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
class RequiredReasonApi {
  /// The `NSPrivacyAccessedAPIType` value, e.g.
  /// `NSPrivacyAccessedAPICategoryUserDefaults`.
  final String category;

  /// Human-readable category name for reports.
  final String displayName;

  /// Matches a call site in Swift/Objective-C source.
  final RegExp pattern;

  /// Reason codes Apple accepts for this category.
  final Set<String> validReasons;

  const RequiredReasonApi({
    required this.category,
    required this.displayName,
    required this.pattern,
    required this.validReasons,
  });
}

/// Apple's required-reason API categories, checked by
/// [PrivacyManifestAudit].
final List<RequiredReasonApi> requiredReasonApis = [
  RequiredReasonApi(
    category: 'NSPrivacyAccessedAPICategoryFileTimestamp',
    displayName: 'File timestamp',
    pattern: RegExp(
      r'\bNSFile(?:Creation|Modification)Date\b'
      r'|\bfileModificationDate\b'
      r'|\b(?:contentModification|creation)DateKey\b'
      r'|\bf?getattrlist(?:bulk|at)?\s*\('
      r'|\b[fl]?stat(?:at)?\s*\(',
    ),
    validReasons: {'DDA9.1', 'C617.1', '3B52.1', '0A2A.1'},
  ),
  RequiredReasonApi(
    category: 'NSPrivacyAccessedAPICategorySystemBootTime',
    displayName: 'System boot time',
    pattern: RegExp(r'\bsystemUptime\b|\bmach_absolute_time\s*\('),
    validReasons: {'35F9.1', '8FFB.1', '3D61.1'},
  ),
  RequiredReasonApi(
    category: 'NSPrivacyAccessedAPICategoryDiskSpace',
    displayName: 'Disk space',
    pattern: RegExp(
      r'\bvolume(?:AvailableCapacity(?:ForImportantUsage|ForOpportunisticUsage)?|TotalCapacity)Key\b'
      r'|\bNSFileSystem(?:Free)?Size\b'
      r'|\bsystem(?:Free)?Size\b'
      r'|\bf?statv?fs\s*\(',
    ),
    validReasons: {'85F4.1', 'E174.1', '7D9E.1', 'B728.1'},
  ),
  RequiredReasonApi(
    category: 'NSPrivacyAccessedAPICategoryActiveKeyboards',
    displayName: 'Active keyboards',
    pattern: RegExp(r'\bactiveInputModes\b'),
    validReasons: {'3EC4.1', '54BD.1'},
  ),
  RequiredReasonApi(
    category: 'NSPrivacyAccessedAPICategoryUserDefaults',
    displayName: 'User defaults',
    pattern: RegExp(r'\b(?:NS)?UserDefaults\b'),
    validReasons: {'CA92.1', '1C8F.1', 'C56D.1', 'AC6B.1'},
  ),
];
