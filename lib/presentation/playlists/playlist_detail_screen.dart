import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/library_entities.dart';
import '../../domain/entities/song.dart';
import '../widgets/mini_player.dart';
import 'components/playlist_header.dart';
import 'components/playlist_song_tile.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final PlaylistEntity playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  String _filter = '';
  final TextEditingController _filterController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<List<Song>> _loadSongs(PlaylistEntity playlist) async {
    final libraryRepo = await ref.read(libraryRepositoryProvider.future);
    final all = await libraryRepo.getAllSongs();
    return playlist.songIds
        .map((id) {
          try {
            return all.firstWhere((s) => s.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Song>()
        .toList();
  }

  Future<void> _showRenameDialog(PlaylistEntity playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName != playlist.name) {
      final repo = await ref.read(playlistRepositoryProvider.future);
      await repo.rename(playlist.id, newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Renamed to "$newName"')),
        );
      }
    }
  }

  Future<void> _confirmDelete(PlaylistEntity playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"? Songs will not be removed from your library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = await ref.read(playlistRepositoryProvider.future);
      await repo.delete(playlist.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the stream so the screen rebuilds when songs are added/removed
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final currentPlaylist = playlistsAsync.when(
      data: (playlists) {
        try {
          return playlists.firstWhere((p) => p.id == widget.playlist.id);
        } catch (_) {
          return widget.playlist;
        }
      },
      loading: () => widget.playlist,
      error: (_, __) => widget.playlist,
    );

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _filterController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Filter songs…',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _filter = v),
              )
            : Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Filter songs',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _filter = '';
                  _filterController.clear();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') _showRenameDialog(currentPlaylist);
              if (value == 'delete') _confirmDelete(currentPlaylist);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Row(
                children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Rename')],
              )),
              const PopupMenuItem(value: 'delete', child: Row(
                children: [Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))],
              )),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: FutureBuilder<List<Song>>(
        future: _loadSongs(currentPlaylist),
        key: ValueKey(currentPlaylist.songIds.length),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snapshot.data ?? [];
          final filtered = _filter.isEmpty
              ? songs
              : songs.where((s) {
                  final q = _filter.toLowerCase();
                  return (s.title ?? '').toLowerCase().contains(q) ||
                      (s.artist ?? '').toLowerCase().contains(q) ||
                      (s.album ?? '').toLowerCase().contains(q);
                }).toList();

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 72,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No songs in this playlist yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Tap ⋮ on any song and choose "Add to playlist"',
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          if (filtered.isEmpty) {
            return Center(
              child: Text('No results for "$_filter"',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            );
          }

          return Column(
            children: [
              // ── Playlist Header ────────────────────────────────────────
              PlaylistHeader(playlist: currentPlaylist, songs: songs),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final song = filtered[index];
                    return PlaylistSongTile(
                      song: song,
                      playlistSongs: songs,
                      playlist: currentPlaylist,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
