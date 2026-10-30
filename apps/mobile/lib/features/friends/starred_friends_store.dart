// Made by Dr Ali
// Starred contacts live on this phone, per signed-in user.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kStarredPrefix = 'obic_starred_friends_v1_';

class StarredFriendsStore extends ChangeNotifier {
  StarredFriendsStore._();
  static final StarredFriendsStore instance = StarredFriendsStore._();

  String? _userId;
  List<String> _ids = const [];

  List<String> get ids => _ids;

  bool isStarred(String id) => id.isNotEmpty && _ids.contains(id);

  Future<void> loadFor(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _ids = List<String>.from(
      prefs.getStringList('$_kStarredPrefix$userId') ?? const <String>[],
    );
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final userId = _userId;
    if (id.isEmpty || userId == null || userId.isEmpty) return;
    if (_ids.contains(id)) {
      _ids = _ids.where((e) => e != id).toList();
    } else {
      _ids = [id, ..._ids.where((e) => e != id)];
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_kStarredPrefix$userId', _ids);
    notifyListeners();
  }
}
