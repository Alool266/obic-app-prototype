// Made by Dr Ali
// Chat attach helpers — DTO kind mapping + local vs remote URL detection.

/// Maps UI attach kind to SendMessageDto kind (server enum).
String dtoAttachmentKind(String uiKind) {
  switch (uiKind) {
    case 'none':
      return 'none';
    case 'image':
      return 'image';
    case 'audio':
      return 'audio';
    case 'video':
      return 'video';
    case 'file':
      return 'file';
    default:
      return 'file';
  }
}

/// True when [url] is already a server/public attachment (not a device path).
bool isRemoteAttachmentUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final u = url.trim();
  if (u.startsWith('stub://')) return false;
  if (u.startsWith('http://') || u.startsWith('https://')) return true;
  if (u.startsWith('/uploads/')) return true;
  return false;
}

/// True when [url] looks like a local file path pending upload.
bool isLocalAttachmentPath(String? url) {
  if (url == null || url.isEmpty) return false;
  if (isRemoteAttachmentUrl(url)) return false;
  if (url.startsWith('stub://')) return false;
  // Absolute paths (iOS/Android) or file://
  if (url.startsWith('file://')) return true;
  if (url.startsWith('/')) return true;
  return false;
}

/// Voice note filename: `voice_12s.m4a` → duration seconds (null if unknown).
int? parseVoiceDurationSeconds(String? attachmentName) {
  if (attachmentName == null || attachmentName.isEmpty) return null;
  final m = RegExp(r'(?:^|[_-])(\d{1,4})s?\.', caseSensitive: false)
      .firstMatch(attachmentName);
  if (m != null) {
    final n = int.tryParse(m.group(1)!);
    if (n != null && n >= 0 && n < 3600) return n;
  }
  final m2 = RegExp(r'voice[_-]?(\d{1,4})', caseSensitive: false)
      .firstMatch(attachmentName);
  if (m2 != null) {
    final n = int.tryParse(m2.group(1)!);
    if (n != null && n >= 0 && n < 3600) return n;
  }
  return null;
}

String voiceAttachmentName(int seconds) {
  final s = seconds.clamp(1, 600);
  return 'voice_${s}s.m4a';
}

String formatVoiceDuration(int seconds) {
  final s = seconds.clamp(0, 5999);
  if (s < 60) return '0:${s.toString().padLeft(2, '0')}';
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

/// Trial Postgres bytea ceiling — larger files are disk-only (ephemeral on Render).
const int kChatUploadDurableMaxBytes = 12 * 1024 * 1024;

/// API multipart ceiling (uploads controller).
const int kChatUploadHardMaxBytes = 80 * 1024 * 1024;
