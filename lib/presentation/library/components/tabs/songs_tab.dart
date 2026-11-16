import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/song.dart';
import '../../../player/player_route.dart';
import '../../../widgets/song_tile.dart';

class SongsTab extends ConsumerWidget {
  final List<Song> sorted;
  final Widget sortBar;

  const SongsTab({super.key, required this.sorted, required this.sortBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        sortBar,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                '${sorted.length} tracks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Play'),
                onPressed: sorted.isEmpty
                    ? null
                    : () async {
                        await ref.read(playbackControllerProvider).playSongs(sorted);
                        if (context.mounted) {
                          Navigator.of(context).push(PlayerRoute());
                        }
                      },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('Shuffle'),
                onPressed: sorted.isEmpty
                    ? null
                    : () async {
                        await ref.read(playbackControllerProvider).playSongs(sorted, shuffle: true);
                        if (context.mounted) {
                          Navigator.of(context).push(PlayerRoute());
                        }
                      },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final song = sorted[index];
              return SongTile(
                song: song,
                onTap: () async {
                  await ref.read(playbackControllerProvider).playSongs(sorted, startIndex: index);
                  final repo = await ref.read(libraryRepositoryProvider.future);
                  await repo.incrementPlayCount(song.id);
                  if (context.mounted) {
                    Navigator.of(context).push(PlayerRoute());
                  }
                },
                onFavoriteToggle: () async {
                  final repo = await ref.read(libraryRepositoryProvider.future);
                  repo.toggleFavorite(song.id, !song.favorite);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
