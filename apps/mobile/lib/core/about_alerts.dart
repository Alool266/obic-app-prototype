// Made by Dr Ali
// Local banners on this phone so someone can see what OBIC is.
// Not sent through the API, and not delivered to any other user.
//
// Turn the test off by setting this to false.
import 'package:flutter/services.dart';

const bool kObicAboutAlertsEnabled = false;

const String kObicAboutAlertTitle = 'OBIC';

const List<String> kObicAboutAlertBodies = <String>[
  'OBIC is the services app.',
  'Chat and calls stay inside the app.',
  'Hotels and flights stay inside OBIC.',
  'A customer request goes to the secretary.',
  'A message shows the sender name.',
];

class AboutAlerts {
  AboutAlerts._();

  static const _channel = MethodChannel('obic/push');

  static Future<void> start() async {
    try {
      if (!kObicAboutAlertsEnabled) {
        await _channel.invokeMethod<void>('cancelAbout');
        return;
      }
      await _channel.invokeMethod<void>('scheduleAbout', <String, Object>{
        'title': kObicAboutAlertTitle,
        'bodies': kObicAboutAlertBodies,
        'intervalSeconds': 600,
      });
    } catch (_) {}
  }
}
