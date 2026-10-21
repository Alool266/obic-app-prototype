// Made by Dr Ali
// Client-side cache for WeChat-style message translations (per message id + locale).

class TranslationCache {
  TranslationCache._();
  static final TranslationCache instance = TranslationCache._();

  static const _maxEntries = 300;

  /// key → translation text
  final Map<String, String> _store = {};

  String key(String messageId, String targetLocale) =>
      '$messageId|$targetLocale';

  String? get(String messageId, String targetLocale) {
    if (messageId.isEmpty) return null;
    return _store[key(messageId, targetLocale)];
  }

  void put(String messageId, String targetLocale, String translation) {
    if (messageId.isEmpty) return;
    if (_store.length >= _maxEntries) {
      final drop = (_maxEntries * 0.2).ceil().clamp(1, _maxEntries);
      final keys = _store.keys.take(drop).toList();
      for (final k in keys) {
        _store.remove(k);
      }
    }
    _store[key(messageId, targetLocale)] = translation;
  }

  void clear() => _store.clear();
}
