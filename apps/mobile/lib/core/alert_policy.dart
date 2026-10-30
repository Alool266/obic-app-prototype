// Made by Dr Ali
// Who hears a message, call, or customer-action alert.
// Role is never an input: customers, employees, and admins use the same rules.

import '../features/messages/chat_call_body.dart';

/// Chat banner. Quiet for your own send, the chat already on screen, or a muted chat.
bool shouldAlertChatMessage({
  required String? myUserId,
  required String? senderId,
  required bool chatOpen,
  required bool muted,
  required bool appInForeground,
}) {
  if (senderId != null && senderId.isNotEmpty && senderId == myUserId) {
    return false;
  }
  if (muted) return false;
  // Quiet only while that chat is on screen. Another app still gets the banner.
  if (chatOpen && appInForeground) return false;
  return true;
}

/// Inbox row (booking, handoff, bug, mini app). Skip the open or muted chat.
/// The server already omits the customer who performed the action.
bool shouldAlertInbox({
  required bool chatOpen,
  required bool muted,
}) {
  if (chatOpen || muted) return false;
  return true;
}

/// Short preview. Call-log lines keep the existing missed / no-answer text.
String chatMessagePreview(
  Map<String, dynamic> message, {
  bool arabic = false,
}) {
  if (message['recalled'] == true) {
    return arabic ? 'تم حذف الرسالة' : 'Message recalled';
  }
  final body = (message['body'] as String?)?.trim() ?? '';
  if (body.contains('[[obic:call:')) {
    final record = parseCallRecordBody(body);
    if (record != null) {
      if (!callRecordConnected(record)) {
        return missedCallLabel(video: record.isVideo, arabic: arabic);
      }
      final dur = formatCallDuration(record.durationSeconds);
      if (arabic) {
        return record.isVideo ? 'مكالمة فيديو $dur' : 'مكالمة صوتية $dur';
      }
      return record.isVideo ? 'Video call $dur' : 'Voice call $dur';
    }
  }
  if (body.contains('[[obic:sticker:')) {
    return arabic ? 'ملصق' : 'Sticker';
  }
  if (body.startsWith('[[status]]')) {
    return arabic ? 'تحديث طلب' : 'Order update';
  }
  if (body.isNotEmpty && !body.startsWith('[[')) {
    return body.length > 80 ? '${body.substring(0, 77)}…' : body;
  }
  final kind = message['attachmentKind']?.toString() ?? '';
  if (arabic) {
    return switch (kind) {
      'audio' => 'رسالة صوتية',
      'image' => 'صورة',
      'video' => 'فيديو',
      'file' => 'ملف',
      'location' => 'موقع',
      _ => 'رسالة جديدة',
    };
  }
  return switch (kind) {
    'audio' => 'Voice message',
    'image' => 'Photo',
    'video' => 'Video',
    'file' => 'File',
    'location' => 'Location',
    _ => 'New message',
  };
}

String missedCallLabel({required bool video, bool arabic = false}) {
  if (arabic) return video ? 'مكالمة فيديو فائتة' : 'مكالمة فائتة';
  return video ? 'Missed video call' : 'Missed voice call';
}
