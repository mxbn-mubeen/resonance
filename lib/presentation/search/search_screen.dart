import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../player/player_screen.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: 'Search songs, artists, albums…',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
            setState(() {}); // rebuild to show/hide clear button
          },
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              final repo = await ref.read(searchHistoryRepositoryProvider.future);
              await repo.saveQuery(value);
              setState(() {});
            }
          },
        ),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            if (_controller.text.isEmpty) {
              return FutureBuilder<List<String>>(
                future: ref.read(searchHistoryRepositoryProvider.future).then((r) => r.getRecentQueries()),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start typing to search your library',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Searches', style: Theme.of(context).textTheme.titleSmall),
                            TextButton(
                              onPressed: () async {
                                final repo = await ref.read(searchHistoryRepositoryProvider.future);
                                await repo.clearHistory();
                                setState(() {});
                              },
                              child: const Text('Clear'),
                            )
                          ],
                        ),
                      ),
                      ...history.map((q) => ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(q),
                            onTap: () {
                              _controller.text = q;
                              ref.read(searchQueryProvider.notifier).state = q;
                              setState(() {});
                            },
                          )),
                    ],
                  );
                },
              );
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results for "${_controller.text}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final song = results[index];
              return SongTile(
                song: song,
                onTap: () async {
                  await ref
                      .read(playbackControllerProvider)
                      .playSongs(results, startIndex: index);
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                  }
                  final repo = await ref.read(libraryRepositoryProvider.future);
                  await repo.incrementPlayCount(song.id);
                },
                onFavoriteToggle: () async {
                  final repo = await ref.read(libraryRepositoryProvider.future);
                  repo.toggleFavorite(song.id, !song.favorite);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
