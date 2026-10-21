// Made by Dr Ali
// Map raw API / Nest validation errors → short WeChat-clean copy in app locale.

import 'package:obic_mobile/l10n/app_localizations.dart';

import 'phone_activation_lock.dart';

/// Classify Socket/Timeout/ClientException into stable tokens for [friendlyApiError].
String classifyTransportError(Object error) {
  if (error is PhoneActivationRequired) return 'phone_activation';
  final raw = error.toString().toLowerCase();
  if (raw.contains('phoneactivationrequired')) return 'phone_activation';
  if (raw.contains('-25299') ||
      raw.contains('errsecduplicateitem') ||
      raw.contains('already exists in the keychain') ||
      raw.contains('unexpected security result')) {
    return 'keychain';
  }
  if (raw.contains('timeout') || raw.contains('timed out')) {
    return 'timeout';
  }
  if (raw.contains('failed host lookup') ||
      raw.contains('name not resolved') ||
      raw.contains('nodename nor servname')) {
    return 'dns';
  }
  // ClientException often embeds uri=http://192.168… — never surface that.
  if (raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('connection closed') ||
      raw.contains('connection abort') ||
      raw.contains('before full header') ||
      raw.contains('broken pipe') ||
      raw.contains('network is unreachable') ||
      raw.contains('uri=http://') ||
      raw.contains('uri=https://')) {
    return 'connection';
  }
  if (raw.contains('certificate') ||
      raw.contains('handshake') ||
      raw.contains('tls') ||
      raw.contains('ssl')) {
    return 'tls';
  }
  if (raw.contains('socket') ||
      raw.contains('network') ||
      raw.contains('clientexception') ||
      raw.contains('http exception')) {
    return 'network';
  }
  // Preserve unexpected messages — never force-label everything as network.
  return error.toString();
}

