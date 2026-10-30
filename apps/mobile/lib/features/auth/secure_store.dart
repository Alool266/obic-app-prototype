// Made by Dr Ali
// Shared Keychain / Keystore access for session tokens and the account vault.

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// iOS options for every OBIC secret.
///
/// `synchronizable: false` keeps tokens off iCloud. Accessibility is
/// after-first-unlock so a background refresh can read them. That attribute
/// is not part of the keychain primary key: an older item stored as
/// "when unlocked" still occupies the same account, and SecItemAdd then
/// returns errSecDuplicateItem (-25299) because the lookup query does not
/// see it.
const IOSOptions kObicIosSecureOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false,
);

const AndroidOptions kObicAndroidSecureOptions = AndroidOptions(
  // resetOnError:false — default true wipes tokens on a transient Keystore blip.
  resetOnError: false,
  migrateWithBackup: true,
);

class ObicSecureStore {
  ObicSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: kObicAndroidSecureOptions,
              iOptions: kObicIosSecureOptions,
            );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) {
    return _storage.read(
      key: key,
      iOptions: kObicIosSecureOptions,
      aOptions: kObicAndroidSecureOptions,
    );
  }

  Future<void> delete(String key) {
    return _storage.delete(
      key: key,
      iOptions: kObicIosSecureOptions,
      aOptions: kObicAndroidSecureOptions,
    );
  }

  /// Insert or replace one item. On iOS -25299, delete that key only and
  /// write again. Does not clear the rest of the keychain.
  Future<void> write(String key, String value) async {
    try {
      await _write(key, value);
    } on PlatformException catch (e) {
      if (!_isDuplicateKeychainItem(e)) rethrow;
      await delete(key);
      await _write(key, value);
    }
  }

  Future<void> _write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      iOptions: kObicIosSecureOptions,
      aOptions: kObicAndroidSecureOptions,
    );
  }
}

bool _isDuplicateKeychainItem(PlatformException e) {
  final details = e.details;
  if (details == -25299 || details == '-25299') return true;
  final blob = '${e.code} ${e.message} $details'.toLowerCase();
  return blob.contains('-25299') ||
      blob.contains('errsecduplicateitem') ||
      blob.contains('already exists in the keychain');
}
