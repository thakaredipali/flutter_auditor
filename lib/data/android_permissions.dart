import 'permission_info.dart';
import 'permission_risk.dart';

const highRiskPermissions = [
  PermissionInfo(
    permission: 'android.permission.READ_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Accesses the user\'s private text messages.',
    recommendation:
        'Use SMS Retriever API or SMS User Consent API for OTP verification.',
  ),
  PermissionInfo(
    permission: 'android.permission.SEND_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Can send SMS messages in the background.',
    recommendation:
        'Use Intent.ACTION_SENDTO to delegate sending to the default SMS app.',
  ),
  PermissionInfo(
    permission: 'android.permission.RECEIVE_SMS',
    risk: PermissionRisk.high,
    category: 'SMS',
    reason: 'Intercepts incoming SMS messages.',
    recommendation:
        'Use SMS Retriever API.',
  ),
];


const mediumRiskPermissions = [
  PermissionInfo(
    permission: 'android.permission.ACCESS_FINE_LOCATION',
    risk: PermissionRisk.medium,
    category: 'Location',
    reason: 'Accesses the user\'s precise location.',
    recommendation:
        'Use ACCESS_COARSE_LOCATION if precise location is not required.',
  ),
  PermissionInfo(
    permission: 'android.permission.ACCESS_COARSE_LOCATION',
    risk: PermissionRisk.medium,
    category: 'Location',
    reason: 'Accesses the user\'s approximate location.',
    recommendation:
        'Request location permissions only when necessary and provide clear justification.',
  ),
];


const lowRiskPermissions = [
  PermissionInfo(
    permission: 'android.permission.INTERNET',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to access the internet.',
    recommendation:
        'Ensure that network requests are made securely (e.g., using HTTPS).',
  ),
  PermissionInfo(
    permission: 'android.permission.ACCESS_NETWORK_STATE',
    risk: PermissionRisk.low,
    category: 'Network',
    reason: 'Allows the app to check network connectivity status.',
    recommendation:
        'Use this permission only if you need to check network state before making requests.',
  ),
];

const allAndroidPermissions = [
  ...highRiskPermissions,
  ...mediumRiskPermissions,
  ...lowRiskPermissions,
];