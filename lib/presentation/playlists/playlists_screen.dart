import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/library_entities.dart';
import '../library/group_detail_screen.dart';
import '../widgets/playlist_cover_widget.dart';
import 'playlist_detail_screen.dart';
import 'smart_playlist_definitions.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Playlists'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Manual'),
              Tab(text: 'Auto'),
              Tab(text: 'AI'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Manual tab
            ref.watch(playlistsStreamProvider).when(
                  data: (playlists) {
                    final manual = playlists.where((p) => !p.isAuto && !p.isAiGenerated).toList();
                    if (manual.isEmpty) {
                      return const Center(child: Text('No manual playlists yet.'));
                    }
                    return ListView(
                      children: manual.map((p) => _PlaylistTile(playlist: p)).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
            
            // Automatic tab
            ListView(
              children: kAutomaticPlaylistDefs.map((def) => _AutoPlaylistTile(def: def)).toList(),
            ),
            
            // AI tab
            ListView(
              children: kAiPlaylistDefs.map((def) => _AutoPlaylistTile(def: def)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final engine = await ref.read(playlistEngineProvider.future);
                await engine.createManualPlaylist(controller.text.trim());
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// One row for an Automatic/AI playlist. Resolves its song list on tap
/// (not eagerly for every tile on screen build - these can involve genre
/// joins across the whole library) and opens the shared GroupDetailScreen,
/// same one Library's tabs and the Home rail both use.
class _AutoPlaylistTile extends ConsumerStatefulWidget {
  final SmartPlaylistDef def;

  const _AutoPlaylistTile({required this.def});

  @override
  ConsumerState<_AutoPlaylistTile> createState() => _AutoPlaylistTileState();
}

class _AutoPlaylistTileState extends ConsumerState<_AutoPlaylistTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.def.icon),
      title: Text(widget.def.title),
      subtitle: Text(widget.def.subtitle, style: const TextStyle(fontSize: 11)),
      trailing: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
      onTap: _loading ? null : () => openSmartPlaylist(context, ref, widget.def),
    );
  }
}

/// Shared navigation logic - resolves the song list and opens
/// GroupDetailScreen, or shows a snackbar if nothing matched. Used by both
/// the Playlists tab tiles and the Home rail's smart-playlist cards so the
/// tap behavior (loading state, empty-result message) is identical
/// everywhere instead of being reimplemented per surface.
Future<void> openSmartPlaylist(BuildContext context, WidgetRef ref, SmartPlaylistDef def) async {
  final engine = await ref.read(playlistEngineProvider.future);
  final songs = await def.loader(engine);
  if (!context.mounted) return;

  if (songs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No songs match "${def.title}" yet')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => GroupDetailScreen(
        title: def.title,
        songs: songs,
        subtitle: '${songs.length} songs',
      ),
    ),
  );
}


class _PlaylistTile extends ConsumerWidget {
  final PlaylistEntity playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: PlaylistCoverWidget(
        songIds: playlist.songIds,
        size: 48,
      ),
      title: Text(playlist.name),
      subtitle: Text('${playlist.songIds.length} songs'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
    );
  }
}