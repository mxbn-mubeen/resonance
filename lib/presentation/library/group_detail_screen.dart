import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../core/di/providers.dart';
import '../player/player_route.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import 'components/group_header.dart';

enum _SortMode { titleAsc, titleDesc, artist, duration }

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Song> songs;
  final String subtitle;

  const GroupDetailScreen({
    super.key,
    required this.title,
    required this.songs,
    this.subtitle = '',
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  String _filter = '';
  final TextEditingController _filterController = TextEditingController();
  bool _showSearch = false;
  _SortMode _sortMode = _SortMode.titleAsc;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter by search query
    final filtered = _filter.isEmpty
        ? List<Song>.from(widget.songs)
        : widget.songs.where((s) {
            final q = _filter.toLowerCase();
            return (s.title ?? '').toLowerCase().contains(q) ||
                (s.artist ?? '').toLowerCase().contains(q) ||
                (s.album ?? '').toLowerCase().contains(q);
          }).toList();

    // 2. Sort the filtered list
    switch (_sortMode) {
      case _SortMode.titleAsc:
        filtered.sort((a, b) => (a.title ?? a.filename).compareTo(b.title ?? b.filename));
      case _SortMode.titleDesc:
        filtered.sort((a, b) => (b.title ?? b.filename).compareTo(a.title ?? a.filename));
      case _SortMode.artist:
        filtered.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      case _SortMode.duration:
        filtered.sort((a, b) => a.duration.compareTo(b.duration));
    }

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
            : Text(widget.title),
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
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          GroupHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            songs: widget.songs,
          ),
          // ── Sort bar ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _chip('A → Z', _SortMode.titleAsc),
                const SizedBox(width: 8),
                _chip('Z → A', _SortMode.titleDesc),
                const SizedBox(width: 8),
                _chip('Artist', _SortMode.artist),
                const SizedBox(width: 8),
                _chip('Duration', _SortMode.duration),
              ],
            ),
          ),
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text('No results for "$_filter"',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final song = filtered[index];
                  return SongTile(
                    song: song,
                    onTap: () async {
                      // IMPORTANT: pass `filtered` (the sorted/filtered list the user sees)
                      // NOT `widget.songs` (raw order). Using the raw list as the queue
                      // while indexing into the filtered list produces a mismatched queue.
                      await ref.read(playbackControllerProvider).playSongs(filtered, startIndex: index);
                      if (context.mounted) {
                        // Check if a PlayerRoute is already the top-most route
                        bool isPlayerOpen = false;
                        Navigator.popUntil(context, (route) {
                          if (route is PlayerRoute) isPlayerOpen = true;
                          return true; // Don't actually pop anything
                        });
                        
                        if (!isPlayerOpen) {
                          Navigator.of(context).push(PlayerRoute());
                        }
                      }
                    },
                    onFavoriteToggle: () async {
                      final repo = await ref.read(libraryRepositoryProvider.future);
                      await repo.toggleFavorite(song.id, !song.favorite);
                      // Invalidate library provider so changes reflect
                      ref.invalidate(librarySongsProvider);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, _SortMode mode) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortMode == mode,
      onSelected: (_) => setState(() => _sortMode = mode),
    );
  }
}
