// Made by Dr Ali
// Multi-account vault — WeChat-style switcher; tokens stay on device until exit.

import 'dart:convert';

import 'auth_models.dart';
import 'secure_store.dart';

class SavedAccount {
  const SavedAccount({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.userJson,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final String userJson;

  ObicUser? get user {
    try {
      return ObicUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userJson': userJson,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userJson: json['userJson'] as String,
    );
  }
}

/// Pluggable backend so unit tests never touch the platform Keystore.
abstract class AccountVaultStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureAccountVaultStore implements AccountVaultStore {
  SecureAccountVaultStore({ObicSecureStore? store})
      : _store = store ?? ObicSecureStore();

  final ObicSecureStore _store;

  @override
  Future<String?> read(String key) => _store.read(key);

  @override
  Future<void> write(String key, String value) => _store.write(key, value);
}

class MemoryAccountVaultStore implements AccountVaultStore {
  final Map<String, String> _m = {};

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, String value) async {
    _m[key] = value;
  }
}

class AccountVault {
  AccountVault({AccountVaultStore? store})
      : _store = store ?? SecureAccountVaultStore();

  static const _vaultKey = 'obic_account_vault_v1';

  final AccountVaultStore _store;

  Future<List<SavedAccount>> list() async {
    final raw = await _store.read(_vaultKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e)))
          .where(
            (a) =>
                a.userId.isNotEmpty &&
                a.accessToken.isNotEmpty &&
                a.refreshToken.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(SavedAccount account) async {
    final all = await list();
    final next = <SavedAccount>[
      account,
      ...all.where((a) => a.userId != account.userId),
    ];
    await _write(next);
  }

  Future<SavedAccount?> get(String userId) async {
    for (final a in await list()) {
      if (a.userId == userId) return a;
    }
    return null;
  }

  Future<void> remove(String userId) async {
    final next = (await list()).where((a) => a.userId != userId).toList();
    await _write(next);
  }

  Future<void> _write(List<SavedAccount> accounts) async {
    await _store.write(
      _vaultKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }
}
