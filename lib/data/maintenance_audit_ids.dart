/// [Audit.id]s whose findings are dependency-hygiene/maintenance concerns
/// rather than direct security risks. [ConsoleReporter] reports these in a
/// separate "Maintenance" bucket instead of the High/Medium/Low risk tiers,
/// and they never trigger a non-zero exit code.
const Set<String> maintenanceAuditIds = {
  'dependency_hygiene',
  'unused_dependency',
};