/// Prefer this over `e.toString()` in SnackBars for profile / auth / settings.
String friendlyApiError(
  Object error, {
  required AppLocalizations l10n,
  required String langCode,
}) {
  final raw = _rawMessage(error);
  final lower = raw.toLowerCase();

  if (lower == 'phone_activation' ||
      lower.contains('phoneactivationrequired')) {
    return l10n.phoneVerifyLocked;
  }
  if (lower == 'keychain' ||
      lower.contains('-25299') ||
      lower.contains('already exists in the keychain') ||
      lower.contains('unexpected security result')) {
    return l10n.errorGenericRetry;
  }
  if (lower == 'timeout' ||
      lower.contains('timeout') ||
      lower.contains('timed out')) {
    return l10n.authServerWaking;
  }
  if (lower == 'connection' ||
      lower == 'dns' ||
      lower == 'server_waking' ||
      lower.contains('server_waking') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('504')) {
    return l10n.authServerWaking;
  }
  if (lower == 'tls') {
    return l10n.authNetworkError;
  }
  if (lower.contains('email_required_for_phone') ||
      lower.contains('email required for phone')) {
    return l10n.verifyOtpEmailRequiredForPhone;
  }
  if (lower.contains('email_send_failed') ||
      lower.contains('email send failed')) {
    return l10n.verifyOtpEmailSendFailed;
  }
  if (lower.contains('sms_not_configured') ||
      lower.contains('sms not configured')) {
    return l10n.verifyOtpSmsNotConfigured;
  }
  if (lower.contains('sms_send_failed') || lower.contains('sms send failed')) {
    return l10n.verifyOtpSmsSendFailed;
  }
  // OTP verify — never surface raw Nest English ("Invalid code", etc.).
  if (lower.contains('invalid code') ||
      lower.contains('wrong code') ||
      lower.contains('incorrect code') ||
      lower.contains('invalid otp') ||
      lower == 'otp_invalid' ||
      lower == 'invalid_code') {
    return l10n.verifyOtpWrongCode;
  }
  if (lower.contains('code expired') ||
      lower.contains('otp expired') ||
      lower.contains('challenge expired') ||
      lower == 'otp_expired' ||
      lower == 'code_expired') {
    return l10n.verifyOtpExpired;
  }
  if (lower.contains('too many attempts') ||
      lower.contains('too many tries') ||
      lower == 'otp_too_many') {
    return l10n.verifyOtpTooManyAttempts;
  }
  if (lower.contains('verification session expired') ||
      lower.contains('invalid verification session') ||
      lower.contains('verify session expired')) {
    return l10n.verifyOtpSessionExpired;
  }
  if (lower.contains('sms_phone_countries')) {
    return l10n.smsPhoneCountries;
  }
  if (lower.contains('china numbers only') ||
      lower.contains('china mainland')) {
    return langCode == 'ar'
        ? 'التحقق بالهاتف يدعم أرقام الصين فقط حالياً'
        : langCode == 'zh'
            ? '目前手机验证仅支持中国大陆号码'
            : 'Phone verification supports China numbers only for now';
  }
  if (lower.contains('should not exist') ||
      lower.contains('whitelist') ||
      lower.contains('property city') ||
      lower.contains('property country') ||
      lower.contains('property obicid')) {
    return l10n.errorProfileFieldsUnsupported;
  }
  if (lower.contains('current password is incorrect') ||
      lower.contains('password is incorrect')) {
    return l10n.errorWrongPassword;
  }
  if (lower.contains('email already in use')) {
    return l10n.errorEmailTaken;
  }
  if (lower.contains('obic id already in use')) {
    return l10n.errorObicIdTaken;
  }
  if (lower.contains('once every 365') ||
      lower.contains('next change available')) {
    return l10n.profileObicIdCooldownHint;
  }
  if (lower.contains('obic id must be') ||
      lower.contains('start with a letter')) {
    return l10n.profileObicIdHint;
  }
  if (lower.contains('last superadmin') ||
      lower.contains('last super admin')) {
    return l10n.deleteAccountSuperAdminRule;
  }
  if (lower.contains('phone already')) {
    return langCode == 'ar'
        ? 'رقم الهاتف مستخدم مسبقاً'
        : langCode == 'zh'
            ? '该手机号已被使用'
            : 'Phone number already in use';
  }
  if (lower.contains('not signed in') ||
      lower.contains('authentication required')) {
    return l10n.authRequiredTitle;
  }
  if (lower.contains('provider_email_not_verified')) {
    return l10n.authProviderEmailNotVerified;
  }
  if (lower.contains('social_login_role_not_allowed')) {
    return l10n.authSocialRoleNotAllowed;
  }
  if (lower.contains('google_sign_in_not_configured') ||
      lower.contains('apple_sign_in_not_configured')) {
    return l10n.authSocialNotConfigured;
  }
  if (lower.contains('invalid_social_token')) {
    return l10n.authInvalidSocialToken;
  }
  if (lower.contains('not configured') &&
      (lower.contains('image') || lower.contains('file'))) {
    return l10n.obicAiAttachmentNotConfigured;
  }
  if (lower.contains('over 4 mb') || lower.contains('over 4mb')) {
    return l10n.obicAiFileTooLarge;
  }
  if (lower.contains('only jpeg') ||
      lower.contains('files are supported')) {
    return l10n.obicAiUnsupportedFile;
  }
  if (lower.contains('could not read')) {
    return l10n.obicAiCouldNotReadFile;
  }
  if (lower.contains('file type not allowed') ||
      lower.contains('upload failed') ||
      lower.contains('no files uploaded') ||
      lower.contains('empty upload')) {
    return l10n.errorUploadFailed;
  }
  if (lower.contains('moments-cover') ||
      lower.contains('coverurl') ||
      lower.contains('cover url')) {
    return l10n.errorMomentsCoverFailed;
  }
  if (lower.contains('only the secretary can update status')) {
    return l10n.errorOnlySecretaryCanUpdateStatus;
  }
  if (lower == 'network' ||
      lower.contains('socket') ||
      lower.contains('failed host lookup') ||
      lower.contains('clientexception') ||
      lower.contains('uri=http') ||
      lower.contains('before full header') ||
      lower.contains('connection')) {
    return l10n.authNetworkError;
  }
  if (lower.contains('unauthorized') || lower.contains('401')) {
    return l10n.authRequiredTitle;
  }

  // Drop Nest "Bad Request" prefixes and array dumps.
  var cleaned = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^AuthApiException:\s*'), '')
      .replaceFirst(
        RegExp(r'^Bad RequestException:\s*', caseSensitive: false),
        '',
      )
      .trim();
  if (cleaned.contains('property ') && cleaned.contains('should not')) {
    return l10n.errorProfileFieldsUnsupported;
  }
  if (cleaned.length > 160 ||
      cleaned.contains('class-validator') ||
      cleaned.startsWith('[')) {
    return l10n.errorGenericRetry;
  }
  if (cleaned.isEmpty) return l10n.errorGenericRetry;
  return cleaned;
}

String _rawMessage(Object error) {
  if (error is String) return error;
  try {
    final dynamic e = error;
    final m = e.message;
    if (m is String) return m;
  } catch (_) {}
  return error.toString();
}
