import 'permission_info.dart';
import 'permission_risk.dart';

// ============================================================
// HIGH RISK
// Permissions that typically require a Play Console Permissions
// Declaration, are frequently abused for fraud/malware, or can
// trigger Play Protect install blocks.
// ============================================================
const highRiskPermissions = [
  // ---------------- SMS ----------------
  PermissionInfo(
    permission: 'android.permission.READ_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Accesses the user\'s private text messages.',
    recommendation:
        'Use SMS Retriever API or SMS User Consent API for OTP verification instead. '
        'If a full messaging use case is required, app must be the default SMS/Assistant handler '
        'and submit a Play Console Permissions Declaration.',
  ),
  PermissionInfo(
    permission: 'android.permission.SEND_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Can send SMS messages, including silently in the background.',
    recommendation:
        'Use Intent.ACTION_SENDTO to delegate sending to the default SMS app. '
        'If silent sending is core to the app, requires default handler status + declaration.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECEIVE_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Intercepts incoming SMS messages.',
    recommendation:
        'Use SMS Retriever API or SMS User Consent API for OTP flows (no permission needed). '
        'Declaration + default handler status required for a full messaging app.',
  ),
  PermissionInfo(
    permission: 'android.permission.WRITE_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Modifies the SMS database.',
    recommendation:
        'Almost always removable — rarely a legitimate use case. '
        'If truly needed, requires default handler status + declaration.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECEIVE_MMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Intercepts incoming MMS messages.',
    recommendation:
        'No direct alternative. Requires default handler status + Play Console declaration.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECEIVE_WAP_PUSH',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Intercepts WAP push messages.',
    recommendation:
        'Rarely needed today. Remove unless building a carrier/messaging app; otherwise requires declaration.',
  ),

  // ---------------- Call Log / Telephony ----------------
  PermissionInfo(
    permission: 'android.permission.READ_CALL_LOG',
    risk: PermissionRisk.high,
    category: 'Call Log',
    reason: 'Reads the user\'s call history.',
    recommendation:
        'Offer manual number entry as a fallback instead. '
        'Must be default Phone/Assistant handler + declaration if retained.',
  ),
  PermissionInfo(
    permission: 'android.permission.WRITE_CALL_LOG',
    risk: PermissionRisk.high,
    category: 'Call Log',
    reason: 'Modifies the user\'s call history.',
    recommendation:
        'Remove unless building a dialer/call-management app. Requires declaration if kept.',
  ),
  PermissionInfo(
    permission: 'android.permission.PROCESS_OUTGOING_CALLS',
    risk: PermissionRisk.high,
    category: 'Call Log',
    reason: 'Can intercept and redirect outgoing calls. Deprecated on newer Android.',
    recommendation:
        'Migrate to CallRedirectionService (Android 10+). Otherwise requires declaration.',
  ),
  PermissionInfo(
    permission: 'android.permission.CALL_PHONE',
    risk: PermissionRisk.high,
    category: 'Telephony',
    reason: 'Places phone calls without user interaction or confirmation.',
    recommendation:
        'Use Intent.ACTION_DIAL or Intent.ACTION_CALL via the dialer UI instead, '
        'unless silent/auto-dialing is the core feature (then declaration required).',
  ),
  PermissionInfo(
    permission: 'android.permission.ANSWER_PHONE_CALLS',
    risk: PermissionRisk.high,
    category: 'Telephony',
    reason: 'Programmatically answers incoming calls.',
    recommendation:
        'Remove unless building a call-screening/call-management app. Requires declaration.',
  ),

  // ---------------- Location ----------------
  PermissionInfo(
    permission: 'android.permission.ACCESS_BACKGROUND_LOCATION',
    risk: PermissionRisk.high,
    category: 'Location',
    reason: 'Tracks the user\'s location even when the app is closed or not in use.',
    recommendation:
        'Use foreground-only location (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION) unless a core, '
        'user-beneficial background feature exists. Requires a Play Console declaration + demo video.',
  ),

  // ---------------- Storage / Files ----------------
  PermissionInfo(
    permission: 'android.permission.MANAGE_EXTERNAL_STORAGE',
    risk: PermissionRisk.high,
    category: 'Storage',
    reason: 'Grants broad, unrestricted access to shared storage ("All files access").',
    recommendation:
        'Use the Storage Access Framework or MediaStore API instead. '
        'Only keep for genuine file-manager/backup apps — requires declaration.',
  ),

  // ---------------- Package Visibility ----------------
  PermissionInfo(
    permission: 'android.permission.QUERY_ALL_PACKAGES',
    risk: PermissionRisk.high,
    category: 'Package Visibility',
    reason: 'Reveals the full list of installed apps on the device.',
    recommendation:
        'Declare specific packages/intents using a scoped <queries> block instead. '
        'Only keep broad access for launcher/antivirus-type apps — requires declaration.',
  ),

  // ---------------- Accessibility ----------------
  PermissionInfo(
    permission: 'android.permission.BIND_ACCESSIBILITY_SERVICE',
    risk: PermissionRisk.high,
    category: 'Accessibility',
    reason:
        'Grants full read/control access to the device UI. Frequently abused for financial fraud malware.',
    recommendation:
        'If a genuine accessibility tool, set isAccessibilityTool=true. Otherwise requires '
        'clear in-app disclosure, explicit user consent, and a Play Console declaration.',
  ),

  // ---------------- Overlay ----------------
  PermissionInfo(
    permission: 'android.permission.SYSTEM_ALERT_WINDOW',
    risk: PermissionRisk.high,
    category: 'Special Access',
    reason: 'Allows drawing over other apps (overlay UI).',
    recommendation:
        'Prefer in-app UI over system overlays where possible. If required, '
        'direct users to the system settings page for approval (special permission, not runtime-granted).',
  ),

  // ---------------- Device Admin ----------------
  PermissionInfo(
    permission: 'android.permission.BIND_DEVICE_ADMIN',
    risk: PermissionRisk.high,
    category: 'Device Admin',
    reason: 'Grants device admin control — device wipe, lock, and policy enforcement.',
    recommendation: 'Remove unless building an enterprise MDM/device-management app.',
  ),

  // ---------------- Notifications ----------------
  PermissionInfo(
    permission: 'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
    risk: PermissionRisk.high,
    category: 'Notifications',
    reason:
        'Reads all notifications posted by every app on the device. Frequently abused for fraud.',
    recommendation:
        'No real alternative exists. Requires a Play Console declaration with a strong core-functionality justification.',
  ),

  // ---------------- Install Packages ----------------
  PermissionInfo(
    permission: 'android.permission.REQUEST_INSTALL_PACKAGES',
    risk: PermissionRisk.high,
    category: 'Package Install',
    reason: 'Allows the app to trigger installation of other APK packages.',
    recommendation:
        'Use a Play Store deep link for updates/installs instead. '
        'Keep only for browser/file-manager/enterprise apps — requires declaration.',
  ),

  // ---------------- Body Sensors ----------------
  PermissionInfo(
    permission: 'android.permission.BODY_SENSORS',
    risk: PermissionRisk.high,
    category: 'Health',
    reason: 'Accesses body sensor data such as heart rate, SpO2, and skin temperature.',
    recommendation:
        'On Android 16+, migrate to granular permissions (e.g., android.permission.health.READ_HEART_RATE). '
        'Declaration required regardless of which variant is used.',
  ),
  PermissionInfo(
    permission: 'android.permission.BODY_SENSORS_BACKGROUND',
    risk: PermissionRisk.high,
    category: 'Health',
    reason: 'Accesses body sensor data while the app is in the background.',
    recommendation:
        'Only request if background monitoring is core to the app (e.g., workout tracking). '
        'Requires declaration; prefer granular health.* permissions on Android 16+.',
  ),

  // ---------------- VPN ----------------
  PermissionInfo(
    permission: 'android.permission.BIND_VPN_SERVICE',
    risk: PermissionRisk.high,
    category: 'Network',
    reason: 'Creates a device-level VPN tunnel with visibility into all network traffic.',
    recommendation:
        'Only keep for genuine VPN, parental-control, or device-security apps. '
        'Must encrypt device-to-tunnel traffic and be declared in the Play listing.',
  ),

  // ---------------- Accounts ----------------
  PermissionInfo(
    permission: 'android.permission.GET_ACCOUNTS',
    risk: PermissionRisk.high,
    category: 'Accounts',
    reason: 'Lists all accounts (e.g., emails) registered on the device.',
    recommendation:
        'Use Google Sign-In / OAuth-based sign-in flows instead. Usually fully removable.',
  ),
];

