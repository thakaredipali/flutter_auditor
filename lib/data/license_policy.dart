/// pub.dev score tags carry the license as `license:<spdx-id-lowercased>`
/// (e.g. `license:mit`, `license:gpl-3.0`). This set lists strong-copyleft
/// identifiers that typically require legal review before bundling into a
/// closed-source or commercially distributed app.
const Set<String> restrictedLicenseIds = {
  'gpl-1.0',
  'gpl-2.0',
  'gpl-3.0',
  'agpl-3.0',
  'lgpl-2.1',
  'lgpl-3.0',
};
