import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../core/di/providers.dart';
import '../player/player_route.dart';
import 'mini_progress_bar.dart';

/// Immersive glassmorphic floating mini-player.
///
/// Bound to the same PlaybackController streams as PlayerScreen and the OS
/// notification — all three always agree on what's playing.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(playbackControllerProvider);
    final allSongs = ref.watch(librarySongsProvider).valueOrNull ?? [];

    return StreamBuilder<MediaItem?>(
      stream: controller.mediaItem,
      builder: (context, mediaSnapshot) {
        final item = mediaSnapshot.data;
        if (item == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: controller.playbackState,
          builder: (context, stateSnapshot) {
            final playing = stateSnapshot.data?.playing ?? false;
            final song = allSongs.firstWhereOrNull((s) => s.id == item.id);
            final isFavorite = song?.favorite ?? false;

            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF16181F).withValues(alpha: 0.85)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (ModalRoute.of(context) is! PlayerRoute) {
                            Navigator.of(context).push(PlayerRoute());
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  // Artwork with rounded corners and border
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: item.artUri != null
                                          ? Image.file(
                                              File(item.artUri!.toFilePath()),
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            )
                                          : Icon(
                                              Icons.music_note_rounded,
                                              size: 22,
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title + Artist
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.artist ?? 'Unknown Artist',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75) ??
                                                Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Favourite button
                                  if (song != null)
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        size: 22,
                                        color: isFavorite ? Colors.pinkAccent : Colors.white60,
                                      ),
                                      onPressed: () async {
                                        final repo = await ref.read(libraryRepositoryProvider.future);
                                        await repo.toggleFavorite(song.id, !isFavorite);
                                        ref.invalidate(librarySongsProvider);
                                      },
                                    ),

                                  // Play / Pause in a sleek circular button
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                                      shape: const CircleBorder(),
                                    ),
                                    icon: Icon(
                                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                    onPressed: playing ? controller.pause : controller.play,
                                  ),
                                ],
                              ),
                            ),

                            // Pinned Slim Progress Bar along the bottom
                            MiniProgressBar(
                              controller: controller,
                              totalDuration: item.duration ?? Duration.zero,
                              accentColor: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
