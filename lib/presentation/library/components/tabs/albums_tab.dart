import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../domain/entities/song.dart';
import '../../group_detail_screen.dart';

class AlbumsTab extends StatefulWidget {
  final List<String> albumKeys;
  final Map<String, List<Song>> albums;

  const AlbumsTab({super.key, required this.albumKeys, required this.albums});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filteredKeys = _filter.isEmpty
        ? widget.albumKeys
        : widget.albumKeys
            .where((k) => k.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Filter albums...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text(
                '${filteredKeys.length} albums',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.76,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: filteredKeys.length,
            itemBuilder: (context, index) {
              final album = filteredKeys[index];
              final albumSongs = widget.albums[album]!;
              final coverSong = albumSongs.firstWhere(
                (s) => s.artworkPath != null && File(s.artworkPath!).existsSync(),
                orElse: () => albumSongs.first,
              );
              final hasArtwork = coverSong.artworkPath != null &&
                  File(coverSong.artworkPath!).existsSync();

              return _AlbumGridCard(
                album: album,
                artist: coverSong.artist ?? 'Unknown Artist',
                songCount: albumSongs.length,
                hasArtwork: hasArtwork,
                artworkPath: coverSong.artworkPath,
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
          ),
        ),
      ],
    );
  }
}

class _AlbumGridCard extends StatelessWidget {
  final String album;
  final String artist;
  final int songCount;
  final bool hasArtwork;
  final String? artworkPath;
  final VoidCallback onTap;

  const _AlbumGridCard({
    required this.album,
    required this.artist,
    required this.songCount,
    required this.hasArtwork,
    required this.artworkPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasArtwork
                  ? Image.file(
                      File(artworkPath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                            theme.colorScheme.tertiary.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.album_rounded,
                        color: theme.colorScheme.primary,
                        size: 48,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$artist · $songCount track${songCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
