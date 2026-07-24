import 'dart:convert';
import 'dart:io';

/// Thin wrapper around the pub.dev package API. Kept as a small,
/// overridable class (rather than free functions) so audits can be tested
/// against a fake implementation instead of hitting the network.
class PubDevClient {
  static const _timeout = Duration(seconds: 10);

  /// `GET https://pub.dev/api/packages/<name>` — returns the latest
  /// published version and its pubspec, or null if the package isn't
  /// found or the request fails.
  Future<Map<String, dynamic>?> fetchPackageInfo(String name) {
    return _getJson('https://pub.dev/api/packages/$name');
  }

  /// `GET https://pub.dev/api/packages/<name>/metrics` — returns pub.dev's
  /// score tags, including `is:discontinued`, `is:null-safe`, and
  /// `license:<spdx-id>`, or null if unavailable.
  Future<Map<String, dynamic>?> fetchMetrics(String name) {
    return _getJson('https://pub.dev/api/packages/$name/metrics');
  }

  Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
