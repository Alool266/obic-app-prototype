// Made by Dr Ali
// Auth session controller — restores tokens; guests browse, login for actions.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/api_errors.dart';
import '../../core/china_push.dart';
import '../../core/realtime_client.dart';
import 'account_vault.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'token_storage.dart';
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    AuthApi? api,
    TokenStorage? storage,
    AccountVault? vault,
  })  : _api = api ?? AuthApi(),
        _storage = storage ?? TokenStorage(),
        _vault = vault ?? AccountVault();

  final AuthApi _api;
  final TokenStorage _storage;
  final AccountVault _vault;

  AuthStatus status = AuthStatus.unknown;
  ObicUser? user;
  String? lastError;
  bool busy = false;
  String? pendingTotpSession;
  AuthVerifyRequiredException? pendingVerify;

  /// One refresh at a time. Parallel callers (chat poll + bootstrap) used to
  /// both present the same refresh token; the loser looked like a stolen token.
  Future<String?>? _refreshInFlight;

  bool get needsTotp => pendingTotpSession != null && pendingTotpSession!.isNotEmpty;

  bool get needsVerify => pendingVerify != null;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isGuest => !isAuthenticated;

  /// Short-lived access JWT for authenticated API calls (never logged).
  Future<String?> accessToken() => _storage.readAccessToken();

  /// Returns a valid access token, refreshing once if the JWT expired (~15m).
  ///
  /// Hot path: decode JWT `exp` locally — no `/me` and no [notifyListeners]
  /// when the token is still fresh. Pollers used to call this every few
  /// seconds; each call previously hit the network and rebuilt the whole app.
  ///
  /// Session rule: stay logged in unless refresh is truly revoked/invalid
  /// (confirmed 401/403 after a silent retry) or the user Signs out /
  /// clears via Switch Account. Network blips, 5xx, and Render cold starts
  /// never wipe tokens.
  Future<String?> ensureAccessToken() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null || refresh == null) return null;

    // Still valid (60s skew) → return immediately. Session stays intact.
    if (_jwtStillValid(access, skew: const Duration(seconds: 60))) {
      return access;
    }

    try {
      return await _refreshSingleFlight(refresh);
    } on AuthApiException catch (e) {
      // Soft API errors (5xx, waking) — keep stored tokens.
      if (e.statusCode != 401 && e.statusCode != 403) {
        return access;
      }
      // Silent retry — proxies / cold starts can spuriously reject once.
      try {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        return await _refreshSingleFlight(refresh);
      } on AuthApiException catch (e2) {
        if (e2.statusCode == 401 || e2.statusCode == 403) {
          // Confirmed invalid/revoked refresh — only then clear local session.
          await _invalidateLocalSession();
          notifyListeners();
          return null;
        }
        return access;
      } catch (_) {
        // Retry network blip — keep session.
        return access;
      }
    } catch (_) {
      // Network blip during refresh — keep stored tokens for next launch.
      return access;
    }
  }

  Future<String?> _refreshSingleFlight(String refresh) {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final run = _persistRefreshedTokens(refresh);
    _refreshInFlight = run;
    return run.whenComplete(() {
      if (identical(_refreshInFlight, run)) _refreshInFlight = null;
    });
  }

  Future<String> _persistRefreshedTokens(String refresh) async {
    final tokens = await _api.refresh(refresh);
    ObicUser? me = user;
    try {
      me = await _api.fetchMe(tokens.accessToken);
    } catch (_) {
      // Keep cached profile if /me blips after a successful refresh.
    }
    final profile = me ?? user;
    final existingUserJson = await _storage.readUserJson();
    final userJson = profile != null
        ? jsonEncode(profile.toJson())
        : (existingUserJson ?? '{}');
    await _storage.saveSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userJson: userJson,
    );
    if (me != null) user = me;
    status = AuthStatus.authenticated;
    final uid = (me ?? user)?.id;
    if (uid != null && uid.isNotEmpty) {
      await _vault.upsert(
        SavedAccount(
          userId: uid,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userJson: userJson,
        ),
      );
    }
    unawaited(RealtimeClient.instance.bindAuth(tokens.accessToken));
    notifyListeners();
    return tokens.accessToken;
  }

  /// True when JWT `exp` is in the future (minus [skew]). Undecodable → false
  /// so we attempt refresh rather than assuming forever-valid.
  static bool _jwtStillValid(String token, {required Duration skew}) {
    final payload = _decodeJwtPayload(token);
    final exp = payload?['exp'];
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    return DateTime.now().toUtc().isBefore(expiresAt.subtract(skew));
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> bootstrap() async {
    try {
      // Simulator / first launch can hang on Keychain — never block UI forever.
      await _bootstrapInner().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Slow network must not force login or race-clear tokens.
      await _restoreCachedSessionOrGuest();
    } catch (_) {
      await _restoreCachedSessionOrGuest();
    }
  }

  Future<void> _bootstrapInner() async {
    var access = await _storage.readAccessToken();
    var refresh = await _storage.readRefreshToken();
    var cached = await _storage.readUserJson();

    // Keystore blip / upgrade: active keys empty but vault still has account.
    if (access == null || refresh == null) {
      final restored = await _restoreActiveFromVault();
      if (!restored) {
        user = null;
        status = AuthStatus.unauthenticated;
        unawaited(RealtimeClient.instance.clearAuth());
        notifyListeners();
        return;
      }
      access = await _storage.readAccessToken();
      refresh = await _storage.readRefreshToken();
      cached = await _storage.readUserJson();
      if (access == null || refresh == null) {
        user = null;
        status = AuthStatus.unauthenticated;
        unawaited(RealtimeClient.instance.clearAuth());
        notifyListeners();
        return;
      }
    }

    unawaited(
      ChinaPush.sync(accessToken: access, refreshToken: refresh),
    );

    // Optimistic restore: kill/reopen stays logged in before network returns.
    if (cached != null) {
      try {
        user = ObicUser.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
        status = AuthStatus.authenticated;
        unawaited(RealtimeClient.instance.bindAuth(access));
        unawaited(
          ChinaPush.sync(accessToken: access, refreshToken: refresh),
        );
        notifyListeners();
      } catch (_) {
        // Bad cache JSON — still try network with tokens.
      }
    }

    try {
      user = await _api.fetchMe(access);
      await _persistUser(user!);
      status = AuthStatus.authenticated;
      unawaited(RealtimeClient.instance.bindAuth(access));
    } on AuthApiException catch (e) {
      if (e.statusCode == 401) {
        await _refreshDuringBootstrap(refresh);
      }
      // Non-401 (5xx, etc.): keep tokens + cached user.
    } catch (_) {
      // Offline / DNS / timeout inside HTTP — keep tokens.
    }
    notifyListeners();
  }

  /// Prefer vaulted account when active secure keys are missing (not Sign out).
  Future<bool> _restoreActiveFromVault() async {
    try {
      final accounts = await _vault.list();
      if (accounts.isEmpty) return false;
      final entry = accounts.first;
      await _storage.saveSession(
        accessToken: entry.accessToken,
        refreshToken: entry.refreshToken,
        userJson: entry.userJson,
      );
      return true;
    } catch (_) {
      // Keystore / plugin blip — treat as no vault, not as logout.
      return false;
    }
  }

  Future<void> _refreshDuringBootstrap(String refresh) async {
    Future<void> attempt() async {
      final tokens = await _api.refresh(refresh);
      ObicUser? me;
      try {
        me = await _api.fetchMe(tokens.accessToken);
      } catch (_) {
        // Refresh succeeded — keep new tokens even if /me blips.
      }
      final existingUserJson = await _storage.readUserJson();
      final profile = me ?? user;
      await _storage.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userJson: profile != null
            ? jsonEncode(profile.toJson())
            : (existingUserJson ?? '{}'),
      );
      if (me != null) user = me;
      status = AuthStatus.authenticated;
      unawaited(RealtimeClient.instance.bindAuth(tokens.accessToken));
    }

    try {
      await attempt();
    } on AuthApiException catch (e) {
      if (e.statusCode != 401 && e.statusCode != 403) {
        // Soft failures keep cached session.
        return;
      }
      try {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await attempt();
      } on AuthApiException catch (e2) {
        if (e2.statusCode == 401 || e2.statusCode == 403) {
          await _invalidateLocalSession();
        }
      } catch (_) {
        // Network during retry — keep cached session.
      }
    } catch (_) {
      // Network during refresh — keep cached session.
    }
  }

  /// After timeout/error: stay authenticated if secure storage still has a session.
  Future<void> _restoreCachedSessionOrGuest() async {
    var access = await _storage.readAccessToken();
    var refresh = await _storage.readRefreshToken();
    var cached = await _storage.readUserJson();

    if (access == null || refresh == null) {
      final restored = await _restoreActiveFromVault();
      if (restored) {
        access = await _storage.readAccessToken();
        refresh = await _storage.readRefreshToken();
        cached = await _storage.readUserJson();
      }
    }

    if (access == null || refresh == null) {
      user = null;
      status = AuthStatus.unauthenticated;
      unawaited(RealtimeClient.instance.clearAuth());
      notifyListeners();
      return;
    }

    if (cached != null) {
      try {
        user = ObicUser.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {
        // Tokens alone still mean "signed in"; profile can load later.
      }
    }
    status = AuthStatus.authenticated;
    unawaited(RealtimeClient.instance.bindAuth(access));
    notifyListeners();
  }

  Future<void> _invalidateLocalSession() async {
    await _storage.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    unawaited(RealtimeClient.instance.clearAuth());
  }

  Future<bool> register({
    String? email,
    String? phone,
    required String password,
    required String name,
    String? locale,
    String? regionCountry,
  }) async {
    busy = true;
    lastError = null;
    pendingVerify = null;
    notifyListeners();
    try {
      final result = await _api.register(
        email: email,
        phone: phone,
        password: password,
        name: name,
        locale: locale,
        regionCountry: regionCountry,
      );
      return await _completeAuth(result.tokens, result.user);
    } on AuthVerifyRequiredException catch (e) {
      pendingVerify = e;
      return false;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AuthVerifyRequiredException?> startEmailVerify({
    String? email,
    String? locale,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final token = await ensureAccessToken();
      if (token == null) {
        lastError = 'Not signed in';
        return null;
      }
      final pending = await _api.startEmailVerify(
        accessToken: token,
        email: email,
        locale: locale,
      );
      pendingVerify = pending;
      return pending;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = classifyTransportError(e);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AuthVerifyRequiredException?> startPhoneVerify({
    required String phone,
    String? email,
    String? locale,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final token = await ensureAccessToken();
      if (token == null) {
        lastError = 'Not signed in';
        return null;
      }
      final pending = await _api.startPhoneVerify(
        accessToken: token,
        phone: phone,
        email: email,
        locale: locale,
      );
      pendingVerify = pending;
      return pending;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = classifyTransportError(e);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    busy = true;
    lastError = null;
    pendingTotpSession = null;
    pendingVerify = null;
    notifyListeners();
    try {
      final result = await _api.login(
        email: email,
        phone: phone,
        password: password,
      );
      return await _completeAuth(result.tokens, result.user);
    } on AuthTotpRequiredException catch (e) {
      pendingTotpSession = e.totpSession;
      return false;
    } on AuthVerifyRequiredException catch (e) {
      pendingVerify = e;
      return false;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Phone + SMS code sign-in (no password). On success the OTP challenge
  /// is in [pendingVerify] and the caller routes to the OTP screen, exactly
  /// like the password flow. Returns true when a code was sent.
  Future<bool> startPhoneCodeLogin({
    required String phone,
    String? locale,
    String? regionCountry,
  }) async {
    busy = true;
    lastError = null;
    pendingTotpSession = null;
    pendingVerify = null;
    notifyListeners();
    try {
      pendingVerify = await _api.startPhoneLogin(
        phone: phone,
        locale: locale,
        regionCountry: regionCountry,
      );
      return true;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithSocial({
    required String provider,
    required String idToken,
    String? name,
    String? regionCountry,
  }) async {
    busy = true;
    lastError = null;
    pendingTotpSession = null;
    pendingVerify = null;
    notifyListeners();
    try {
      final result = await _api.socialSignIn(
        provider: provider,
        idToken: idToken,
        name: name,
        regionCountry: regionCountry,
      );
      return await _completeAuth(result.tokens, result.user);
    } on AuthVerifyRequiredException catch (e) {
      pendingVerify = e;
      return false;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({
    required String verifySession,
    required String code,
  }) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await _api.verifyOtp(
        verifySession: verifySession,
        code: code.trim(),
      );
      pendingVerify = null;
      return await _completeAuth(result.tokens, result.user);
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AuthVerifyRequiredException?> resendOtp(String verifySession) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final next = await _api.resendOtp(verifySession);
      pendingVerify = next;
      return next;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = classifyTransportError(e);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> verifyTotp(String code) async {
    final session = pendingTotpSession;
    if (session == null || session.isEmpty) return false;
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await _api.verifyTotpLogin(
        totpSession: session,
        code: code.trim(),
      );
      pendingTotpSession = null;
      return await _completeAuth(result.tokens, result.user);
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancelTotp() {
    pendingTotpSession = null;
    notifyListeners();
  }

  /// Soft-delete on server (password required), drop vault entry, clear session.
  Future<bool> deleteAccount({required String currentPassword}) async {
    busy = true;
    notifyListeners();
    try {
      final access = await ensureAccessToken();
      if (access == null) {
        lastError = 'Not signed in';
        return false;
      }
      if (currentPassword.trim().isEmpty) {
        lastError = 'Password required';
        return false;
      }
      final uid = user?.id;
      await _api.deleteMe(
        accessToken: access,
        currentPassword: currentPassword.trim(),
      );
      if (uid != null) {
        await _vault.remove(uid);
      }
      await _storage.clear();
      user = null;
      status = AuthStatus.unauthenticated;
      unawaited(RealtimeClient.instance.clearAuth());
      return true;
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    try {
      final refresh = await _storage.readRefreshToken();
      final uid = user?.id;
      if (refresh != null) {
        try {
          await _api.logout(refresh);
        } catch (_) {
          // Local logout still proceeds if the network call fails.
        }
      }
      if (uid != null) {
        await _vault.remove(uid);
      }
    } finally {
      await _storage.clear();
      user = null;
      status = AuthStatus.unauthenticated;
      unawaited(RealtimeClient.instance.clearAuth());
      busy = false;
      notifyListeners();
    }
  }

  /// Accounts available for WeChat-style switching (includes current).
  Future<List<SavedAccount>> listSavedAccounts() async {
    await _syncCurrentToVault();
    return _vault.list();
  }

  /// Park the current session in the vault so another account can be added.
  /// Does **not** clear the active session — cancel/back keeps the current user
  /// signed in (WeChat multi-account). Login success upserts the new account
  /// and switches to it; the previous account remains in the vault.
  Future<void> prepareAddAccount() async {
    await _syncCurrentToVault();
  }

  /// Restore a previously vaulted account after cancelling add-account login.
  /// No-op when already authenticated (preferred add-account path).
  Future<void> restoreAfterCancelledAddAccount() async {
    if (isAuthenticated) return;
    final accounts = await _vault.list();
    if (accounts.isEmpty) return;
    await switchToAccount(accounts.first.userId);
  }

  /// Switch to a vaulted account. Keeps working offline (local tokens).
  Future<bool> switchToAccount(String userId) async {
    if (user?.id == userId) return true;
    await _syncCurrentToVault();
    final entry = await _vault.get(userId);
    if (entry == null) return false;
    try {
      final u = ObicUser.fromJson(
        jsonDecode(entry.userJson) as Map<String, dynamic>,
      );
      await _storage.saveSession(
        accessToken: entry.accessToken,
        refreshToken: entry.refreshToken,
        userJson: entry.userJson,
      );
      user = u;
      status = AuthStatus.authenticated;
      lastError = null;
      unawaited(RealtimeClient.instance.bindAuth(entry.accessToken));
      notifyListeners();
      // Soft refresh — never wipe session on network failure.
      unawaited(refreshProfile());
      return true;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    }
  }

  Future<void> _syncCurrentToVault() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    final userJson = await _storage.readUserJson();
    final uid = user?.id;
    if (access == null ||
        refresh == null ||
        userJson == null ||
        uid == null ||
        uid.isEmpty) {
      return;
    }
    await _vault.upsert(
      SavedAccount(
        userId: uid,
        accessToken: access,
        refreshToken: refresh,
        userJson: userJson,
      ),
    );
  }

  Future<bool> _runAuth(
    Future<({AuthTokens tokens, ObicUser user})> Function() action,
  ) async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await action();
      return await _completeAuth(result.tokens, result.user);
    } on AuthApiException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = classifyTransportError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _completeAuth(AuthTokens tokens, ObicUser u) async {
    final userJson = jsonEncode(u.toJson());
    await _storage.saveSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      userJson: userJson,
    );
    user = u;
    status = AuthStatus.authenticated;
    unawaited(RealtimeClient.instance.bindAuth(tokens.accessToken));
    await _vault.upsert(
      SavedAccount(
        userId: u.id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userJson: userJson,
      ),
    );
    // Ensure listeners (register/login success navigation) see auth before
    // the surrounding busy=false notify — belt-and-suspenders vs blank UI.
    notifyListeners();
    return true;
  }

  Future<void> _persistUser(ObicUser u) async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null || refresh == null) return;
    final userJson = jsonEncode(u.toJson());
    await _storage.saveSession(
      accessToken: access,
      refreshToken: refresh,
      userJson: userJson,
    );
    // Keep vault in sync so cold-start vault fallback always has fresh tokens.
    if (u.id.isNotEmpty) {
      await _vault.upsert(
        SavedAccount(
          userId: u.id,
          accessToken: access,
          refreshToken: refresh,
          userJson: userJson,
        ),
      );
    }
  }

  /// Refresh local profile after avatar / me updates.
  Future<void> applyUser(ObicUser u) async {
    user = u;
    await _persistUser(u);
    notifyListeners();
  }

  /// Re-fetch /users/me so role/avatar stay current (e.g. staff after re-login).
  Future<void> refreshProfile() async {
    final access = await accessToken();
    if (access == null) return;
    try {
      final me = await _api.fetchMe(access);
      await applyUser(me);
    } catch (_) {
      // Keep cached user if refresh fails.
    }
  }

  bool get isStaffRole {
    final r = user?.role;
    return r == 'Employee' || r == 'SuperAdmin';
  }

  bool get isSuperAdmin => user?.role == 'SuperAdmin';

  bool get isEmployee => user?.role == 'Employee';

  /// Internal Ops: SuperAdmin always; Employee only when server opsAccess=true.
  /// Customers never see Ops (kOpsPrototype must not open it for them).
  bool get canOpenOps {
    if (isSuperAdmin) return true;
    if (isEmployee && (user?.opsAccess ?? false)) return true;
    return false;
  }

  /// Hotel & flight offers desk: SuperAdmin always; Employee only when
  /// server offersAccess=true. Customers never manage offers.
  bool get canManageOffers {
    if (isSuperAdmin) return true;
    if (isEmployee && (user?.offersAccess ?? false)) return true;
    return false;
  }
}
