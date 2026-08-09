import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../core/di/providers.dart';
import 'components/library_tabs.dart';

// Sort options
enum _SortMode { titleAsc, titleDesc, artist, dateAdded }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _SortMode _sortMode = _SortMode.titleAsc;

  List<Song> _sortSongs(List<Song> songs) {
    final list = List<Song>.from(songs);
    switch (_sortMode) {
      case _SortMode.titleAsc:
        list.sort((a, b) => (a.title ?? a.filename).compareTo(b.title ?? b.filename));
      case _SortMode.titleDesc:
        list.sort((a, b) => (b.title ?? b.filename).compareTo(a.title ?? a.filename));
      case _SortMode.artist:
        list.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      case _SortMode.dateAdded:
        list.sort((a, b) => b.modified.compareTo(a.modified));
    }
    return list;
  }

  Widget _sortBar() {
    return SingleChildScrollView(
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
          _chip('Date Added', _SortMode.dateAdded),
        ],
      ),
    );
  }

  Widget _chip(String label, _SortMode mode) {
    final selected = _sortMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _sortMode = mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(librarySongsProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
              Tab(text: 'Folders'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.pinkAccent),
                    SizedBox(width: 4),
                    Text('Favourites'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rescan',
              onPressed: () async {
                final scanner = await ref.read(scannerServiceProvider.future);
                final result = await scanner.scan(
                    includedFolderPaths: ref.read(includedFoldersProvider).valueOrNull ?? []);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.newOrUpdated} new, ${result.updated} updated, '
                        '${result.unchanged} unchanged, ${result.deleted} removed',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: songsAsync.when(
          data: (songs) {
            final sorted = _sortSongs(songs);

            // Build grouped data
            final artists = <String, List<Song>>{};
            final albums = <String, List<Song>>{};
            final folders = <String, List<Song>>{};

            for (final song in songs) {
              final artistKey = song.artist ?? 'Unknown Artist';
              final albumKey = song.album ?? 'Unknown Album';
              final dir = File(song.path).parent.path;
              artists.putIfAbsent(artistKey, () => []).add(song);
              albums.putIfAbsent(albumKey, () => []).add(song);
              folders.putIfAbsent(dir, () => []).add(song);
            }

            final artistKeys = artists.keys.toList()..sort();
            final albumKeys = albums.keys.toList()..sort();
            final folderPaths = folders.keys.toList()..sort();

            return TabBarView(
              children: [
                SongsTab(sorted: sorted, sortBar: _sortBar()),
                ArtistsTab(artistKeys: artistKeys, artists: artists),
                AlbumsTab(albumKeys: albumKeys, albums: albums),
                FoldersTab(folderPaths: folderPaths, folders: folders),
                FavouritesTab(songs: songs),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
