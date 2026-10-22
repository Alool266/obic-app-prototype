// Made by Dr Ali
// Google and Apple sign-in. Client IDs come from --dart-define.
// Missing IDs show a configuration error instead of crashing.

import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/region_controller.dart';
import 'auth_controller.dart';

/// Web client ID. The ID token `aud` is this value when [serverClientId] is set.
/// Public OAuth client ID (not a secret) — baked in as default so TestFlight
/// and store builds are always configured; --dart-define can still override.
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '479446860741-vodgknuv00juv33l1hksna5hgpvod84e.apps.googleusercontent.com',
);

/// iOS OAuth client ID. Required on iOS; unused on Android.
const String kGoogleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue:
      '479446860741-qc6p87a6066d440qtnq6uruoohl2t35f.apps.googleusercontent.com',
);

/// Apple Services ID. Required for Android. iOS uses the bundle ID natively.
const String kAppleServiceId = String.fromEnvironment(
  'APPLE_SERVICE_ID',
  defaultValue: 'com.obic.app.signin',
);

/// HTTPS return URL registered on the Services ID.
/// Trial/prod example: https://api.example.com/v1/auth/apple/android-callback
const String kAppleRedirectUri = String.fromEnvironment(
  'APPLE_REDIRECT_URI',
  defaultValue: 'https://api.obicgp.com/v1/auth/apple/android-callback',
);

enum SocialProvider { google, apple }

enum SocialAuthFailure { notConfigured, cancelled, failed }

class SocialAuthException implements Exception {
  const SocialAuthException(this.failure);

  final SocialAuthFailure failure;
}

class SocialCredential {
  const SocialCredential({required this.idToken, this.name});

  final String idToken;
  final String? name;
}

Future<void>? _googleInit;

/// Obtains a provider token, then asks the API to verify it and sign in.
/// China phone gates stay on the existing shell path after tokens are stored.
Future<bool> startSocialSignIn({
  required AuthController auth,
  required SocialProvider provider,
}) async {
  final cred = await obtainSocialCredential(provider);
  final prefs = await SharedPreferences.getInstance();
  final region = prefs.getString(kRegionCountryKey);
  final apiProvider = _apiProvider(provider);
  return auth.signInWithSocial(
    provider: apiProvider,
    idToken: cred.idToken,
    name: cred.name,
    regionCountry: region,
  );
}

String _apiProvider(SocialProvider provider) {
  switch (provider) {
    case SocialProvider.google:
      return 'google';
    case SocialProvider.apple:
      return 'apple';
  }
}

Future<SocialCredential> obtainSocialCredential(SocialProvider provider) {
  switch (provider) {
    case SocialProvider.google:
      return _googleCredential();
    case SocialProvider.apple:
      return _appleCredential();
  }
}

Future<void> _ensureGoogleInitialized() {
  final existing = _googleInit;
  if (existing != null) return existing;
  final next = GoogleSignIn.instance.initialize(
    clientId: Platform.isIOS && kGoogleIosClientId.isNotEmpty
        ? kGoogleIosClientId
        : null,
    serverClientId: kGoogleServerClientId,
  );
  _googleInit = next.catchError((Object error) {
    _googleInit = null;
    throw error;
  });
  return _googleInit!;
}

Future<SocialCredential> _googleCredential() async {
  if (kGoogleServerClientId.isEmpty) {
    throw const SocialAuthException(SocialAuthFailure.notConfigured);
  }
  if (Platform.isIOS && kGoogleIosClientId.isEmpty) {
    throw const SocialAuthException(SocialAuthFailure.notConfigured);
  }
  try {
    await _ensureGoogleInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const SocialAuthException(SocialAuthFailure.notConfigured);
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const SocialAuthException(SocialAuthFailure.failed);
    }
    final name = account.displayName?.trim();
    return SocialCredential(
      idToken: idToken,
      name: name != null && name.isNotEmpty ? name : null,
    );
  } on SocialAuthException {
    rethrow;
  } on GoogleSignInException catch (error) {
    throw SocialAuthException(_googleFailure(error.code));
  } catch (_) {
    throw const SocialAuthException(SocialAuthFailure.failed);
  }
}

SocialAuthFailure _googleFailure(GoogleSignInExceptionCode code) {
  switch (code) {
    case GoogleSignInExceptionCode.canceled:
    case GoogleSignInExceptionCode.interrupted:
      return SocialAuthFailure.cancelled;
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
    case GoogleSignInExceptionCode.uiUnavailable:
      return SocialAuthFailure.notConfigured;
    case GoogleSignInExceptionCode.unknownError:
    case GoogleSignInExceptionCode.userMismatch:
      return SocialAuthFailure.failed;
  }
}

Future<SocialCredential> _appleCredential() async {
  final native = Platform.isIOS || Platform.isMacOS;
  WebAuthenticationOptions? web;
  if (!native) {
    final redirect = Uri.tryParse(kAppleRedirectUri);
    if (kAppleServiceId.isEmpty ||
        redirect == null ||
        !redirect.hasScheme ||
        redirect.host.isEmpty) {
      throw const SocialAuthException(SocialAuthFailure.notConfigured);
    }
    web = WebAuthenticationOptions(
      clientId: kAppleServiceId,
      redirectUri: redirect,
    );
  }
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: web,
    );
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const SocialAuthException(SocialAuthFailure.failed);
    }
    final parts = <String>[
      if (credential.givenName != null &&
          credential.givenName!.trim().isNotEmpty)
        credential.givenName!.trim(),
      if (credential.familyName != null &&
          credential.familyName!.trim().isNotEmpty)
        credential.familyName!.trim(),
    ];
    final name = parts.join(' ');
    return SocialCredential(idToken: idToken, name: name.isEmpty ? null : name);
  } on SocialAuthException {
    rethrow;
  } on SignInWithAppleAuthorizationException catch (error) {
    throw SocialAuthException(_appleFailure(error.code));
  } on SignInWithAppleNotSupportedException {
    throw const SocialAuthException(SocialAuthFailure.notConfigured);
  } catch (_) {
    throw const SocialAuthException(SocialAuthFailure.failed);
  }
}

SocialAuthFailure _appleFailure(AuthorizationErrorCode code) {
  switch (code) {
    case AuthorizationErrorCode.canceled:
      return SocialAuthFailure.cancelled;
    case AuthorizationErrorCode.notHandled:
    case AuthorizationErrorCode.notInteractive:
    case AuthorizationErrorCode.unknown:
      return SocialAuthFailure.notConfigured;
    case AuthorizationErrorCode.failed:
    case AuthorizationErrorCode.invalidResponse:
    case AuthorizationErrorCode.credentialExport:
    case AuthorizationErrorCode.credentialImport:
    case AuthorizationErrorCode.matchedExcludedCredential:
      return SocialAuthFailure.failed;
  }
}
