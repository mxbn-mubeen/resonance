import 'package:flutter/material.dart';

import '../../../../domain/entities/song.dart';
import '../../group_detail_screen.dart';

class ArtistsTab extends StatefulWidget {
  final List<String> artistKeys;
  final Map<String, List<Song>> artists;

  const ArtistsTab({super.key, required this.artistKeys, required this.artists});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          ),
        ),
      ],
    );
  }
}
