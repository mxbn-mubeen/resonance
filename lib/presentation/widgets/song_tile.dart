import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:audio_service/audio_service.dart';
import '../../domain/entities/song.dart';
import '../../core/di/providers.dart';
import 'playing_indicator.dart';

class SongTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(playbackControllerProvider);

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<MediaItem?>(
            stream: controller.mediaItem,
            builder: (context, mediaSnapshot) {
              final item = mediaSnapshot.data;
              final isCurrent = item?.id == song.id;

              if (!isCurrent) return const SizedBox.shrink();

              return StreamBuilder<PlaybackState>(
                stream: controller.playbackState,
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
          IconButton(
            icon: Icon(song.favorite ? Icons.favorite : Icons.favorite_border),
            onPressed: onFavoriteToggle,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'add_to_playlist') {
                _showAddToPlaylistSheet(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_to_playlist',
                child: Text('Add to playlist'),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final playlistsAsync = ref.watch(playlistsStreamProvider);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  playlistsAsync.when(
                    data: (playlists) {
                      if (playlists.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No playlists created yet.'),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final p = playlists[index];
                          return ListTile(
                            leading: const Icon(Icons.queue_music),
                            title: Text(p.name),
                            onTap: () async {
                              final repo = await ref.read(playlistRepositoryProvider.future);
                              await repo.addSong(p.id, song.id);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Added to ${p.name}')),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
