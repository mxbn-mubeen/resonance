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
  final Color? accentColor;

  const PlayerContent({
    super.key,
    required this.item,
    required this.controller,
    required this.artworkPath,
    this.accentColor,
  });

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

    final glowColor = widget.accentColor ?? Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
      child: Column(
        children: [
          // ── Back arrow ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          const Spacer(),

          // ── Artwork card with radiant ambient glow shadow ─────────────
          RepaintBoundary(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 42,
                    spreadRadius: 6,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: widget.artworkPath != null
                      ? Image.file(
                          File(widget.artworkPath!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: const Color(0xFF1E212B),
                          child: const Icon(Icons.music_note_rounded, size: 84, color: Colors.white60),
                        ),
                ),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item?.artist ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w400,
                      ),
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
                        icon: Icon(
                          song.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: song.favorite ? Colors.pinkAccent : Colors.white70,
                          size: 26,
                        ),
                        onPressed: () async {
                          final repo = await ref.read(libraryRepositoryProvider.future);
                          await repo.toggleFavorite(song.id, !song.favorite);
                          ref.invalidate(librarySongsProvider);
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── DYNAMIC: Slider + labels + transport controls ───────────────
          PlayerDynamicSection(
            controller: widget.controller,
            item: widget.item,
            shuffleEnabled: _shuffleEnabled,
            repeatMode: _repeatMode,
            onToggleShuffle: _toggleShuffle,
            onToggleRepeat: _toggleRepeat,
            formatDuration: _formatDuration,
            accentColor: widget.accentColor,
          ),
          const SizedBox(height: 8),

          // ── Secondary controls (queue, speed, sleep, EQ) ───────────────
          PlayerSecondaryControls(controller: widget.controller, song: song, artworkPath: widget.artworkPath),
        ],
      ),
    );
  }
}

