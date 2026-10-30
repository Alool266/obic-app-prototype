// Made by Dr Ali
// OBIC Music mini app — Home, Search, and Library.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/script_text_field.dart';
import 'music_downloads.dart';
import 'music_library.dart';
import 'music_now_playing.dart';
import 'music_player.dart';
import 'music_settings_screen.dart';
import 'music_text.dart';

export 'music_now_playing.dart' show MusicMiniPlayer;

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _library = const MusicLibrary();
  final _player = MusicPlayerController.instance;
  int _tab = 0;
  String _text = '';
  List<MusicTrack> _catalog = kMusicSeed;
  List<MusicTrack> _results = kMusicSeed;
  List<MusicTrack> _downloads = const [];
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_player.ensureReady());
    unawaited(_refreshHome());
    unawaited(_loadDownloads());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    setState(() => _busy = true);
    final load = await _library.search(const MusicQuery());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (load.tracks.isNotEmpty) _catalog = load.tracks;
    });
  }

  Future<void> _search() async {
    final query = MusicQuery(text: _text);
    final instant = _library.instant(query);
    setState(() {
      _results = instant;
      _busy = true;
    });
    final load = await _library.search(query);
    if (!mounted || _text != query.text) return;
    setState(() {
      _busy = false;
      _results = load.tracks;
    });
  }

  Future<void> _loadDownloads() async {
    final rows = await MusicDownloads.instance.list();
    if (mounted) setState(() => _downloads = rows);
  }

  Future<void> _download(MusicTrack track) async {
    final file = await MusicDownloads.instance.download(track);
    if (!mounted) return;
    await _loadDownloads();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          file == null
              ? musicText(context, 'Could not download this song.', 'تعذر تنزيل هذه الأغنية.', '无法下载这首歌。', 'Téléchargement impossible.')
              : musicText(context, 'Saved in Music.', 'حُفظت في الموسيقى.', '已保存到音乐。', 'Enregistré dans Musique.'),
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(MusicTrack track) async {
    if (_player.playlists.isEmpty) {
      final name = await _askPlaylistName();
      if (name == null || name.trim().isEmpty) return;
      final created = await _player.createPlaylist(name.trim());
      await _player.addToPlaylist(created.id, track);
      return;
    }
    if (!mounted) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C2333),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final playlist in _player.playlists)
              ListTile(
                title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, playlist.id),
              ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF1A6DFF)),
              title: Text(
                musicText(context, 'New playlist', 'قائمة جديدة', '新建歌单', 'Nouvelle playlist'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, '__new__'),
            ),
          ],
        ),
      ),
    );
    if (id == null) return;
    if (id == '__new__') {
      final name = await _askPlaylistName();
      if (name == null || name.trim().isEmpty) return;
      final created = await _player.createPlaylist(name.trim());
      await _player.addToPlaylist(created.id, track);
      return;
    }
    await _player.addToPlaylist(id, track);
  }

  Future<String?> _askPlaylistName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(musicText(context, 'New playlist', 'قائمة جديدة', '新建歌单', 'Nouvelle playlist')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: musicText(context, 'Name', 'الاسم', '名称', 'Nom'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(musicText(context, 'Cancel', 'إلغاء', '取消', 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(musicText(context, 'Create', 'إنشاء', '创建', 'Créer')),
          ),
        ],
      ),
    );
  }

  void _play(List<MusicTrack> tracks, int index) {
    unawaited(_player.playQueue(tracks, index));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MusicNowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // App light/dark, read before this screen forces a dark Theme.
    final Color barInk = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF0B1B3F);
    final ButtonStyle barIconStyle = ButtonStyle(
      iconColor: WidgetStatePropertyAll<Color>(barInk),
      foregroundColor: WidgetStatePropertyAll<Color>(barInk),
    );
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final bool showLeading = route?.impliesAppBarDismissal ?? false;
    Widget? leading;
    if (showLeading) {
      leading = (route?.fullscreenDialog ?? false)
          ? CloseButton(style: barIconStyle)
          : BackButton(style: barIconStyle);
    }
    final theme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1A6DFF),
        surface: Color(0xFF1C2333),
        onSurface: Colors.white,
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: barInk,
        automaticallyImplyLeading: false,
        leading: leading,
        title: Text(
          musicText(context, 'OBIC Music', 'موسيقى OBIC', 'OBIC 音乐', 'OBIC Musique'),
          style: TextStyle(color: barInk),
        ),
        actions: [
          IconButton(
            style: barIconStyle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MusicSettingsScreen()),
              );
            },
            icon: Icon(Icons.settings_outlined, color: barInk),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _page()),
          const MusicMiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1C2333),
        indicatorColor: const Color(0xFF1A6DFF).withValues(alpha: 0.35),
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: musicText(context, 'Home', 'الرئيسية', '首页', 'Accueil'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: musicText(context, 'Search', 'بحث', '搜索', 'Recherche'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_rounded),
            label: musicText(context, 'Library', 'المكتبة', '资料库', 'Bibliothèque'),
          ),
        ],
      ),
    ),
    );
  }

  Widget _page() {
    return switch (_tab) {
      0 => _home(),
      1 => _searchPage(),
      _ => _libraryPage(),
    };
  }

  Widget _home() {
    if (_catalog.isEmpty && _busy) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6DFF)));
    }
    if (_catalog.isEmpty) {
      return _empty(
        musicText(context, 'No songs found', 'لا توجد أغاني', '没有找到歌曲', 'Aucun titre'),
        () => unawaited(_refreshHome()),
      );
    }
    final featured = musicFeatured(_catalog);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF1A6DFF)),
        _row(musicText(context, 'Featured', 'مختارات', '精选', 'À la une'), featured),
        _row(musicText(context, 'Arabic', 'عربي', '阿拉伯语', 'Arabe'), _library.instant(const MusicQuery(language: 'ar'))),
        _row(musicText(context, 'English', 'إنجليزي', '英语', 'Anglais'), _library.instant(const MusicQuery(language: 'en'))),
        _row(musicText(context, 'Chinese', 'صيني', '中文', 'Chinois'), _library.instant(const MusicQuery(language: 'zh'))),
        _row(musicText(context, 'French', 'فرنسي', '法语', 'Français'), _library.instant(const MusicQuery(language: 'fr'))),
        for (final genre in const ['jazz', 'ambient', 'classical', 'folk'])
          _row(genre, _library.instant(MusicQuery(genre: genre))),
        ListenableBuilder(
          listenable: _player,
          builder: (context, _) => _row(
            musicText(context, 'Recently played', 'شُغّلت مؤخرًا', '最近播放', 'Récents'),
            _player.recent,
          ),
        ),
      ],
    );
  }

  Widget _searchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ObicScriptTextField(
            onChanged: (value) {
              _text = value;
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                unawaited(_search());
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: musicText(context, 'Search songs or artists', 'ابحث عن أغنية أو فنان', '搜索歌曲或歌手', 'Titre ou artiste'),
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1C2333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF1A6DFF)),
        Expanded(
          child: _results.isEmpty
              ? _empty(
                  musicText(context, 'No songs found', 'لا توجد أغاني', '没有找到歌曲', 'Aucun titre'),
                  () => unawaited(_search()),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) => _tile(_results, index),
                ),
        ),
      ],
    );
  }

  Widget _libraryPage() {
    return ListenableBuilder(
      listenable: _player,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _sectionTitle(musicText(context, 'Favourites', 'المفضلة', '收藏', 'Favoris')),
            if (_player.favorites.isEmpty)
              _inlineEmpty(
                musicText(context, 'No favourites yet', 'لا توجد مفضلات بعد', '还没有收藏', 'Pas encore de favoris'),
              )
            else
              for (var i = 0; i < _player.favorites.length; i++) _tile(_player.favorites, i),
            _sectionTitle(musicText(context, 'Playlists', 'قوائم التشغيل', '歌单', 'Playlists')),
            if (_player.playlists.isEmpty)
              _inlineEmpty(
                musicText(context, 'No playlists yet', 'لا توجد قوائم بعد', '还没有歌单', 'Pas encore de playlist'),
              )
            else
              for (final playlist in _player.playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded, color: Color(0xFF1A6DFF)),
                  title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${playlist.tracks.length}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: playlist.tracks.isEmpty
                      ? null
                      : () => _play(playlist.tracks, 0),
                ),
            _sectionTitle(musicText(context, 'Downloads', 'التنزيلات', '下载', 'Téléchargements')),
            if (_downloads.isEmpty)
              _inlineEmpty(
                musicText(context, 'No downloads yet', 'لا توجد تنزيلات بعد', '还没有下载', 'Pas encore de téléchargement'),
              )
            else
              for (var i = 0; i < _downloads.length; i++) _tile(_downloads, i),
          ],
        );
      },
    );
  }

  Widget _row(String title, List<MusicTrack> tracks) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length.clamp(0, 12),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return InkWell(
                onTap: () => _play(tracks, index),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              musicTone(track.id, lightness: 0.4),
                              const Color(0xFF1A6DFF),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tile(List<MusicTrack> tracks, int index) {
    final track = tracks[index];
    return ListTile(
      onTap: () => _play(tracks, index),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: musicTone(track.id, lightness: 0.34),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${track.artist} · ${track.source}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: PopupMenuButton<String>(
        color: const Color(0xFF1C2333),
        onSelected: (value) {
          switch (value) {
            case 'fav':
              unawaited(_player.toggleFavorite(track));
            case 'down':
              unawaited(_download(track));
            case 'list':
              unawaited(_addToPlaylist(track));
            default:
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'fav',
            child: Text(
              _player.isFavorite(track)
                  ? musicText(context, 'Remove favourite', 'إزالة من المفضلة', '取消收藏', 'Retirer des favoris')
                  : musicText(context, 'Favourite', 'مفضلة', '收藏', 'Favori'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          PopupMenuItem(
            value: 'down',
            child: Text(
              musicText(context, 'Download', 'تنزيل', '下载', 'Télécharger'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          PopupMenuItem(
            value: 'list',
            child: Text(
              musicText(context, 'Add to playlist', 'أضف إلى قائمة', '加入歌单', 'Ajouter à une playlist'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _inlineEmpty(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(label, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _empty(String label, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A6DFF)),
            onPressed: retry,
            child: Text(musicText(context, 'Retry', 'إعادة المحاولة', '重试', 'Réessayer')),
          ),
        ],
      ),
    );
  }
}
