// Made by Dr Ali
// Offline outbound chat queue — persist, optimistic bubbles, flush on reconnect.
// Attachments: keep local path until flush uploads via POST /v1/uploads.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../auth/auth_controller.dart';
import '../social/social_api.dart';
import 'chat_attach_helpers.dart';

class QueuedOutboundMessage {
  QueuedOutboundMessage({
    required this.localId,
    required this.threadId,
    required this.body,
    this.attachmentKind = 'none',
    this.attachmentName,
    this.attachmentUrl,
    this.locale,
    this.failed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String localId;
  final String threadId;
  final String body;
  final String attachmentKind;
  final String? attachmentName;
  final String? attachmentUrl;
  final String? locale;
  final DateTime createdAt;

  /// Send was tried and the network or server refused it. Tap to resend.
  bool failed;

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'threadId': threadId,
        'body': body,
        'attachmentKind': attachmentKind,
        'attachmentName': attachmentName,
        'attachmentUrl': attachmentUrl,
        'locale': locale,
        'failed': failed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedOutboundMessage.fromJson(Map<String, dynamic> json) {
    return QueuedOutboundMessage(
      localId: json['localId'] as String,
      threadId: json['threadId'] as String,
      body: (json['body'] as String?) ?? '',
      attachmentKind: (json['attachmentKind'] as String?) ?? 'none',
      attachmentName: json['attachmentName'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      locale: json['locale'] as String?,
      failed: json['failed'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Optimistic bubble shape matching SocialApi message rows.
  Map<String, dynamic> asOptimisticBubble({
    required String senderId,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return {
      'id': localId,
      'threadId': threadId,
      'body': body,
      'attachmentKind': attachmentKind,
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'pending': true,
      'failed': failed,
      'localId': localId,
    };
  }
}

class OutboundMessageQueue extends ChangeNotifier {
  OutboundMessageQueue._();
  static final OutboundMessageQueue instance = OutboundMessageQueue._();

  List<QueuedOutboundMessage>? _items;
  bool _flushing = false;

  bool get isFlushing => _flushing;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/obic_outbound_queue.json');
  }

  Future<List<QueuedOutboundMessage>> list() async {
    if (_items != null) return List.of(_items!);
    try {
      final f = await _file();
      if (!await f.exists()) {
        _items = [];
        return [];
      }
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) {
        _items = [];
        return [];
      }
      _items = raw
          .whereType<Map>()
          .map((e) => QueuedOutboundMessage.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
      return List.of(_items!);
    } catch (_) {
      _items = [];
      return [];
    }
  }

  Future<void> _persist() async {
    final f = await _file();
    final data = (_items ?? []).map((e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(data));
  }

  Future<List<QueuedOutboundMessage>> forThread(String threadId) async {
    final all = await list();
    return all.where((e) => e.threadId == threadId).toList();
  }

  /// In-memory peek after [list] has warmed the cache (UI rebuilds).
  List<QueuedOutboundMessage> forThreadSync(String threadId) {
    return (_items ?? [])
        .where((e) => e.threadId == threadId)
        .toList(growable: false);
  }

  Future<QueuedOutboundMessage> enqueue({
    required String threadId,
    required String body,
    String attachmentKind = 'none',
    String? attachmentName,
    String? attachmentUrl,
    String? locale,
  }) async {
    await list();
    final item = QueuedOutboundMessage(
      localId: 'pending_${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      body: body,
      attachmentKind: dtoAttachmentKind(attachmentKind),
      attachmentName: attachmentName,
      attachmentUrl: attachmentUrl,
      locale: locale,
    );
    _items = [...?_items, item];
    await _persist();
    notifyListeners();
    return item;
  }

  Future<void> remove(String localId) async {
    await list();
    _items = (_items ?? []).where((e) => e.localId != localId).toList();
    await _persist();
    notifyListeners();
  }

  /// Resolve local path → real /uploads URL (or pass through remote URL).
  Future<String?> _resolveAttachmentUrl({
    required SocialApi api,
    required String accessToken,
    required QueuedOutboundMessage next,
  }) async {
    final kind = next.attachmentKind;
    if (kind == 'none') return null;
    final raw = next.attachmentUrl;
    if (raw == null || raw.isEmpty) {
      throw StateError('Missing attachment');
    }
    if (raw.startsWith('stub://')) {
      throw StateError('Stub attachment URL not allowed');
    }
    if (isRemoteAttachmentUrl(raw)) return raw;
    if (!isLocalAttachmentPath(raw)) {
      throw StateError('Invalid attachment URL');
    }
    final path = raw.startsWith('file://') ? Uri.parse(raw).toFilePath() : raw;
    final items = await api.uploadFiles(
      accessToken: accessToken,
      files: [
        (
          path: path,
          filename: next.attachmentName ?? p.basename(path),
        ),
      ],
    );
    if (items.isEmpty) throw StateError('Upload failed');
    final url = items.first['url'] as String?;
    if (url == null || url.isEmpty) throw StateError('Upload failed');
    return url;
  }

  /// Drop head of queue (poison pill) and persist.
  Future<void> _dropHead() async {
    if ((_items ?? []).isEmpty) return;
    _items = _items!.sublist(1);
    await _persist();
    notifyListeners();
  }

  /// True when retrying this item can never succeed (missing file / bad URL).
  bool _isPermanentAttachFailure(QueuedOutboundMessage next, Object error) {
    final kind = next.attachmentKind;
    if (kind == 'none') return false;
    final raw = next.attachmentUrl ?? '';
    if (raw.startsWith('stub://')) return true;
    if (raw.isEmpty) return true;
    if (isLocalAttachmentPath(raw)) {
      final path =
          raw.startsWith('file://') ? Uri.parse(raw).toFilePath() : raw;
      if (!File(path).existsSync()) return true;
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('missing attachment') ||
        msg.contains('stub attachment') ||
        msg.contains('invalid attachment')) {
      return true;
    }
    return false;
  }

  /// Move a failed bubble back to waiting and to the front of the queue.
  Future<void> retry(String localId) async {
    await list();
    final items = _items;
    if (items == null) return;
    final index = items.indexWhere((item) => item.localId == localId);
    if (index < 0) return;
    final item = items.removeAt(index);
    item.failed = false;
    items.insert(0, item);
    await _persist();
    notifyListeners();
  }

  /// Send queued messages FIFO. Skips permanently-broken attachments so a
  /// failed photo cannot block later text forever. Transient errors stop the
  /// pass (retry on reconnect / next flush).
  Future<int> flush({
    required SocialApi api,
    required AuthController auth,
  }) async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      final token = await auth.ensureAccessToken();
      if (token == null) return 0;
      await list();
      while ((_items ?? []).isNotEmpty) {
        final next = _items!.first;
        try {
          final attachUrl = await _resolveAttachmentUrl(
            api: api,
            accessToken: token,
            next: next,
          );
          await api.sendMessage(
            accessToken: token,
            threadId: next.threadId,
            body: next.body.isEmpty ? '' : next.body,
            attachmentKind: next.attachmentKind,
            attachmentName: next.attachmentName,
            attachmentUrl: attachUrl,
            locale: next.locale,
          );
          await _dropHead();
          sent++;
        } catch (e) {
          // Any failed attachment must not block later text forever
          // (missing file, upload 5xx, oversized, expired local cache, …).
          if (next.attachmentKind != 'none' ||
              _isPermanentAttachFailure(next, e)) {
            await _dropHead();
            continue;
          }
          // Auth / network / 5xx on plain text — keep, mark failed, retry later.
          next.failed = true;
          await _persist();
          notifyListeners();
          break;
        }
      }
    } finally {
      _flushing = false;
    }
    return sent;
  }
}