// ============================================================
// MEDIUM RISK
// Sensitive permissions with lighter review requirements, or
// restricted only if a lower-scope alternative isn't used.
// ============================================================
const mediumRiskPermissions = [
  PermissionInfo(
    permission: 'android.permission.ACCESS_FINE_LOCATION',
    risk: PermissionRisk.medium,
    category: 'Location',
    reason: 'Accesses the user\'s precise location.',
    recommendation:
        'Use ACCESS_COARSE_LOCATION if precise location is not required for the core feature.',
  ),
  PermissionInfo(
    permission: 'android.permission.ACCESS_COARSE_LOCATION',
    risk: PermissionRisk.medium,
    category: 'Location',
    reason: 'Accesses the user\'s approximate location.',
    recommendation: 'Request location only when necessary and provide clear in-app justification.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_MEDIA_IMAGES',
    risk: PermissionRisk.medium,
    category: 'Media',
    reason: 'Accesses all photos on the device.',
    recommendation:
        'Use the Android Photo Picker instead — it requires no permission and is privacy-preserving. '
        'Declaration required if this permission is kept.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_MEDIA_VIDEO',
    risk: PermissionRisk.medium,
    category: 'Media',
    reason: 'Accesses all videos on the device.',
    recommendation:
        'Use the Android Photo Picker instead. Declaration required if this permission is kept.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_MEDIA_AUDIO',
    risk: PermissionRisk.medium,
    category: 'Media',
    reason: 'Accesses all audio files on the device.',
    recommendation: 'Scope to app-specific media directories where possible.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_CONTACTS',
    risk: PermissionRisk.medium,
    category: 'Contacts',
    reason: 'Reads the user\'s full contact list.',
    recommendation:
        'Use the Android Contact Picker for single-contact selection instead of broad access. '
        'Broad access will require justification under Google\'s new Contacts Permissions policy (effective Oct 28, 2026).',
  ),
  PermissionInfo(
    permission: 'android.permission.WRITE_CONTACTS',
    risk: PermissionRisk.medium,
    category: 'Contacts',
    reason: 'Modifies the user\'s contact list.',
    recommendation: 'Only request if the app explicitly creates/edits contacts as a core feature.',
  ),
  PermissionInfo(
    permission: 'android.permission.CAMERA',
    risk: PermissionRisk.medium,
    category: 'Camera',
    reason: 'Accesses the device camera.',
    recommendation:
        'Request at time of use (runtime permission) with a clear in-context explanation.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECORD_AUDIO',
    risk: PermissionRisk.medium,
    category: 'Microphone',
    reason: 'Accesses the device microphone.',
    recommendation:
        'Request only when the recording feature is actively used; stop capture immediately after use.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_PHONE_STATE',
    risk: PermissionRisk.medium,
    category: 'Telephony',
    reason: 'Reads device identifiers and phone state (IMEI, call state, etc.).',
    recommendation:
        'Use Firebase Instance ID / Advertising ID / SDK-generated UUIDs instead of device identifiers where possible.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_PHONE_NUMBERS',
    risk: PermissionRisk.medium,
    category: 'Telephony',
    reason: 'Reads the device\'s phone number(s).',
    recommendation: 'Use SMS Retriever / phone number hint APIs for verification flows instead.',
  ),
  PermissionInfo(
    permission: 'android.permission.USE_EXACT_ALARM',
    risk: PermissionRisk.medium,
    category: 'Alarms',
    reason: 'Schedules precisely-timed alarms; auto-granted only for alarm/calendar apps.',
    recommendation:
        'Use SCHEDULE_EXACT_ALARM (user-granted) instead unless the app\'s core function is an alarm, timer, or calendar with event notifications.',
  ),
  PermissionInfo(
    permission: 'android.permission.USE_FULL_SCREEN_INTENT',
    risk: PermissionRisk.medium,
    category: 'Notifications',
    reason: 'Shows a full-screen notification, interrupting whatever the user is doing.',
    recommendation:
        'Auto-granted only for alarm apps or calling apps on Android 14+. Otherwise, request explicit user consent.',
  ),
  PermissionInfo(
    permission: 'android.permission.READ_EXTERNAL_STORAGE',
    risk: PermissionRisk.medium,
    category: 'Storage',
    reason: 'Reads files from shared/external storage.',
    recommendation:
        'On Android 13+, prefer scoped media permissions (READ_MEDIA_IMAGES/VIDEO/AUDIO) or the Storage Access Framework.',
  ),
  PermissionInfo(
    permission: 'android.permission.WRITE_EXTERNAL_STORAGE',
    risk: PermissionRisk.medium,
    category: 'Storage',
    reason: 'Writes files to shared/external storage.',
    recommendation:
        'Use app-specific storage or the MediaStore API instead; largely unnecessary on Android 10+ (scoped storage).',
  ),
  PermissionInfo(
    permission: 'android.permission.ACTIVITY_RECOGNITION',
    risk: PermissionRisk.medium,
    category: 'Sensors',
    reason: 'Detects the user\'s physical activity (walking, running, driving, etc.).',
    recommendation: 'Request only if activity-based features are core to the app (e.g., fitness tracking).',
  ),
  PermissionInfo(
    permission: 'android.permission.BLUETOOTH_CONNECT',
    risk: PermissionRisk.medium,
    category: 'Bluetooth',
    reason: 'Connects to already-paired Bluetooth devices.',
    recommendation: 'Request only when a Bluetooth-dependent feature is actively used.',
  ),
  PermissionInfo(
    permission: 'android.permission.BLUETOOTH_SCAN',
    risk: PermissionRisk.medium,
    category: 'Bluetooth',
    reason: 'Scans for nearby Bluetooth devices (can be used to infer location).',
    recommendation:
        'Add android:usesPermissionFlags="neverForLocation" if location derivation is not needed, to avoid also requiring location permissions.',
  ),
  PermissionInfo(
    permission: 'android.permission.NEARBY_WIFI_DEVICES',
    risk: PermissionRisk.medium,
    category: 'WiFi',
    reason: 'Discovers and connects to nearby WiFi devices.',
    recommendation: 'Request only when a WiFi-based discovery/connection feature is active.',
  ),
];

