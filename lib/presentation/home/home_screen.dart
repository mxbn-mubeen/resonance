import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import 'components/home_empty_prompt.dart';
import 'components/home_header.dart';
import 'components/home_playlists_section.dart';
import 'components/home_recent_section.dart';
import 'components/home_recommended_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(librarySongsProvider);

    return Scaffold(
      body: SafeArea(
        child: songsAsync.when(
          data: (songs) {
            if (songs.isEmpty) {
              return const HomeEmptyPrompt();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                HomeHeader(songs: songs),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Recently added',
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 12),
                const HomeRecentSection(),
                const SizedBox(height: 28),
                const HomeRecommendedSection(),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Playlists & Mixes',
                  icon: Icons.queue_music_rounded,
                ),
                const SizedBox(height: 12),
                const HomePlaylistsSection(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading library: $e')),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}
