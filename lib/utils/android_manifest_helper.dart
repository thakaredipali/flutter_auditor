import 'package:xml/xml.dart';

import '../models/project_context.dart';

class AndroidManifestHelper {
  const AndroidManifestHelper._();

  static Future<XmlDocument?> load(ProjectContext context) async {
    final manifest = context.androidManifest;

    if (!await manifest.exists()) {
      return null;
    }

    final content = await manifest.readAsString();

    try {
      return XmlDocument.parse(content);
    } catch (_) {
      return null;
    }
  }
}
