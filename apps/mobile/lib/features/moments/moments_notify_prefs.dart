// Made by Dr Ali
// Moments notification prefs — server-backed with local cache + one-time migrate.

import 'package:shared_preferences/shared_preferences.dart';

import '../social/social_api.dart';

const _kMomentsNotifyEnabled = 'obic_moments_notify_enabled';
const _kMomentsMuteUpdates = 'obic_moments_mute_updates';
const _kMomentsMutedFriends = 'obic_moments_muted_friends';
const _kMomentsHiddenFrom = 'obic_moments_hidden_from_friends';
const _kMomentsPrefsMigrated = 'obic_moments_prefs_migrated_v1';

class MomentsNotifySnapshot {
  const MomentsNotifySnapshot({
    required this.notifyEnabled,
    required this.muteUpdates,
    this.mutedFriendIds = const [],
    this.hiddenFromFriendIds = const [],
  });

  final bool notifyEnabled;
  final bool muteUpdates;
  final List<String> mutedFriendIds;
  final List<String> hiddenFromFriendIds;

  bool get shouldShowBadge => notifyEnabled && !muteUpdates;
}

class MomentsNotifyPrefs {
  static MomentsNotifySnapshot? _memory;

  static Future<bool> notifyEnabled() async {
    final s = await _cached();
    return s.notifyEnabled;
  }

