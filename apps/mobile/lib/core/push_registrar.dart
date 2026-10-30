// Made by Dr Ali
// Registers this phone for Apple or Firebase push.
// Every signed-in account, including employees and admins. Trial servers
// that do not have the route yet return 404; that is ignored.

import 'device_alerts.dart';
import '../features/auth/auth_controller.dart';

class PushRegistrar {
  PushRegistrar._();

  static Future<void> start(AuthController auth) {
    return DeviceAlerts.instance.start();
  }
}
