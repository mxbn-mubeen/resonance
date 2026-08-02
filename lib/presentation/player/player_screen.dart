import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/playback/playback_controller.dart';
import '../../core/di/providers.dart';
import '../equalizer/equalizer_screen.dart';

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

class _PlayerContent extends StatelessWidget {
  final MediaItem? item;
  final PlaybackController controller;
  final String? artworkPath;

  const _PlayerContent({required this.item, required this.controller, required this.artworkPath});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: controller.playbackState,
      builder: (context, stateSnapshot) {
        final playing = stateSnapshot.data?.playing ?? false;
        final position = stateSnapshot.data?.updatePosition ?? Duration.zero;
        final total = item?.duration ?? Duration.zero;

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
              // 3D-tilted album art card - a Matrix4 with a small
              // perspective entry (row 3, col 2) plus Y/X rotation. Flat
              // CSS-style "transform: rotateY()" doesn't exist in Flutter;
              // the 0.0015 perspective term is what makes the rotation
              // read as depth instead of a sheared rectangle.
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
                  child: artworkPath != null
                      ? Image.file(File(artworkPath!), fit: BoxFit.cover)
                      : const Icon(Icons.music_note, size: 72, color: Colors.white),
                ),
              ),
              const Spacer(),
              Text(
                item?.title ?? 'Nothing playing',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item?.artist ?? '',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                textAlign: TextAlign.center,
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
                      ? (v) => controller.seek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.white70),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: controller.skipToPrevious,
                  ),
                  IconButton(
                    iconSize: 56,
                    icon: Icon(
                      playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                    ),
                    onPressed: playing ? controller.pause : controller.play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: controller.skipToNext,
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.speed, color: Colors.white70, size: 18),
                    label: const Text('Speed', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bedtime, color: Colors.white70, size: 18),
                    label: const Text('Sleep timer', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                    ),
                    icon: const Icon(Icons.equalizer, color: Colors.white70, size: 18),
                    label: const Text('Equalizer', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
