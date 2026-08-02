import 'dart:io';
import 'package:flutter/material.dart';

import '../../domain/entities/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.artworkPath != null
            ? Image.file(File(song.artworkPath!), width: 44, height: 44, fit: BoxFit.cover)
            : Container(
                width: 44,
                height: 44,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
              ),
      ),
      title: Text(song.title ?? song.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: Icon(song.favorite ? Icons.favorite : Icons.favorite_border),
        onPressed: onFavoriteToggle,
      ),
      onTap: onTap,
    );
  }
}
