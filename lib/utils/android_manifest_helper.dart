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

    return XmlDocument.parse(content);
  }
}