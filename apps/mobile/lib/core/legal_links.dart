import 'package:url_launcher/url_launcher.dart';

/// Public pages used by the website, the app, and the store listings.
class ObicLegal {
  static const terms = 'https://www.obicgp.com/terms.html';
  static const privacy = 'https://www.obicgp.com/privacy.html';

  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
