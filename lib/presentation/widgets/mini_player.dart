import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../player/player_screen.dart';

/// Bound to the same PlaybackController streams as PlayerScreen and the OS
/// notification - all three always agree on what's playing.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(playbackControllerProvider);

    return StreamBuilder<MediaItem?>(
      stream: controller.mediaItem,
      builder: (context, mediaSnapshot) {
        final item = mediaSnapshot.data;
        return StreamBuilder<PlaybackState>(
          stream: controller.playbackState,
          builder: (context, stateSnapshot) {
            final playing = stateSnapshot.data?.playing ?? false;

            return Material(
              color: theme.colorScheme.surfaceContainer,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item?.artUri != null
                            ? Image.file(File(item!.artUri!.toFilePath()), width: 36, height: 36, fit: BoxFit.cover)
                            : Container(
                                width: 36,
                                height: 36,
                                color: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.music_note, size: 18, color: theme.colorScheme.onPrimaryContainer),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item?.title ?? 'Nothing playing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: item == null ? null : (playing ? controller.pause : controller.play),
                      ),
                      const SizedBox(width: 4),
                    ],
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
