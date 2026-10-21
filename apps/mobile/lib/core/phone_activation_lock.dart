// Made by Dr Ali
// While a mainland number is still unverified, reads stay open and writes ask for activation.

class PhoneActivationRequired implements Exception {
  const PhoneActivationRequired();

  @override
  String toString() => 'PhoneActivationRequired';
}

class PhoneActivationLock {
  static bool Function()? needsActivation;
  static bool Function()? isStaff;
  static void Function()? ask;

  static bool block(String method, Uri url) {
    final verb = method.toUpperCase();
    if (verb == 'GET' || verb == 'HEAD') return false;
    // Opening a chat clears its notification. That is looking, not an action.
    if (url.path.contains('/v1/notifications')) return false;
    // Device token registration. Alerts stay on before activation.
    if (url.path.contains('/v1/push/')) return false;
    if (needsActivation?.call() != true) return false;
    // Staff still send chat (and the upload that a photo message needs).
    // Customers stay on activate-before-write.
    final path = url.path;
    if (isStaff?.call() == true &&
        (path.contains('/v1/chat/') || path.contains('/v1/uploads'))) {
      return false;
    }
    ask?.call();
    return true;
  }
}
