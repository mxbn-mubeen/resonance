import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_screen.dart';
import '../../widgets/song_tile.dart';
import '../group_detail_screen.dart';

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

class ArtistsTab extends StatelessWidget {
  final List<String> artistKeys;
  final Map<String, List<Song>> artists;

  const ArtistsTab({super.key, required this.artistKeys, required this.artists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: artistKeys.length,
      itemBuilder: (context, index) {
        final artist = artistKeys[index];
        final artistSongs = artists[artist]!;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: artistSongs
                    .firstWhere((s) => s.artworkPath != null,
                        orElse: () => artistSongs.first)
                    .artworkPath !=
                null
                ? FileImage(File(artistSongs
                    .firstWhere((s) => s.artworkPath != null,
                        orElse: () => artistSongs.first)
                    .artworkPath!))
                : null,
            child: artistSongs.every((s) => s.artworkPath == null)
                ? Text(
                    artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${artistSongs.length} songs'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  title: artist.isNotEmpty ? artist : 'Unknown Artist',
                  subtitle: '${artistSongs.length} songs',
                  songs: artistSongs,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AlbumsTab extends StatelessWidget {
  final List<String> albumKeys;
  final Map<String, List<Song>> albums;

  const AlbumsTab({super.key, required this.albumKeys, required this.albums});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: albumKeys.length,
      itemBuilder: (context, index) {
        final album = albumKeys[index];
        final albumSongs = albums[album]!;
        final coverSong = albumSongs.first;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: coverSong.artworkPath != null
                ? Image.file(
                    File(coverSong.artworkPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.album,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
          title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${coverSong.artist ?? "Unknown Artist"} · ${albumSongs.length} songs',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  title: album,
                  subtitle: '${coverSong.artist ?? "Unknown Artist"} • ${albumSongs.length} songs',
                  songs: albumSongs,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FoldersTab extends StatelessWidget {
  final List<String> folderPaths;
  final Map<String, List<Song>> folders;

  const FoldersTab({super.key, required this.folderPaths, required this.folders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: folderPaths.length,
      itemBuilder: (context, index) {
        final dir = folderPaths[index];
        final dirSongs = folders[dir]!;
        final folderName = dir.split(Platform.pathSeparator).last;
        return ListTile(
          leading: const Icon(Icons.folder_rounded),
          title: Text(folderName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${dirSongs.length} songs'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  title: folderName,
                  subtitle: '${dirSongs.length} songs',
                  songs: dirSongs,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
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
