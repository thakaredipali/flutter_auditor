import 'permission_risk.dart';

class PermissionInfo {
  final String permission;
  final PermissionRisk risk;
  final String category;
  final String reason;
  final String recommendation;

  const PermissionInfo({
    required this.permission,
    required this.risk,
    required this.category,
    required this.reason,
    required this.recommendation,
  });
}