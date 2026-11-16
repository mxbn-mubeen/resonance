import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/library_entities.dart';
import '../widgets/playlist_cover_widget.dart';
import 'components/auto_playlist_tile.dart';
import 'playlist_detail_screen.dart';
import 'smart_playlist_definitions.dart';

export 'components/auto_playlist_tile.dart' show openSmartPlaylist;

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.library_music_rounded, size: 18), text: 'Manual'),
              Tab(icon: Icon(Icons.flash_on_rounded, size: 18), text: 'Smart Auto'),
              Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'AI Mixes'),
            ],
          ),
          actions: [
            IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New Playlist',
              onPressed: () => _showCreateSheet(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            // Manual tab
            ref.watch(playlistsStreamProvider).when(
                  data: (playlists) {
                    final manual = playlists.where((p) => !p.isAuto && !p.isAiGenerated).toList();
                    if (manual.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.queue_music_rounded, size: 56, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text(
                              'No custom playlists yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create Playlist'),
                              onPressed: () => _showCreateSheet(context, ref),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: manual.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) => _PlaylistTile(playlist: manual[i]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),

            // Automatic tab
            ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: kAutomaticPlaylistDefs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) => AutoPlaylistTile(def: kAutomaticPlaylistDefs[i]),
            ),

            // AI tab
            ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: kAiPlaylistDefs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) => AutoPlaylistTile(def: kAiPlaylistDefs[i]),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Playlist title...',
                prefixIcon: const Icon(Icons.playlist_add_rounded),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      final engine = await ref.read(playlistEngineProvider.future);
                      await engine.createManualPlaylist(name);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${playlist.songIds.length} tracks',
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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
