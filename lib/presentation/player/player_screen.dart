import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/playback/playback_controller.dart';
import '../../core/di/providers.dart';
import 'components/player_controls.dart';
import 'components/player_secondary_controls.dart';

/// Cinematic now-playing screen:
/// - Backdrop tint is the album art's extracted dominant/muted color
///   (ArtworkPaletteService), blurred behind the content via ImageFiltered.
/// - Album art itself sits in a 3D-tilted card (Matrix4 perspective entry +
///   rotateY/rotateX) for a bit of depth instead of a flat square.
/// - AnimatedContainer smooths the backdrop color transition between
///   tracks instead of hard-cutting.
///
/// Still bound to the same PlaybackController mediaItem/playbackState
/// streams as MiniPlayer and the OS notification - one source of truth,
/// so this screen, the mini player, and the lock-screen notification never
/// disagree about what's playing.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(playbackControllerProvider);
    final paletteService = ref.watch(artworkPaletteServiceProvider);

    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: controller.mediaItem,
        builder: (context, mediaSnapshot) {
          final item = mediaSnapshot.data;
          final artworkPath = item?.artUri?.toFilePath();

          return FutureBuilder<Color?>(
            // Cached by ArtworkPaletteService per artwork path, so this
            // only does real extraction work once per track, not per frame.
            future: paletteService.dominantColorFor(artworkPath),
            builder: (context, paletteSnapshot) {
              final backdropColor =
                  paletteSnapshot.data ?? Theme.of(context).colorScheme.primaryContainer;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                color: backdropColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred, scaled-up copy of the artwork behind
                    // everything - the "cinematic glow" backdrop.
                    if (artworkPath != null)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Opacity(
                            opacity: 0.5,
                            child: Image.file(
                              File(artworkPath),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: _PlayerContent(item: item, controller: controller, artworkPath: artworkPath),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlayerContent extends ConsumerStatefulWidget {
  final MediaItem? item;
  final PlaybackController controller;
  final String? artworkPath;

  const _PlayerContent({required this.item, required this.controller, required this.artworkPath});

  @override
  ConsumerState<_PlayerContent> createState() => _PlayerContentState();
}

class _PlayerContentState extends ConsumerState<_PlayerContent> {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: widget.controller.playbackState,
      builder: (context, stateSnapshot) {
        final playing = stateSnapshot.data?.playing ?? false;
        final position = stateSnapshot.data?.updatePosition ?? Duration.zero;
        final total = widget.item?.duration ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const Spacer(),
              Transform(
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
                      ? Image.file(File(widget.artworkPath!), fit: BoxFit.cover)
                      : const Icon(Icons.music_note, size: 72, color: Colors.white),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 48), // Spacer to balance the heart icon
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
                    child: Builder(
                      builder: (context) {
                        final allSongs = ref.watch(librarySongsProvider).valueOrNull ?? [];
                        final song = allSongs.firstWhereOrNull((s) => s.id == widget.item?.id);
                        if (song == null) return const SizedBox.shrink();

                        final isFavorite = song.favorite;
                        return IconButton(
                          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.pinkAccent : Colors.white70),
                          onPressed: () async {
                            final repo = await ref.read(libraryRepositoryProvider.future);
                            await repo.toggleFavorite(song.id, !isFavorite);
                            ref.invalidate(librarySongsProvider);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.25),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: total.inMilliseconds > 0
                      ? position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble()
                      : 0,
                  max: total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1,
                  onChanged: total.inMilliseconds > 0
                      ? (v) => widget.controller.seek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_formatDuration(total), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              // ── Transport controls ──────────────────────────────────────
              PlayerControls(
                controller: widget.controller,
                shuffleEnabled: _shuffleEnabled,
                repeatMode: _repeatMode,
                playing: playing,
                onToggleShuffle: _toggleShuffle,
                onToggleRepeat: _toggleRepeat,
              ),
              const SizedBox(height: 8),
              // ── Secondary controls ──────────────────────────────────────
              PlayerSecondaryControls(controller: widget.controller),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