  static Future<void> setNotifyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMomentsNotifyEnabled, value);
    if (value) await prefs.setBool(_kMomentsMuteUpdates, false);
    _memory = MomentsNotifySnapshot(
      notifyEnabled: value,
      muteUpdates: value ? false : true,
      mutedFriendIds: _memory?.mutedFriendIds ?? await _localMutedFriends(),
      hiddenFromFriendIds:
          _memory?.hiddenFromFriendIds ?? await _localHiddenFrom(),
    );
  }

  static Future<bool> muteUpdates() async {
    final s = await _cached();
    return s.muteUpdates;
  }

  static Future<void> setMuteUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMomentsMuteUpdates, value);
    await prefs.setBool(_kMomentsNotifyEnabled, !value);
    _memory = MomentsNotifySnapshot(
      notifyEnabled: !value,
      muteUpdates: value,
      mutedFriendIds: _memory?.mutedFriendIds ?? await _localMutedFriends(),
      hiddenFromFriendIds:
          _memory?.hiddenFromFriendIds ?? await _localHiddenFrom(),
    );
  }

  static Future<List<String>> mutedFriendIds() async {
    final s = await _cached();
    return s.mutedFriendIds;
  }

  static Future<List<String>> hiddenFromFriendIds() async {
    final s = await _cached();
    return s.hiddenFromFriendIds;
  }

  static Future<bool> isFriendMuted(String friendId) async {
    if (friendId.isEmpty) return false;
    final ids = await mutedFriendIds();
    return ids.contains(friendId);
  }

  static Future<bool> shouldShowMomentsBadge() async {
    final s = await _cached();
    return s.shouldShowBadge;
  }

  /// Pull server prefs; migrate local once if server still at defaults.
  static Future<MomentsNotifySnapshot> syncFromServer({
    required String accessToken,
    SocialApi? api,
  }) async {
    final client = api ?? SocialApi();
    final remote = await client.getMomentNotifyPrefs(accessToken);
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_kMomentsPrefsMigrated) ?? false;

    var notify = remote['notifyEnabled'] != false;
    var mute = remote['muteUpdates'] == true;
    var mutedIds = _parseIds(remote['mutedFriendIds']);
    var hiddenIds = _parseIds(remote['hiddenFromFriendIds']);

    if (!migrated) {
      final localNotify = prefs.getBool(_kMomentsNotifyEnabled);
      final localMute = prefs.getBool(_kMomentsMuteUpdates);
      final localMuted = await _localMutedFriends();
      final localChanged = localNotify != null ||
          localMute != null ||
          localMuted.isNotEmpty;
      final serverDefault = notify && !mute && mutedIds.isEmpty;
      if (localChanged && serverDefault) {
        notify = localNotify ?? true;
        mute = localMute ?? false;
        if (mute) notify = false;
        if (!mute && (localNotify ?? true)) notify = true;
        mutedIds = localMuted;
        await client.updateMomentNotifyPrefs(
          accessToken: accessToken,
          notifyEnabled: notify,
          muteUpdates: mute,
          mutedFriendIds: mutedIds,
        );
      }
      await prefs.setBool(_kMomentsPrefsMigrated, true);
    }

    await prefs.setBool(_kMomentsNotifyEnabled, notify);
    await prefs.setBool(_kMomentsMuteUpdates, mute);
    await prefs.setStringList(_kMomentsMutedFriends, mutedIds);
    await prefs.setStringList(_kMomentsHiddenFrom, hiddenIds);
    final snap = MomentsNotifySnapshot(
      notifyEnabled: notify,
      muteUpdates: mute,
      mutedFriendIds: mutedIds,
      hiddenFromFriendIds: hiddenIds,
    );
    _memory = snap;
    return snap;
  }

  static Future<MomentsNotifySnapshot> pushGlobal({
    required String accessToken,
    required bool notifyEnabled,
    required bool muteUpdates,
    SocialApi? api,
  }) async {
    await setNotifyEnabled(notifyEnabled);
    await setMuteUpdates(muteUpdates);
    final client = api ?? SocialApi();
    final remote = await client.updateMomentNotifyPrefs(
      accessToken: accessToken,
      notifyEnabled: notifyEnabled,
      muteUpdates: muteUpdates,
    );
    return _applyRemote(remote);
  }

  static Future<MomentsNotifySnapshot> muteFriend({
    required String accessToken,
    required String friendId,
    SocialApi? api,
  }) async {
    final client = api ?? SocialApi();
    final remote = await client.muteMomentFriend(
      accessToken: accessToken,
      friendId: friendId,
    );
    return _applyRemote(remote);
  }

  static Future<MomentsNotifySnapshot> unmuteFriend({
    required String accessToken,
    required String friendId,
    SocialApi? api,
  }) async {
    final client = api ?? SocialApi();
    final remote = await client.unmuteMomentFriend(
      accessToken: accessToken,
      friendId: friendId,
    );
    return _applyRemote(remote);
  }

  static Future<MomentsNotifySnapshot> hideFromFriend({
    required String accessToken,
    required String friendId,
    SocialApi? api,
  }) async {
    final client = api ?? SocialApi();
    final remote = await client.hideMomentFromFriend(
      accessToken: accessToken,
      friendId: friendId,
    );
    return _applyRemote(remote);
  }

  static Future<MomentsNotifySnapshot> unhideFromFriend({
    required String accessToken,
    required String friendId,
    SocialApi? api,
  }) async {
    final client = api ?? SocialApi();
    final remote = await client.unhideMomentFromFriend(
      accessToken: accessToken,
      friendId: friendId,
    );
    return _applyRemote(remote);
  }

  static Future<MomentsNotifySnapshot> _applyRemote(
    Map<String, dynamic> remote,
  ) async {
    final notify = remote['notifyEnabled'] != false;
    final mute = remote['muteUpdates'] == true;
    final mutedIds = _parseIds(remote['mutedFriendIds']);
    final hiddenIds = _parseIds(remote['hiddenFromFriendIds']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMomentsNotifyEnabled, notify);
    await prefs.setBool(_kMomentsMuteUpdates, mute);
    await prefs.setStringList(_kMomentsMutedFriends, mutedIds);
    await prefs.setStringList(_kMomentsHiddenFrom, hiddenIds);
    final snap = MomentsNotifySnapshot(
      notifyEnabled: notify,
      muteUpdates: mute,
      mutedFriendIds: mutedIds,
      hiddenFromFriendIds: hiddenIds,
    );
    _memory = snap;
    return snap;
  }

  static Future<MomentsNotifySnapshot> _cached() async {
    if (_memory != null) return _memory!;
    final prefs = await SharedPreferences.getInstance();
    final snap = MomentsNotifySnapshot(
      notifyEnabled: prefs.getBool(_kMomentsNotifyEnabled) ?? true,
      muteUpdates: prefs.getBool(_kMomentsMuteUpdates) ?? false,
      mutedFriendIds: prefs.getStringList(_kMomentsMutedFriends) ?? const [],
      hiddenFromFriendIds: prefs.getStringList(_kMomentsHiddenFrom) ?? const [],
    );
    _memory = snap;
    return snap;
  }

  static Future<List<String>> _localMutedFriends() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kMomentsMutedFriends) ?? const [];
  }

  static Future<List<String>> _localHiddenFrom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kMomentsHiddenFrom) ?? const [];
  }

  static List<String> _parseIds(Object? raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
