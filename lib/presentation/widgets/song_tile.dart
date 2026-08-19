import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:audio_service/audio_service.dart';
import '../../domain/entities/song.dart';
import '../../core/di/providers.dart';
import 'playing_indicator.dart';

class SongTile extends ConsumerStatefulWidget {
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
  ConsumerState<SongTile> createState() => _SongTileState();
}

class _SongTileState extends ConsumerState<SongTile> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.song.favorite;
  }

  @override
  void didUpdateWidget(covariant SongTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.favorite != widget.song.favorite) {
      _isFavorite = widget.song.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playbackControllerProvider);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: widget.song.artworkPath != null
            ? Image.file(File(widget.song.artworkPath!), width: 44, height: 44, fit: BoxFit.cover)
            : Container(
                width: 44,
                height: 44,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
              ),
      ),
      title: Text(widget.song.title ?? widget.song.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(widget.song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<MediaItem?>(
            stream: controller.mediaItem,
            builder: (context, mediaSnapshot) {
              final item = mediaSnapshot.data;
              final isCurrent = item?.id == widget.song.id;

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
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              if (widget.onFavoriteToggle != null) {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
                widget.onFavoriteToggle!();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'add_to_playlist') {
                _showAddToPlaylistSheet(context, ref);
              } else if (value == 'add_to_queue') {
                await ref.read(playbackControllerProvider).addToQueue(widget.song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                }
              } else if (value == 'play_next') {
                await ref.read(playbackControllerProvider).playNext(widget.song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playing next')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'play_next',
                child: Text('Play next'),
              ),
              const PopupMenuItem(
                value: 'add_to_queue',
                child: Text('Add to queue'),
              ),
              const PopupMenuItem(
                value: 'add_to_playlist',
                child: Text('Add to playlist'),
              ),
            ],
          ),
        ],
      ),
      onTap: widget.onTap,
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
                              await repo.addSong(p.id, widget.song.id);
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
