import 'package:flutter/material.dart';

class EmptyPlaylistView extends StatelessWidget {
  const EmptyPlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music, size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
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
}

class EmptySearchView extends StatelessWidget {
  final String filter;
  const EmptySearchView({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No results for "$filter"',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