// ============================================================
// LOW RISK
// Common permissions, generally low review risk, but still
// worth logging for completeness and to confirm actual usage.
// ============================================================
const lowRiskPermissions = [
  PermissionInfo(
    permission: 'android.permission.INTERNET',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to access the internet.',
    recommendation: 'Ensure all network requests are made securely (e.g., using HTTPS).',
  ),
  PermissionInfo(
    permission: 'android.permission.ACCESS_NETWORK_STATE',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to check network connectivity status.',
    recommendation: 'Use only if you need to check network state before making requests.',
  ),
  PermissionInfo(
    permission: 'android.permission.ACCESS_WIFI_STATE',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to view information about WiFi network state.',
    recommendation: 'Low risk; confirm it is actually used before keeping it.',
  ),
  PermissionInfo(
    permission: 'android.permission.CHANGE_WIFI_STATE',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to change WiFi connectivity state.',
    recommendation: 'Remove if the app does not actively manage WiFi connections.',
  ),
  PermissionInfo(
    permission: 'android.permission.VIBRATE',
    risk: PermissionRisk.low,
    category: 'Device',
    reason: 'Allows the app to control the vibration motor.',
    recommendation: 'No action needed; standard low-risk permission.',
  ),
  PermissionInfo(
    permission: 'android.permission.WAKE_LOCK',
    risk: PermissionRisk.low,
    category: 'Device',
    reason: 'Prevents the device from sleeping.',
    recommendation: 'Ensure wake locks are released promptly to avoid battery drain complaints.',
  ),
  PermissionInfo(
    permission: 'android.permission.POST_NOTIFICATIONS',
    risk: PermissionRisk.low,
    category: 'Notifications',
    reason: 'Allows the app to post notifications (required at runtime on Android 13+).',
    recommendation: 'Request at a contextually relevant moment, not immediately on app launch.',
  ),
  PermissionInfo(
    permission: 'android.permission.SCHEDULE_EXACT_ALARM',
    risk: PermissionRisk.low,
    category: 'Alarms',
    reason: 'Schedules exact alarms; user-grantable, safer alternative to USE_EXACT_ALARM.',
    recommendation: 'Preferred over USE_EXACT_ALARM for non-alarm-core apps.',
  ),
  PermissionInfo(
    permission: 'android.permission.FOREGROUND_SERVICE',
    risk: PermissionRisk.low,
    category: 'Services',
    reason: 'Allows the app to run a foreground service.',
    recommendation: 'Ensure a persistent, user-visible notification accompanies the service per policy.',
  ),
  PermissionInfo(
    permission: 'android.permission.FOREGROUND_SERVICE_LOCATION',
    risk: PermissionRisk.low,
    category: 'Services',
    reason: 'Declares the type of foreground service as location-related.',
    recommendation: 'Must match an actual location-based foreground service use case.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECEIVE_BOOT_COMPLETED',
    risk: PermissionRisk.low,
    category: 'Device',
    reason: 'Allows the app to start automatically after device boot.',
    recommendation: 'Confirm this is needed — unnecessary auto-start impacts battery/startup time.',
  ),
];

const allAndroidPermissions = [
  ...highRiskPermissions,
  ...mediumRiskPermissions,
  ...lowRiskPermissions,
];