// Made by Dr Ali
// Storage — space by kind. Clear cache never deletes chats or login.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/media_disk_cache.dart';
import '../../core/offline_cache_store.dart';
import '../../theme/obic_colors.dart';
import '../music/music_downloads.dart';
import 'settings_widgets.dart';

const _keepDaysKey = 'obic_media_keep_days';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  bool _busy = false;
  int _images = 0;
  int _videos = 0;
  int _voice = 0;
  int _files = 0;
  int _music = 0;
  int _chats = 0;
  int _keepDays = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final kinds = await MediaDiskCache.instance.sizeByKind();
    final music = await MusicDownloads.instance.sizeBytes();
    final chats = await OfflineCacheStore.instance.snapshotBytes();
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt(_keepDaysKey) ?? 0;
    if (days > 0) {
      await MediaDiskCache.instance.purgeOlderThan(days);
    }
    if (!mounted) return;
    setState(() {
      _images = kinds['images'] ?? 0;
      _videos = kinds['videos'] ?? 0;
      _voice = kinds['voice'] ?? 0;
      _files = kinds['files'] ?? 0;
      _music = music;
      _chats = chats;
      _keepDays = days;
    });
  }

  String _label(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    final before = _images + _videos + _voice + _files;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.storageClearCache),
        content: Text(l10n.storageClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.storageClearCache),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await MediaDiskCache.instance.clear();
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.storageFreed(_label(before)))),
    );
  }

  Future<void> _clearMusic() async {
    final l10n = AppLocalizations.of(context);
    final before = await MusicDownloads.instance.clear();
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.storageFreed(_label(before)))),
    );
  }

  Future<void> _setDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keepDaysKey, days);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.settingsStorage),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SettingsGroup(
            children: [
              SettingsReadonlyTile(
                title: l10n.storageImages,
                value: _label(_images),
              ),
              SettingsReadonlyTile(
                title: l10n.storageVideos,
                value: _label(_videos),
              ),
              SettingsReadonlyTile(
                title: l10n.storageVoice,
                value: _label(_voice),
              ),
              SettingsReadonlyTile(
                title: l10n.storageFiles,
                value: _label(_files),
              ),
              SettingsReadonlyTile(
                title: l10n.storageMusic,
                value: _label(_music),
              ),
              SettingsReadonlyTile(
                title: l10n.storageChats,
                value: _label(_chats),
                hint: l10n.storageChatsHint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsGroup(
            children: [
              ListTile(
                dense: true,
                title: Text(l10n.storageClearCache),
                subtitle: Text(l10n.storageCacheHint),
                enabled: !_busy,
                onTap: _clearCache,
              ),
              ListTile(
                dense: true,
                title: Text(l10n.storageClearMusic),
                enabled: !_busy,
                onTap: _clearMusic,
              ),
              ListTile(
                dense: true,
                title: Text(l10n.storageAutoDelete),
                subtitle: Text(
                  _keepDays == 0
                      ? l10n.storageAutoNever
                      : l10n.storageAutoDays(_keepDays),
                ),
                onTap: () async {
                  final picked = await showModalBottomSheet<int>(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final days in [0, 7, 30, 90])
                            ListTile(
                              title: Text(
                                days == 0
                                    ? l10n.storageAutoNever
                                    : l10n.storageAutoDays(days),
                              ),
                              onTap: () => Navigator.of(context).pop(days),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (picked == null) return;
                  await _setDays(picked);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
