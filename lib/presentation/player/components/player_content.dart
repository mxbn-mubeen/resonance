import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../../application/playback/playback_controller.dart';
import '../../../../core/di/providers.dart';
import 'player_dynamic_section.dart';
import 'player_secondary_controls.dart';

/// Layout:
///   [static]  — back arrow, artwork card, title/artist, heart — only rebuilds
///               when MediaItem changes (track change), NOT on pause/seek.
///   [dynamic] — slider + time labels + transport controls — rebuilt by
///               StreamBuilder<PlaybackState> + StreamBuilder<Duration>
///               which fires every second / on pause.
///
/// Splitting these two sections eliminates the full-screen repaint that
/// previously happened on every pause button press or position tick.
class PlayerContent extends ConsumerStatefulWidget {
  final MediaItem? item;
  final PlaybackController controller;
  final String? artworkPath;

  const PlayerContent({super.key, required this.item, required this.controller, required this.artworkPath});

  @override
  ConsumerState<PlayerContent> createState() => _PlayerContentState();
}

class _PlayerContentState extends ConsumerState<PlayerContent> {
  bool _shuffleEnabled = false;
  int _repeatMode = 0;

  void _toggleShuffle() {
    final next = !_shuffleEnabled;
    setState(() => _shuffleEnabled = next);
    widget.controller.setShuffleEnabled(next);
  }

  void _toggleRepeat() {
    final next = (_repeatMode + 1) % 3;
    setState(() => _repeatMode = next);
    final mode = [AudioServiceRepeatMode.none, AudioServiceRepeatMode.all, AudioServiceRepeatMode.one][next];
    widget.controller.setRepeatMode(mode);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Static: look up song once (changes only on track change, not on pause)
    final allSongs = ref.watch(librarySongsProvider).valueOrNull ?? [];
    final song = allSongs.firstWhereOrNull((s) => s.id == widget.item?.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        children: [
          // ── Back arrow ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const Spacer(),

          // ── Artwork card (RepaintBoundary = never repaints on pause/seek) ──
          RepaintBoundary(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-0.18)
                ..rotateX(0.05),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.12),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.artworkPath != null
                    ? Image.file(File(widget.artworkPath!), fit: BoxFit.cover, gaplessPlayback: true)
                    : const Icon(Icons.music_note, size: 72, color: Colors.white),
              ),
            ),
          ),
          const Spacer(),

          // ── Title + artist + heart ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.item?.title ?? 'Nothing playing',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item?.artist ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: song == null
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: Icon(song.favorite ? Icons.favorite : Icons.favorite_border,
                            color: song.favorite ? Colors.pinkAccent : Colors.white70),
                        onPressed: () async {
                          final repo = await ref.read(libraryRepositoryProvider.future);
                          await repo.toggleFavorite(song.id, !song.favorite);
                          ref.invalidate(librarySongsProvider);
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── DYNAMIC: Slider + labels + transport controls ───────────────
          // Only THIS section rebuilds on pause / position tick.
          PlayerDynamicSection(
            controller: widget.controller,
            item: widget.item,
            shuffleEnabled: _shuffleEnabled,
            repeatMode: _repeatMode,
            onToggleShuffle: _toggleShuffle,
            onToggleRepeat: _toggleRepeat,
            formatDuration: _formatDuration,
          ),
          const SizedBox(height: 8),

          // ── Secondary controls (queue, speed, sleep, EQ) ───────────────
          PlayerSecondaryControls(controller: widget.controller, song: song, artworkPath: widget.artworkPath),
        ],
      ),
    );
  }
}

