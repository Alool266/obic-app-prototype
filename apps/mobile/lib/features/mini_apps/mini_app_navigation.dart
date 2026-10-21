// Made by Dr Ali
// Navigation lock for the mini-app WebView.
// The first-party site stays on its origin. A partner package stays under
// /v1/mini-apps/<id>/files/ on the API host. The public list never opens a
// raw external URL.

/// HTTPS page with a host and no embedded credentials.
Uri? approvedMiniAppUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty) return null;
  return uri;
}

final _packageIndex = RegExp(
  r'^/v1/mini-apps/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/files/index\.html$',
);

String hostedPackageIndexPath(String id) => '/v1/mini-apps/$id/files/index.html';

bool isHostedPackageStart(String id, String startUrl) {
  final path = hostedPackageIndexPath(id);
  final trimmed = startUrl.trim();
  if (trimmed == path) return _packageIndex.hasMatch(path);
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.userInfo.isNotEmpty) return false;
  if (uri.scheme.isNotEmpty && uri.scheme != 'https') return false;
  return uri.path == path && _packageIndex.hasMatch(path);
}

/// `/v1/mini-apps/<uuid>/files/` when [path] is inside a hosted package.
String? packageFilesPrefix(String path) {
  final match = RegExp(
    r'^/v1/mini-apps/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/files(?:/|$)',
  ).firstMatch(path);
  if (match == null) return null;
  return '/v1/mini-apps/${match.group(1)}/files/';
}

/// Main-frame and iframe navigations. Subresources (scripts, images) are not
/// navigations, so files inside the package still load.
bool miniAppNavigationAllowed({
  required Uri approved,
  required String target,
}) {
  final uri = Uri.tryParse(target);
  if (uri == null) return false;
  if (uri.scheme == 'about' && (uri.path.isEmpty || uri.path == 'blank')) {
    return true;
  }
  if (uri.scheme != 'https') return false;
  if (uri.userInfo.isNotEmpty) return false;
  if (uri.host != approved.host || uri.port != approved.port) return false;
  final prefix = packageFilesPrefix(approved.path);
  if (prefix == null) return true;
  final path = uri.path;
  return path == prefix.substring(0, prefix.length - 1) || path.startsWith(prefix);
}
