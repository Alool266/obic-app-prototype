// Made by Dr Ali
// Full player for the OBIC Music mini app.

import 'dart:async';

import 'package:flutter/material.dart';

import 'music_library.dart';
import 'music_player.dart';
import 'music_text.dart';

Color musicTone(String id, {double lightness = 0.28}) {
  final hash = id.codeUnits.fold<int>(0, (sum, unit) => (sum * 33 + unit) & 0xFFFFFF);
  return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.46, lightness).toColor();
}

class MusicNowPlayingScreen extends StatelessWidget {
  const MusicNowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicPlayerController.instance,
      builder: (context, _) {
        final player = MusicPlayerController.instance;
        final track = player.current;
        final tone = musicTone(track?.id ?? 'obic');
        final deep = musicTone(track?.id ?? 'obic', lightness: 0.12);
        return Scaffold(
          backgroundColor: deep,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tone, deep, const Color(0xFF10141C)],
              ),
            ),
            child: SafeArea(
              child: track == null
                  ? _Empty(onClose: () => Navigator.of(context).maybePop())
                  : _Body(player: player, track: track),
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          ),
        ),
        const Spacer(),
        Text(
          musicText(context, 'No songs found', 'لا توجد أغاني', '没有找到歌曲', 'Aucun titre'),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.player, required this.track});

  final MusicPlayerController player;
  final MusicTrack track;

  String _clock(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final total = player.duration.inMilliseconds;
    final pos = total == 0
        ? 0.0
        : (player.position.inMilliseconds / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
            ),
          ),
          const Spacer(),
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    musicTone(track.id, lightness: 0.42),
                    const Color(0xFF1A6DFF),
                    musicTone(track.id, lightness: 0.16),
                  ],
                ),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 96),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          Slider(
            value: pos,
            activeColor: const Color(0xFF1A6DFF),
            inactiveColor: Colors.white24,
            onChanged: total == 0
                ? null
                : (value) => unawaited(
                    player.seek(Duration(milliseconds: (value * total).round())),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_clock(player.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_clock(player.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          if (player.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                musicText(
                  context,
                  'This song could not play.',
                  'تعذر تشغيل هذه الأغنية.',
                  '这首歌无法播放。',
                  'Impossible de lire ce titre.',
                ),
                style: const TextStyle(color: Color(0xFFFFB4AB)),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: player.cycleRepeat,
                icon: Icon(
                  player.repeat == MusicRepeat.one
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  color: player.repeat == MusicRepeat.off ? Colors.white54 : Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(player.previous()),
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
              ),
              IconButton(
                onPressed: () => unawaited(player.toggle()),
                icon: Icon(
                  player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 72,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(player.next()),
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
              ),
              IconButton(
                onPressed: () => player.setShuffle(!player.shuffle),
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: player.shuffle ? const Color(0xFF1A6DFF) : Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${track.source} · ${track.license}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class MusicMiniPlayer extends StatelessWidget {
  const MusicMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicPlayerController.instance,
      builder: (context, _) {
        final player = MusicPlayerController.instance;
        final track = player.current;
        if (track == null) return const SizedBox.shrink();
        return Dismissible(
          key: ValueKey(track.id),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => unawaited(player.stop()),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              final speed = details.primaryVelocity ?? 0;
              if (speed > 250) unawaited(player.stop());
            },
            child: Material(
              color: const Color(0xFF1C2333),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MusicNowPlayingScreen()),
                  );
                },
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: musicTone(track.id, lightness: 0.36),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: musicText(context, 'Close', 'إغلاق', '关闭', 'Fermer'),
                        onPressed: () => unawaited(player.stop()),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => unawaited(player.toggle()),
                        icon: Icon(
                          player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => unawaited(player.next()),
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
