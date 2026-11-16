import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../core/di/providers.dart';
import '../settings/library_health_screen.dart';
import 'components/tabs/albums_tab.dart';
import 'components/tabs/artists_tab.dart';
import 'components/tabs/favourites_tab.dart';
import 'components/tabs/folders_tab.dart';
import 'components/tabs/songs_tab.dart';

enum _SortMode { titleAsc, titleDesc, artist, dateAdded }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _SortMode _sortMode = _SortMode.titleAsc;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _sortSongs(List<Song> songs) {
    final list = List<Song>.from(songs);
    switch (_sortMode) {
      case _SortMode.titleAsc:
        list.sort((a, b) => (a.title ?? a.filename).compareTo(b.title ?? b.filename));
      case _SortMode.titleDesc:
        list.sort((b, b2) => (b2.title ?? b2.filename).compareTo(b.title ?? b.filename));
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _chip('A → Z', _SortMode.titleAsc, Icons.sort_by_alpha_rounded),
          const SizedBox(width: 8),
          _chip('Z → A', _SortMode.titleDesc, Icons.sort_by_alpha_rounded),
          const SizedBox(width: 8),
          _chip('Artist', _SortMode.artist, Icons.person_outline_rounded),
          const SizedBox(width: 8),
          _chip('Date Added', _SortMode.dateAdded, Icons.calendar_today_rounded),
        ],
      ),
    );
  }

  Widget _chip(String label, _SortMode mode, IconData icon) {
    final selected = _sortMode == mode;
    return ChoiceChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
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
          title: _showSearch
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, albums...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              : const Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.music_note_rounded, size: 18), text: 'Songs'),
              Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Artists'),
              Tab(icon: Icon(Icons.album_rounded, size: 18), text: 'Albums'),
              Tab(icon: Icon(Icons.folder_rounded, size: 18), text: 'Folders'),
              Tab(icon: Icon(Icons.favorite_rounded, size: 18, color: Colors.pinkAccent), text: 'Favourites'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
              tooltip: _showSearch ? 'Close search' : 'Search library',
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.health_and_safety_outlined),
              tooltip: 'Library Health',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryHealthScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Rescan library',
              onPressed: () async {
                final scanner = await ref.read(scannerServiceProvider.future);
                final result = await scanner.scan(
                    includedFolderPaths: ref.read(includedFoldersProvider).valueOrNull ?? []);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.newOrUpdated} new, ${result.updated} updated, '
                        '${result.unchanged} unchanged',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: songsAsync.when(
          data: (allSongs) {
            final query = _searchQuery.toLowerCase();
            final songs = query.isEmpty 
                ? allSongs 
                : allSongs.where((s) {
                    return (s.title ?? s.filename).toLowerCase().contains(query) ||
                           (s.artist ?? '').toLowerCase().contains(query) ||
                           (s.album ?? '').toLowerCase().contains(query) ||
                           (s.path).toLowerCase().contains(query);
                  }).toList();

            final sorted = _sortSongs(songs);

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
