// Made by Dr Ali
// Friend add / accept banners. Customers, employees, and admins share this.
// The secretary desk is not a recipient. No phone-activation gate.

enum FriendAlertKind {
  request,
  accepted,
}

/// One local banner. [title] is the other person's name. [body] is the short line.
class FriendAlert {
  const FriendAlert({
    required this.kind,
    required this.requestId,
    required this.peerUserId,
    required this.name,
  });

  final FriendAlertKind kind;
  final String requestId;
  final String peerUserId;
  final String name;

  static const requestLine = 'sent you a friend request';
  static const acceptedLine = 'accepted your friend request';

  String get title {
    final clean = name.trim();
    if (clean.isEmpty || _isGenericLabel(clean) || _isUuid(clean)) {
      return 'Someone';
    }
    return clean;
  }

  String get body => line();

  String line({bool arabic = false}) {
    switch (kind) {
      case FriendAlertKind.request:
        return arabic ? 'أرسل لك طلب صداقة' : requestLine;
      case FriendAlertKind.accepted:
        return arabic ? 'قبل طلب الصداقة' : acceptedLine;
    }
  }

  String get notificationKind {
    switch (kind) {
      case FriendAlertKind.request:
        return 'friend_request';
      case FriendAlertKind.accepted:
        return 'friend_accepted';
    }
  }

  /// Requests screen when it exists. Accept opens chat or profile from the peer id.
  String get href {
    switch (kind) {
      case FriendAlertKind.request:
        return 'friends';
      case FriendAlertKind.accepted:
        if (peerUserId.isNotEmpty) return 'friend-accept:$peerUserId';
        return 'friend-accept-name:${Uri.encodeComponent(title)}';
    }
  }

  String get dedupeKey {
    if (requestId.isNotEmpty) return '$notificationKind:$requestId';
    if (peerUserId.isNotEmpty) return '$notificationKind:peer:$peerUserId';
    return '$notificationKind:name:${title.toLowerCase()}';
  }
}

/// Quiet for your own action. Role is not an input.
bool shouldPresentFriendAlert({
  required String? myUserId,
  required String? actorUserId,
}) {
  if (actorUserId != null &&
      actorUserId.isNotEmpty &&
      myUserId != null &&
      actorUserId == myUserId) {
    return false;
  }
  return true;
}

/// Realtime inbox row → banner. Null when it is not a friend event or it is yours.
FriendAlert? friendAlertFromNotification(
  Map<String, dynamic> note, {
  required String? myUserId,
}) {
  final kindRaw = (note['kind'] ?? note['type'])?.toString() ?? '';
  final kind = _kindFromWire(kindRaw);
  if (kind == null) return null;
  final dataRaw = note['data'];
  final data = dataRaw is Map
      ? Map<String, dynamic>.from(dataRaw)
      : <String, dynamic>{};
  final actorId = data['fromUserId']?.toString();
  if (!shouldPresentFriendAlert(myUserId: myUserId, actorUserId: actorId)) {
    return null;
  }
  final peer = (data['peerUserId'] ?? data['fromUserId'])?.toString().trim() ??
      '';
  final requestId = data['requestId']?.toString().trim() ?? '';
  final name = friendPersonName(
    explicit: data['fromName']?.toString(),
    title: note['title']?.toString(),
    body: note['body']?.toString(),
  );
  return FriendAlert(
    kind: kind,
    requestId: requestId,
    peerUserId: peer,
    name: name,
  );
}

/// Prefer a real name. Generic titles and raw ids stay off the banner.
String friendPersonName({String? explicit, String? title, String? body}) {
  for (final candidate in [explicit, title, _nameFromBody(body)]) {
    final clean = candidate?.trim() ?? '';
    if (clean.isEmpty || _isGenericLabel(clean) || _isUuid(clean)) continue;
    return clean;
  }
  return 'Someone';
}

