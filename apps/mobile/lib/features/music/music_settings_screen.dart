// Made by Dr Ali
// Settings that belong to the music mini app, not the OBIC app.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import 'music_downloads.dart';
import 'music_text.dart';

class MusicSettingsScreen extends StatefulWidget {
  const MusicSettingsScreen({super.key});

  @override
  State<MusicSettingsScreen> createState() => _MusicSettingsScreenState();
}

class _MusicSettingsScreenState extends State<MusicSettingsScreen> {
  int _bytes = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final bytes = await MusicDownloads.instance.sizeBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(musicText(context, 'Clear downloaded music', 'مسح الموسيقى المحمّلة', '清除已下载音乐', 'Effacer la musique')),
        content: Text(
          musicText(
            context,
            'This removes songs saved in OBIC Music. Chats, messages, and your login stay.',
            'هذا يحذف الأغاني المحفوظة في موسيقى OBIC. الدردشات والرسائل وتسجيل الدخول تبقى.',
            '这只会删除 OBIC 音乐里保存的歌曲。聊天、消息和登录都会保留。',
            'Cela retire les titres enregistrés dans OBIC Musique. Les discussions et la connexion restent.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.actionCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.actionOk)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final freed = await MusicDownloads.instance.clear();
    if (!mounted) return;
    setState(() => _bytes = 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.storageFreed(_size(freed)))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: Text(musicText(context, 'Music settings', 'إعدادات الموسيقى', '音乐设置', 'Réglages musique')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              musicText(context, 'Downloaded music', 'الموسيقى المحمّلة', '已下载音乐', 'Musique téléchargée'),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(_size(_bytes), style: const TextStyle(color: Colors.white70)),
          ),
          ListTile(
            title: Text(
              musicText(context, 'Clear downloaded music', 'مسح الموسيقى المحمّلة', '清除已下载音乐', 'Effacer la musique'),
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
            onTap: () => unawaited(_clear()),
          ),
        ],
      ),
    );
  }
}
