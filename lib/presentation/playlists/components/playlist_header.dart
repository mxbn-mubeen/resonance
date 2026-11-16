import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/library_entities.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_route.dart';
import '../../widgets/playlist_cover_widget.dart';

class PlaylistHeader extends ConsumerWidget {
  final PlaylistEntity playlist;
  final List<Song> songs;

  const PlaylistHeader({super.key, required this.playlist, required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: PlaylistCoverWidget(songIds: playlist.songIds, size: 96),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${songs.length} track${songs.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Play all', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: songs.isEmpty
                      ? null
                      : () async {
                          await ref.read(playbackControllerProvider).playSongs(songs);
                          if (context.mounted) {
                            Navigator.of(context).push(PlayerRoute());
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: songs.isEmpty
                      ? null
                      : () async {
                          await ref.read(playbackControllerProvider).playSongs(songs, shuffle: true);
                          if (context.mounted) {
                            Navigator.of(context).push(PlayerRoute());
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
