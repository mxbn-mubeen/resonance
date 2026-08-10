import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import 'components/home_recent_section.dart';
import 'components/home_recommended_section.dart';
import 'components/home_empty_prompt.dart';
import 'components/home_playlists_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(librarySongsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const HomeEmptyPrompt();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Your Library', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${songs.length} songs', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text('Recently added', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const HomeRecentSection(),
              const SizedBox(height: 24),
              const HomeRecommendedSection(),
              const SizedBox(height: 24),
              Text('My Playlists', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const HomePlaylistsSection(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading library: $e')),
      ),
    );
  }
}