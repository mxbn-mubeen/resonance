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
              final album = filteredKeys[index];
              final albumSongs = widget.albums[album]!;
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
          ),
        ),
      ],
    );
  }
}
