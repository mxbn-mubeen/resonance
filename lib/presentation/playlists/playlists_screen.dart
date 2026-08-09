import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/library_entities.dart';
import '../../domain/entities/song.dart';
import '../widgets/playlist_cover_widget.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        children: [
          const _SectionHeader('Manual'),
          ref.watch(playlistsStreamProvider).when(
                data: (playlists) {
                  final manual = playlists.where((p) => !p.isAuto && !p.isAiGenerated).toList();
                  if (manual.isEmpty) {
                    return const ListTile(title: Text('No playlists yet'));
                  }
                  return Column(
                    children: manual.map((p) => _PlaylistTile(playlist: p)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
          const _SectionHeader('Automatic'),
          ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Most Played'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist view coming soon!')))),
          ListTile(
              leading: const Icon(Icons.fiber_new),
              title: const Text('Recently Added'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist view coming soon!')))),
          ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Recently Played'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist view coming soon!')))),
          ListTile(
              leading: const Icon(Icons.new_releases),
              title: const Text('Never Played'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist view coming soon!')))),
          const _SectionHeader('AI Generated'),
          ListTile(
              leading: const Icon(Icons.nightlife),
              title: const Text('Night Drive'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Moods coming soon!')))),
          ListTile(
              leading: const Icon(Icons.spa),
              title: const Text('Relax'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Moods coming soon!')))),
          ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workout'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Moods coming soon!')))),
          ListTile(
              leading: const Icon(Icons.center_focus_strong),
              title: const Text('Focus'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Moods coming soon!')))),
        ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
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
