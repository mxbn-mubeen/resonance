import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

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
          FutureBuilder(
            future: ref.read(playlistRepositoryProvider).getAll(),
            builder: (context, snapshot) {
              final playlists = snapshot.data ?? [];
              if (playlists.isEmpty) {
                return const ListTile(title: Text('No playlists yet'));
              }
              return Column(
                children: playlists
                    .map((p) => ListTile(
                          leading: const Icon(Icons.queue_music),
                          title: Text(p.name),
                          subtitle: Text('${p.songIds.length} songs'),
                        ))
                    .toList(),
              );
            },
          ),
          const _SectionHeader('Automatic'),
          const ListTile(leading: Icon(Icons.trending_up), title: Text('Most Played')),
          const ListTile(leading: Icon(Icons.fiber_new), title: Text('Recently Added')),
          const ListTile(leading: Icon(Icons.history), title: Text('Recently Played')),
          const ListTile(leading: Icon(Icons.new_releases), title: Text('Never Played')),
          const _SectionHeader('AI Generated'),
          const ListTile(leading: Icon(Icons.nightlife), title: Text('Night Drive')),
          const ListTile(leading: Icon(Icons.spa), title: Text('Relax')),
          const ListTile(leading: Icon(Icons.fitness_center), title: Text('Workout')),
          const ListTile(leading: Icon(Icons.center_focus_strong), title: Text('Focus')),
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
                await ref.read(playlistEngineProvider).createManualPlaylist(controller.text.trim());
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
