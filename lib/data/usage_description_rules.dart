import 'usage_description_rule.dart';

/// Known iOS Info.plist usage-description keys checked by
/// [UsageDescriptionAudit], along with the common Flutter packages that
/// require them and any Apple-mandated key pairings.
final List<UsageDescriptionRule> usageDescriptionRules = [
  UsageDescriptionRule(
    key: 'NSCameraUsageDescription',
    capability: 'Camera',
    requiredByPackages: [
      'camera',
      'image_picker',
      'mobile_scanner',
      'qr_code_scanner',
      'flutter_barcode_scanner',
      'simple_barcode_scanner',
      'camerawesome',
      'flutter_qr_reader',
    ],
    recommendation:
        'Add NSCameraUsageDescription to Info.plist with a clear explanation of why the app needs camera access.',
  ),
  UsageDescriptionRule(
    key: 'NSMicrophoneUsageDescription',
    capability: 'Microphone',
    requiredByPackages: [
      'camera',
      'record',
      'speech_to_text',
      'flutter_sound',
      'flutter_webrtc',
      'agora_rtc_engine',
      'noise_meter',
      'audio_session',
    ],
    recommendation:
        'Add NSMicrophoneUsageDescription to Info.plist with a clear explanation of why the app needs microphone access.',
  ),
  UsageDescriptionRule(
    key: 'NSPhotoLibraryUsageDescription',
    capability: 'Photo Library (Read)',
    requiredByPackages: [
      'image_picker',
      'photo_manager',
      'gallery_saver',
      'image_gallery_saver',
      'wechat_assets_picker',
      'multi_image_picker2',
      'photo_gallery',
    ],
    recommendation:
        'Add NSPhotoLibraryUsageDescription to Info.plist with a clear explanation of why the app needs photo library access.',
  ),
  UsageDescriptionRule(
    key: 'NSPhotoLibraryAddUsageDescription',
    capability: 'Photo Library (Add)',
    requiredByPackages: [
      'image_picker',
      'gallery_saver',
      'image_gallery_saver',
      'saver_gallery',
      'image_downloader',
    ],
    recommendation:
        'Add NSPhotoLibraryAddUsageDescription to Info.plist with a clear explanation of why the app needs to save photos.',
  ),
  UsageDescriptionRule(
    key: 'NSLocationWhenInUseUsageDescription',
    capability: 'Location (When In Use)',
    requiredByPackages: [
      'geolocator',
      'location',
      'google_maps_flutter',
      'flutter_background_geolocation',
      'background_locator_2',
      'mapbox_gl',
      'yandex_mapkit',
    ],
    recommendation:
        'Add NSLocationWhenInUseUsageDescription to Info.plist with a clear explanation of why the app needs location access.',
  ),
  UsageDescriptionRule(
    key: 'NSLocationAlwaysAndWhenInUseUsageDescription',
    capability: 'Location (Always)',
    // No requiredByPackages: geolocator/location are used for ordinary
    // when-in-use location in most apps, and pubspec.yaml alone can't tell
    // whether an app actually requests background ("always") location.
    // Only flag this key via the pairing check below, which fires solely
    // when the app has explicitly added the Always key itself.
    requiresAlsoPresent: ['NSLocationWhenInUseUsageDescription'],
    recommendation:
        'Add NSLocationAlwaysAndWhenInUseUsageDescription to Info.plist with a clear explanation of why the app needs background location access.',
  ),
  UsageDescriptionRule(
    key: 'NSContactsUsageDescription',
    capability: 'Contacts',
    requiredByPackages: [
      'contacts_service',
      'flutter_contacts',
      'fast_contacts',
    ],
    recommendation:
        'Add NSContactsUsageDescription to Info.plist with a clear explanation of why the app needs contacts access.',
  ),
  UsageDescriptionRule(
    key: 'NSBluetoothAlwaysUsageDescription',
    capability: 'Bluetooth',
    requiredByPackages: [
      'flutter_blue',
      'flutter_blue_plus',
      'flutter_reactive_ble',
      'flutter_bluetooth_serial',
      'flutter_ble_lib',
      'universal_ble',
    ],
    recommendation:
        'Add NSBluetoothAlwaysUsageDescription to Info.plist with a clear explanation of why the app needs Bluetooth access.',
  ),
  UsageDescriptionRule(
    key: 'NSFaceIDUsageDescription',
    capability: 'Face ID',
    requiredByPackages: ['local_auth'],
    recommendation:
        'Add NSFaceIDUsageDescription to Info.plist with a clear explanation of why the app uses Face ID.',
  ),
  UsageDescriptionRule(
    key: 'NSSpeechRecognitionUsageDescription',
    capability: 'Speech Recognition',
    requiredByPackages: ['speech_to_text'],
    recommendation:
        'Add NSSpeechRecognitionUsageDescription to Info.plist with a clear explanation of why the app needs speech recognition.',
  ),
  UsageDescriptionRule(
    key: 'NSCalendarsUsageDescription',
    capability: 'Calendar',
    requiredByPackages: ['device_calendar', 'add_2_calendar'],
    recommendation:
        'Add NSCalendarsUsageDescription to Info.plist with a clear explanation of why the app needs calendar access.',
  ),
  UsageDescriptionRule(
    key: 'NSRemindersUsageDescription',
    capability: 'Reminders',
    requiredByPackages: ['device_calendar'],
    recommendation:
        'Add NSRemindersUsageDescription to Info.plist with a clear explanation of why the app needs reminders access.',
  ),
  UsageDescriptionRule(
    key: 'NSMotionUsageDescription',
    capability: 'Motion & Fitness',
    requiredByPackages: [
      'sensors_plus',
      'pedometer',
      'flutter_compass',
      'motion_sensors',
    ],
    recommendation:
        'Add NSMotionUsageDescription to Info.plist with a clear explanation of why the app needs motion/fitness data.',
  ),
  UsageDescriptionRule(
    key: 'NSHealthShareUsageDescription',
    capability: 'Health (Read)',
    requiredByPackages: ['health'],
    recommendation:
        'Add NSHealthShareUsageDescription to Info.plist with a clear explanation of why the app needs to read Health data.',
  ),
  UsageDescriptionRule(
    key: 'NSHealthUpdateUsageDescription',
    capability: 'Health (Write)',
    requiredByPackages: ['health'],
    recommendation:
        'Add NSHealthUpdateUsageDescription to Info.plist with a clear explanation of why the app needs to write Health data.',
  ),
  UsageDescriptionRule(
    key: 'NSUserTrackingUsageDescription',
    capability: 'App Tracking Transparency',
    requiredByPackages: [
      'app_tracking_transparency',
      'facebook_app_events',
      'flutter_facebook_auth',
      'google_mobile_ads',
      'adjust_sdk',
      'appsflyer_sdk',
    ],
    recommendation:
        'Add NSUserTrackingUsageDescription to Info.plist with a clear explanation of why the app tracks the user across apps and websites.',
  ),
  UsageDescriptionRule(
    key: 'NSLocalNetworkUsageDescription',
    capability: 'Local Network',
    requiredByPackages: [
      'multicast_dns',
      'bonsoir',
      'network_info_plus',
      'flutter_nearby_connections',
    ],
    recommendation:
        'Add NSLocalNetworkUsageDescription to Info.plist with a clear explanation of why the app needs to discover devices on the local network.',
  ),
];
