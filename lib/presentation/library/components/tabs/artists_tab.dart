import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../domain/entities/song.dart';
import '../../group_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';

class ArtistsTab extends ConsumerStatefulWidget {
  final List<String> artistKeys;
  final Map<String, List<Song>> artists;

  const ArtistsTab({super.key, required this.artistKeys, required this.artists});

  @override
  ConsumerState<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends ConsumerState<ArtistsTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filteredKeys = _filter.isEmpty
        ? widget.artistKeys
        : widget.artistKeys
            .where((k) => k.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Filter artists...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredKeys.length,
            itemBuilder: (context, index) {
              final artist = filteredKeys[index];
              final artistSongs = widget.artists[artist]!;
              return _ArtistTile(artist: artist, artistSongs: artistSongs);
            },
          ),
        ),
      ],
    );
  }
}

class _ArtistTile extends ConsumerWidget {
  final String artist;
  final List<Song> artistSongs;

  const _ArtistTile({required this.artist, required this.artistSongs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistImageAsync = ref.watch(artistImageProvider(artist));

    final fallbackSongWithArt = artistSongs.firstWhere(
      (s) => s.artworkPath != null,
      orElse: () => artistSongs.first,
    );
    final fallbackArtPath = fallbackSongWithArt.artworkPath;

    // Use Deezer image if available, else fallback to song cover
    final imagePath = artistImageAsync.value ?? fallbackArtPath;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
        child: imagePath == null
            ? (artistImageAsync.isLoading
                ? const CircularProgressIndicator()
                : Text(
                    artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ))
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
  }
}

