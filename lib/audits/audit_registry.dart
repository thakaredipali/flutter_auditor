import 'package:flutter_auditor/audits/android/allow_backup_audit.dart';
import 'package:flutter_auditor/audits/android/backup_rules_audit.dart';
import 'package:flutter_auditor/audits/android/cleartext_traffic_audit.dart';
import 'package:flutter_auditor/audits/android/debuggable_audit.dart';
import 'package:flutter_auditor/audits/android/exported_components_audit.dart';
import 'package:flutter_auditor/audits/android/manifest_permission_audit.dart';
import 'package:flutter_auditor/audits/android/network_security_config_audit.dart';
import 'package:flutter_auditor/audits/android/release_signing_audit.dart';
import 'package:flutter_auditor/audits/assets/overlarge_asset_audit.dart';
import 'package:flutter_auditor/audits/assets/unused_asset_audit.dart';
import 'package:flutter_auditor/audits/build/obfuscation_audit.dart';
import 'package:flutter_auditor/audits/dependencies/dependency_hygiene_audit.dart';
import 'package:flutter_auditor/audits/dependencies/unused_dependency_audit.dart';
import 'package:flutter_auditor/audits/ios/app_transport_security_audit.dart';
import 'package:flutter_auditor/audits/ios/file_sharing_audit.dart';
import 'package:flutter_auditor/audits/ios/usage_description_audit.dart';
import 'package:flutter_auditor/audits/network/insecure_network_audit.dart';
import 'package:flutter_auditor/audits/secrets/hardcoded_secrets_audit.dart';
import 'package:flutter_auditor/audits/storage/insecure_storage_audit.dart';

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
      ReleaseSigningAudit(),
      ObfuscationAudit(),
      HardcodedSecretsAudit(),
      InsecureNetworkAudit(),
      InsecureStorageAudit(),
      AppTransportSecurityAudit(),
      FileSharingAudit(),
      UsageDescriptionAudit(),
      DependencyHygieneAudit(),
      UnusedDependencyAudit(),
      UnusedAssetAudit(),
      OverlargeAssetAudit(),
    ];
  }
}
