import 'package:xml/xml.dart';

import '../models/project_context.dart';

/// Parses an Info.plist (Apple property list XML) into a plain Dart map.
class InfoPlistHelper {
  const InfoPlistHelper._();

  static Future<Map<String, dynamic>?> load(ProjectContext context) async {
    final plist = context.iosInfoPlist;

    if (!await plist.exists()) {
      return null;
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(await plist.readAsString());
    } catch (_) {
      return null;
    }

    final rootDict = document.rootElement.getElement('dict');

    if (rootDict == null) {
      return null;
    }

    return _parseDict(rootDict);
  }

  static Map<String, dynamic> _parseDict(XmlElement dictElement) {
    final result = <String, dynamic>{};
    final children = dictElement.childElements.toList();

    var i = 0;
    while (i < children.length) {
      final node = children[i];

      if (node.name.local != 'key' || i + 1 >= children.length) {
        i++;
        continue;
      }

      result[node.innerText] = _parseValue(children[i + 1]);
      i += 2;
    }

    return result;
  }

  static dynamic _parseValue(XmlElement node) {
    switch (node.name.local) {
      case 'true':
        return true;
      case 'false':
        return false;
      case 'integer':
        return int.tryParse(node.innerText);
      case 'real':
        return double.tryParse(node.innerText);
      case 'dict':
        return _parseDict(node);
      case 'array':
        return node.childElements.map(_parseValue).toList();
      case 'string':
      default:
        return node.innerText;
    }
  }
}
