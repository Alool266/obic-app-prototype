// Made by Dr Ali
// WeChat Moments 置顶 — pinned post ids live on this phone, newest pin first.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMomentPins = 'obic_moment_pins_v1';

/// At most nine pins, matching the album Pin row.
const kMomentPinLimit = 9;

class MomentPinStore extends ChangeNotifier {
  MomentPinStore._();
  static final MomentPinStore instance = MomentPinStore._();

  List<String> _ids = [];
  bool _loaded = false;

  List<String> get ids => List.unmodifiable(_ids);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _ids = prefs.getStringList(_kMomentPins) ?? [];
    _loaded = true;
  }

  bool isPinned(String? id) => id != null && id.isNotEmpty && _ids.contains(id);

  /// Posts in pin order. Unknown ids are dropped.
  List<Map<String, dynamic>> pinnedFrom(List<Map<String, dynamic>> moments) {
    final byId = <String, Map<String, dynamic>>{};
    for (final m in moments) {
      final id = m['id'] as String?;
      if (id != null && id.isNotEmpty) byId[id] = m;
    }
    return [
      for (final id in _ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> pin(String id) async {
    if (id.isEmpty) return;
    await ensureLoaded();
    _ids = [id, ..._ids.where((e) => e != id)];
    if (_ids.length > kMomentPinLimit) {
      _ids = _ids.sublist(0, kMomentPinLimit);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> unpin(String id) async {
    if (id.isEmpty) return;
    await ensureLoaded();
    if (!_ids.contains(id)) return;
    _ids = _ids.where((e) => e != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kMomentPins, _ids);
  }
}
