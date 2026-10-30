// Made by Dr Ali
// Local remark names. The API has no friendship alias column yet.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRemarkPrefix = 'obic_friend_remarks_v1_';

class FriendRemarkStore extends ChangeNotifier {
  FriendRemarkStore._();
  static final FriendRemarkStore instance = FriendRemarkStore._();

  String? _userId;
  Map<String, String> _remarks = const {};

  String? remarkFor(String friendId) {
    final value = _remarks[friendId]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> loadFor(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kRemarkPrefix$userId');
    if (raw == null || raw.isEmpty) {
      _remarks = const {};
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _remarks = {
          for (final entry in decoded.entries)
            if (entry.value is String &&
                (entry.value as String).trim().isNotEmpty)
              entry.key.toString(): (entry.value as String).trim(),
        };
      } else {
        _remarks = const {};
      }
    } catch (_) {
      _remarks = const {};
    }
    notifyListeners();
  }

  Future<void> setRemark(String friendId, String remark) async {
    final userId = _userId;
    if (friendId.isEmpty || userId == null || userId.isEmpty) return;
    final next = Map<String, String>.from(_remarks);
    final trimmed = remark.trim();
    if (trimmed.isEmpty) {
      next.remove(friendId);
    } else {
      next[friendId] = trimmed;
    }
    _remarks = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kRemarkPrefix$userId', jsonEncode(_remarks));
    notifyListeners();
  }
}
