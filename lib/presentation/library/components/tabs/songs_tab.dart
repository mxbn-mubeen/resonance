import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/song.dart';
import '../../../player/player_screen.dart';
import '../../../widgets/song_tile.dart';

class SongsTab extends ConsumerWidget {
  final List<Song> sorted;
  final Widget sortBar;

  const SongsTab({super.key, required this.sorted, required this.sortBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        sortBar,
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
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
