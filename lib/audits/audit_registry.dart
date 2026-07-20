import 'package:flutter_audit/audits/android/allow_backup_audit.dart';
import 'package:flutter_audit/audits/android/debuggable_audit.dart';

import '../models/audit.dart';

/// Provides all available security audits.
class AuditRegistry {
  const AuditRegistry();

  List<Audit> getAudits() {
    return [
      AllowBackupAudit(),
      DebuggableAudit(),
    ];
  }
}