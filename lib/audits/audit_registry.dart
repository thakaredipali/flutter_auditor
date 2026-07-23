import 'package:flutter_audit/audits/android/allow_backup_audit.dart';
import 'package:flutter_audit/audits/android/backup_rules_audit.dart';
import 'package:flutter_audit/audits/android/cleartext_traffic_audit.dart';
import 'package:flutter_audit/audits/android/debuggable_audit.dart';
import 'package:flutter_audit/audits/android/exported_components_audit.dart';
import 'package:flutter_audit/audits/android/manifest_permission_audit.dart';
import 'package:flutter_audit/audits/android/network_security_config_audit.dart';
import 'package:flutter_audit/audits/ios/app_transport_security_audit.dart';
import 'package:flutter_audit/audits/ios/file_sharing_audit.dart';
import 'package:flutter_audit/audits/ios/usage_description_audit.dart';
import 'package:flutter_audit/audits/network/insecure_network_audit.dart';
import 'package:flutter_audit/audits/secrets/hardcoded_secrets_audit.dart';
import 'package:flutter_audit/audits/storage/insecure_storage_audit.dart';

import '../models/audit.dart';

/// Provides all available security audits.
class AuditRegistry {
  const AuditRegistry();

  List<Audit> getAudits() {
    return [
      AllowBackupAudit(),
      CleartextTrafficAudit(),
      ExportedComponentsAudit(),
      DebuggableAudit(),
      ManifestPermissionAudit(),
      NetworkSecurityConfigAudit(),
      BackupRulesAudit(),
      HardcodedSecretsAudit(),
      InsecureNetworkAudit(),
      InsecureStorageAudit(),
      AppTransportSecurityAudit(),
      FileSharingAudit(),
      UsageDescriptionAudit(),
    ];
  }
}
