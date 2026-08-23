import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import 'components/player_content.dart';

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
                      child: PlayerContent(item: item, controller: controller, artworkPath: artworkPath),
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