import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/song.dart';
import '../../../core/di/providers.dart';
import '../../player/player_screen.dart';
import '../../widgets/playlist_cover_widget.dart';

class GroupHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final List<Song> songs;

  const GroupHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PlaylistCoverWidget(songIds: songs.map((s) => s.id).toList(), size: 96),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isNotEmpty ? subtitle : '${songs.length} song${songs.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Row(
            children: [
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Play all'),
                onPressed: () async {
                  if (songs.isNotEmpty) {
                    await ref.read(playbackControllerProvider).playSongs(songs);
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('Shuffle'),
                onPressed: () async {
                  if (songs.isNotEmpty) {
                    await ref.read(playbackControllerProvider).playSongs(songs, shuffle: true);
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