/// Direct thread already in the list. Does not create a chat.
String? directThreadIdForPeer({
  required List<Map<String, dynamic>> threads,
  required String peerUserId,
}) {
  if (peerUserId.isEmpty) return null;
  for (final thread in threads) {
    final kind = (thread['kind']?.toString() ?? 'direct').toLowerCase();
    if (kind != 'direct') continue;
    final id = thread['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    final parts = thread['participants'];
    if (parts is! List) continue;
    for (final part in parts) {
      if (part is! Map) continue;
      if (part['userId']?.toString() == peerUserId) return id;
    }
  }
  return null;
}

Set<String> friendIdsFromRows(List<dynamic> friends) {
  final ids = <String>{};
  for (final raw in friends) {
    if (raw is! Map) continue;
    final user = raw['user'];
    final id = user is Map ? user['id']?.toString() : raw['id']?.toString();
    if (id != null && id.isNotEmpty) ids.add(id);
  }
  return ids;
}

class _TrackedRequest {
  const _TrackedRequest({
    required this.requestId,
    required this.peerUserId,
    required this.name,
  });

  final String requestId;
  final String peerUserId;
  final String name;
}

/// Pending requests already on screen are the baseline. Later diffs alert.
class FriendAlertWatch {
  bool _ready = false;
  Map<String, _TrackedRequest> _incoming = {};
  Map<String, _TrackedRequest> _outgoing = {};

  int get pendingIncoming => _incoming.length;

  void clear() {
    _ready = false;
    _incoming = {};
    _outgoing = {};
  }

  bool needsFriendList({required List<dynamic> outgoing}) {
    if (!_ready) return false;
    final next = _index(outgoing, 'to');
    for (final id in _outgoing.keys) {
      if (!next.containsKey(id)) return true;
    }
    return false;
  }

  List<FriendAlert> apply({
    required List<dynamic> incoming,
    required List<dynamic> outgoing,
    Set<String> friendUserIds = const {},
  }) {
    final nextIn = _index(incoming, 'from');
    final nextOut = _index(outgoing, 'to');
    if (!_ready) {
      _ready = true;
      _incoming = nextIn;
      _outgoing = nextOut;
      return const [];
    }
    final alerts = <FriendAlert>[];
    final seenPeers = <String>{};
    for (final row in nextIn.values) {
      if (_incoming.containsKey(row.requestId)) continue;
      if (!seenPeers.add(row.peerUserId)) continue;
      alerts.add(
        FriendAlert(
          kind: FriendAlertKind.request,
          requestId: row.requestId,
          peerUserId: row.peerUserId,
          name: row.name,
        ),
      );
    }
    for (final prev in _outgoing.values) {
      if (nextOut.containsKey(prev.requestId)) continue;
      if (!friendUserIds.contains(prev.peerUserId)) continue;
      alerts.add(
        FriendAlert(
          kind: FriendAlertKind.accepted,
          requestId: prev.requestId,
          peerUserId: prev.peerUserId,
          name: prev.name,
        ),
      );
    }
    _incoming = nextIn;
    _outgoing = nextOut;
    return alerts;
  }

  Map<String, _TrackedRequest> _index(List<dynamic> rows, String personKey) {
    final out = <String, _TrackedRequest>{};
    for (final raw in rows) {
      if (raw is! Map) continue;
      final requestId = raw['id']?.toString() ?? '';
      final person = raw[personKey];
      if (requestId.isEmpty || person is! Map) continue;
      final peerId = person['id']?.toString() ?? '';
      if (peerId.isEmpty) continue;
      out[requestId] = _TrackedRequest(
        requestId: requestId,
        peerUserId: peerId,
        name: friendPersonName(explicit: person['name']?.toString()),
      );
    }
    return out;
  }
}

FriendAlertKind? _kindFromWire(String raw) {
  switch (raw) {
    case 'friend_request':
      return FriendAlertKind.request;
    case 'friend_accepted':
      return FriendAlertKind.accepted;
    default:
      return null;
  }
}

const Set<String> _genericLabels = {
  'someone',
  'obic',
  'friend request',
  'friend request accepted',
};

bool _isGenericLabel(String value) =>
    _genericLabels.contains(value.trim().toLowerCase());

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _isUuid(String value) => _uuidPattern.hasMatch(value.trim());

String? _nameFromBody(String? body) {
  final text = body?.trim() ?? '';
  if (text.isEmpty) return null;
  const suffixes = <String>[
    ' sent you a friend request',
    ' accepted your friend request',
  ];
  final lower = text.toLowerCase();
  for (final suffix in suffixes) {
    if (!lower.endsWith(suffix)) continue;
    final name = text.substring(0, text.length - suffix.length).trim();
    if (name.isNotEmpty) return name;
  }
  final colon = text.indexOf(': ');
  if (colon > 0) return text.substring(0, colon).trim();
  return null;
}
