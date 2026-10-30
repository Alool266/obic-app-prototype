// Made by Dr Ali
// Resolve relative /uploads/... URLs against the API host.

import 'api_config.dart';

String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  // Absolute URLs: rewrite stale localhost / old LAN hosts to current API origin
  // so chat/Moments photos keep working when the Mac hotspot IP changes.
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host;
    final isUploadish =
        uri.path.startsWith('/uploads/') || uri.port == 3001;
    final isStaleLocal = host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '0.0.0.0' ||
        host == '10.0.2.2' ||
        // Any RFC1918 / loopback host on :3001 (hotspot IP churn) → current API.
        (uri.port == 3001 && _isPrivateLanHost(host));
    if (isUploadish && isStaleLocal) {
      final origin = Uri.parse(kApiOrigin);
      return uri
          .replace(
            scheme: origin.scheme,
            host: origin.host,
            port: origin.hasPort ? origin.port : null,
          )
          .toString();
    }
    return url;
  }

  // Uploads live on the API origin (/uploads/...), never under /v1.
  final origin = kApiOrigin;
  if (url.startsWith('/')) return '$origin$url';
  return '$origin/$url';
}

bool _isPrivateLanHost(String host) {
  if (host.startsWith('192.168.')) return true;
  if (host.startsWith('10.')) return true;
  final m = RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').firstMatch(host);
  return m != null;
}

/// Strip /v1 so /uploads stays on the API origin root.
String get kApiOrigin {
  final base = kApiBaseUrl.replaceAll(RegExp(r'/$'), '');
  return base.replaceFirst(RegExp(r'/v1$'), '');
}
