import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:audio_service/audio_service.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entities/library_entities.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_screen.dart';
import '../../widgets/playing_indicator.dart';

class PlaylistSongTile extends ConsumerWidget {
  final Song song;
  final List<Song> playlistSongs;
  final PlaylistEntity playlist;
  final int index;

  const PlaylistSongTile({
    super.key,
    required this.song,
    required this.playlistSongs,
    required this.playlist,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: song.artworkPath != null
            ? Image.file(File(song.artworkPath!), width: 44, height: 44, fit: BoxFit.cover)
            : Container(
                width: 44,
                height: 44,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.music_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
              ),
      ),
      title: Text(song.title ?? song.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${song.artist ?? 'Unknown'} • ${song.album ?? ''}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<MediaItem?>(
            stream: ref.watch(playbackControllerProvider).mediaItem,
            builder: (context, mediaSnapshot) {
              final item = mediaSnapshot.data;
              final isCurrent = item?.id == song.id;

              if (!isCurrent) return const SizedBox.shrink();

              return StreamBuilder<PlaybackState>(
                stream: ref.watch(playbackControllerProvider).playbackState,
                builder: (context, stateSnapshot) {
                  final playing = stateSnapshot.data?.playing ?? false;
                  if (!playing) return const SizedBox.shrink();

                  return const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: PlayingIndicator(size: 20),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'remove') {
                final repo = await ref.read(playlistRepositoryProvider.future);
                await repo.removeSong(playlist.id, song.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed "${song.title ?? song.filename}" from playlist')),
                  );
                }
              } else if (value == 'play_next') {
                await ref.read(playbackControllerProvider).playSongs(playlistSongs, startIndex: playlistSongs.indexOf(song));
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'play_next', child: Text('Play from here')),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove from playlist', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        await ref.read(playbackControllerProvider).playSongs(playlistSongs, startIndex: playlistSongs.indexOf(song));
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
    );
  }
}
