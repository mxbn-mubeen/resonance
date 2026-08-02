import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(librarySongsProvider);
    final libraryRepo = ref.read(libraryRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescan',
            onPressed: () async {
              final scanner = ref.read(scannerServiceProvider);
              final result = await scanner.scan(includedFolderPaths: ref.read(includedFoldersProvider));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${result.newOrUpdated} new, ${result.updated} updated, '
                      '${result.unchanged} unchanged, ${result.deleted} removed',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: songsAsync.when(
        data: (songs) => ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongTile(
              song: song,
              onTap: () async {
                await ref.read(playbackControllerProvider).playSongs(songs, startIndex: index);
                await libraryRepo.incrementPlayCount(song.id);
              },
              onFavoriteToggle: () => libraryRepo.toggleFavorite(song.id, !song.favorite),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
