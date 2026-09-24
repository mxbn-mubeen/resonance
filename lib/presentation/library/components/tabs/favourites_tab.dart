import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/song.dart';
import '../../../player/player_route.dart';
import '../../../widgets/song_tile.dart';

class FavouritesTab extends ConsumerWidget {
  final List<Song> songs;

  const FavouritesTab({super.key, required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = songs.where((s) => s.favorite).toList();
    if (favourites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.pink.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No favourites yet'),
            const SizedBox(height: 8),
            const Text(
              'Tap the ♥ icon on any song to add it here',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.play_circle_fill, color: Colors.pinkAccent, size: 32),
          title: Text(
            'Play all ${favourites.length} favourites',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            await ref.read(playbackControllerProvider).playSongs(favourites);
            if (context.mounted) {
              Navigator.of(context).push(PlayerRoute());
            }
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final song = favourites[index];
              return SongTile(
                song: song,
                onTap: () async {
                  await ref.read(playbackControllerProvider).playSongs(favourites, startIndex: index);
                  if (context.mounted) {
                    Navigator.of(context).push(PlayerRoute());
                  }
                  final repo = await ref.read(libraryRepositoryProvider.future);
                  await repo.incrementPlayCount(song.id);
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
