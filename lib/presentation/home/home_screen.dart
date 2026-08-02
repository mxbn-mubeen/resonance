import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/song.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(librarySongsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const _EmptyLibraryPrompt();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Your Library', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${songs.length} songs', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text('Recently added', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FutureBuilder<List<Song>>(
                future: ref.read(playlistEngineProvider).recentlyAdded(limit: 10),
                builder: (context, snapshot) {
                  final recent = snapshot.data ?? [];
                  if (recent.isEmpty) {
                    return const SizedBox(height: 76);
                  }
                  return SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final song = recent[index];
                        return SizedBox(
                          width: 64,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: song.artworkPath != null
                                    ? Image.file(File(song.artworkPath!), width: 64, height: 64, fit: BoxFit.cover)
                                    : Container(
                                        width: 64,
                                        height: 64,
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        child: Icon(Icons.music_note,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // TODO(home_screen): "Most Played" / "Night Drive" style rails
              // follow the same FutureBuilder pattern - PlaylistEngine.mostPlayed()
              // is already implemented; AI mood rails wait on RecommendationEngine.
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading library: $e')),
      ),
    );
  }
}

class _EmptyLibraryPrompt extends ConsumerWidget {
  const _EmptyLibraryPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('No music found yet', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Grant storage permission and pick folders to scan in Settings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final scanner = ref.read(scannerServiceProvider);
                final granted = await scanner.requestPermission();
                if (granted) {
                  await scanner.scan(includedFolderPaths: ref.read(includedFoldersProvider));
                }
              },
              child: const Text('Scan Now'),
            ),
          ],
        ),
      ),
    );
  }
}
