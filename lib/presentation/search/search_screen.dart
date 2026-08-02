import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists, albums, lyrics...',
            border: InputBorder.none,
          ),
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        ),
      ),
      body: resultsAsync.when(
        data: (results) => results.isEmpty
            ? const Center(child: Text('Start typing to search your library'))
            : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final song = results[index];
                  return SongTile(song: song, onTap: () {});
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
