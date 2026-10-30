// Made by Dr Ali
// WeChat-style call history body in DM threads (persist via chat message).

/// Call media mode.
enum ObicCallRecordMode { voice, video }

/// Outcome persisted after a ring / connected call.
enum ObicCallRecordOutcome {
  /// Both sides connected; [durationSeconds] is set.
  ended,
  /// Caller hung up before answer.
  cancelled,
  /// Callee tapped Decline.
  declined,
  /// Rang out / expired with no answer.
  missed,
}

/// Which person wrote this log line.
enum ObicCallRecordSide { outgoing, incoming }

class ObicCallRecord {
  const ObicCallRecord({
    required this.mode,
    required this.outcome,
    this.durationSeconds = 0,
    this.endedByUserId,
    this.side,
    this.people = 0,
  });

  final ObicCallRecordMode mode;
  final ObicCallRecordOutcome outcome;
  final int durationSeconds;
  final String? endedByUserId;
  final int people;

  /// `outgoing` when the sender placed the call. `incoming` when they received it.
  final ObicCallRecordSide? side;

  bool get isVideo => mode == ObicCallRecordMode.video;
}

const String kObicCallBodyPrefix = '[[obic:call:v1]]';

/// Build a machine+human chat body both clients can parse.
String buildCallRecordBody(ObicCallRecord record) {
  final mode = record.isVideo ? 'video' : 'voice';
  final outcome = switch (record.outcome) {
    ObicCallRecordOutcome.ended => 'ended',
    ObicCallRecordOutcome.cancelled => 'cancelled',
    ObicCallRecordOutcome.declined => 'declined',
    ObicCallRecordOutcome.missed => 'missed',
  };
  final lines = <String>[
    kObicCallBodyPrefix,
    'mode=$mode',
    'outcome=$outcome',
    'duration=${record.durationSeconds.clamp(0, 86400)}',
  ];
  final endedBy = record.endedByUserId?.trim();
  if (endedBy != null && endedBy.isNotEmpty) {
    lines.add('endedBy=$endedBy');
  }
  switch (record.side) {
    case ObicCallRecordSide.outgoing:
      lines.add('side=out');
    case ObicCallRecordSide.incoming:
      lines.add('side=in');
    case null:
      break;
  }
  if (record.people > 0) {
    lines.add('people=${record.people.clamp(0, 16)}');
  }
  // Human fallback for older clients / notifications preview.
  final human = _fallbackPreview(record);
  lines.add('');
  lines.add(human);
  return lines.join('\n');
}

ObicCallRecord? parseCallRecordBody(String body) {
  final text = body.trim();
  if (!text.contains(kObicCallBodyPrefix) && !text.startsWith('[[obic:call:')) {
    return null;
  }
  String? mode;
  String? outcome;
  var duration = 0;
  String? endedBy;
  ObicCallRecordSide? side;
  var people = 0;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('mode=')) mode = line.substring(5).trim();
    if (line.startsWith('outcome=')) outcome = line.substring(8).trim();
    if (line.startsWith('duration=')) {
      duration = int.tryParse(line.substring(9).trim()) ?? 0;
    }
    if (line.startsWith('endedBy=')) endedBy = line.substring(8).trim();
    if (line.startsWith('people=')) {
      people = int.tryParse(line.substring(7).trim()) ?? 0;
    }
    if (line.startsWith('side=')) {
      side = switch (line.substring(5).trim()) {
        'out' => ObicCallRecordSide.outgoing,
        'in' => ObicCallRecordSide.incoming,
        _ => null,
      };
    }
  }
  if (outcome == null || outcome.isEmpty) return null;
  final o = switch (outcome) {
    'ended' => ObicCallRecordOutcome.ended,
    'cancelled' => ObicCallRecordOutcome.cancelled,
    'declined' => ObicCallRecordOutcome.declined,
    'missed' => ObicCallRecordOutcome.missed,
    _ => null,
  };
  if (o == null) return null;
  return ObicCallRecord(
    mode: mode == 'video' ? ObicCallRecordMode.video : ObicCallRecordMode.voice,
    outcome: o,
    durationSeconds: duration < 0 ? 0 : duration,
    endedByUserId: endedBy,
    side: side,
    people: people < 0 ? 0 : people,
  );
}

/// True when the person looking at the log is the one who placed the call.
bool callRecordPlacedByViewer(
  ObicCallRecord record, {
  required bool mine,
}) {
  switch (record.side) {
    case ObicCallRecordSide.outgoing:
      return mine;
    case ObicCallRecordSide.incoming:
      return !mine;
    case null:
      switch (record.outcome) {
        case ObicCallRecordOutcome.declined:
        case ObicCallRecordOutcome.missed:
          return !mine;
        case ObicCallRecordOutcome.ended:
        case ObicCallRecordOutcome.cancelled:
          return mine;
      }
  }
}

/// True only after both sides joined and there is talk time to show.
bool callRecordConnected(ObicCallRecord record) {
  return record.outcome == ObicCallRecordOutcome.ended &&
      record.durationSeconds > 0;
}

String formatCallDuration(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

/// WeChat-like label for the bubble (depends on whether I started / ended).
String callRecordLabel(
  ObicCallRecord record, {
  required bool arabic,
  required bool mine,
  String? myUserId,
  String? lang,
}) {
  final code = lang ?? (arabic ? 'ar' : 'en');
  final video = record.isVideo;
  final type = switch (code) {
    'ar' => video ? 'مكالمة فيديو' : 'مكالمة صوتية',
    'zh' => video ? '视频通话' : '语音通话',
    _ => video ? 'Video call' : 'Voice call',
  };
  final people = record.people > 1 ? ' · ${record.people}' : '';

  if (callRecordConnected(record)) {
    final dur = formatCallDuration(record.durationSeconds);
    return '$type $dur$people';
  }
  // Outgoing history is "no answer". Incoming history is "missed".
  if (callRecordPlacedByViewer(record, mine: mine)) {
    return switch (code) {
      'ar' => 'لم يتم الرد',
      'zh' => '无人接听',
      _ => 'No answer',
    };
  }
  return switch (code) {
    'ar' => video ? 'مكالمة فيديو فائتة' : 'مكالمة فائتة',
    'zh' => video ? '未接视频通话' : '未接语音通话',
    _ => video ? 'Missed video call' : 'Missed voice call',
  };
}

String _fallbackPreview(ObicCallRecord record) {
  final video = record.isVideo;
  switch (record.outcome) {
    case ObicCallRecordOutcome.ended:
      if (record.durationSeconds > 0) {
        return '${video ? 'Video' : 'Voice'} call ${formatCallDuration(record.durationSeconds)}';
      }
      return 'No answer';
    case ObicCallRecordOutcome.cancelled:
      return 'Cancelled';
    case ObicCallRecordOutcome.declined:
      return video ? 'Missed video call' : 'Missed voice call';
    case ObicCallRecordOutcome.missed:
      return video ? 'Missed video call' : 'Missed voice call';
  }
}
