import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/song.dart';
import 'components/duplicate_group_card.dart';

class DuplicateTrackerScreen extends ConsumerStatefulWidget {
  final List<Song> duplicates;

  const DuplicateTrackerScreen({super.key, required this.duplicates});

  @override
  ConsumerState<DuplicateTrackerScreen> createState() => _DuplicateTrackerScreenState();
}

class _DuplicateTrackerScreenState extends ConsumerState<DuplicateTrackerScreen> {
  late List<Song> _allDuplicates;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isAutoCleaning = false;

  @override
  void initState() {
    super.initState();
    _allDuplicates = List.from(widget.duplicates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<Song>> _groupDuplicates() {
    final groups = <String, List<Song>>{};
    for (final s in _allDuplicates) {
      final key = '${s.title?.trim().toLowerCase()}|${s.artist?.trim().toLowerCase()}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    return groups;
  }

  Future<void> _handleDelete(Song song) async {
    final repo = await ref.read(libraryRepositoryProvider.future);
    await repo.deleteSongById(song.id);
    if (mounted) {
      setState(() {
        _allDuplicates.removeWhere((s) => s.id == song.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Removed copy of "${song.title ?? song.filename}"')),
      );
    }
  }

  Future<void> _autoCleanDuplicates() async {
    final groups = _groupDuplicates();
    final toDelete = <Song>[];
    for (final group in groups.values) {
      if (group.length > 1) {
        toDelete.addAll(group.skip(1));
      }
    }

    if (toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Clean Duplicates'),
        content: Text(
          'This will remove ${toDelete.length} duplicate copies, keeping the first copy of each track. '
          'Files will be deleted from your library.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clean All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isAutoCleaning = true);
    final repo = await ref.read(libraryRepositoryProvider.future);
    int count = 0;
    for (final song in toDelete) {
      try {
        await repo.deleteSongById(song.id);
        count++;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _allDuplicates.removeWhere((s) => toDelete.contains(s));
        _isAutoCleaning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Cleaned $count duplicate tracks!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupDuplicates();
    final filteredKeys = groups.keys.where((k) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final songs = groups[k]!;
      return songs.any((s) =>
          (s.title ?? s.filename).toLowerCase().contains(q) ||
          (s.artist ?? '').toLowerCase().contains(q) ||
          s.path.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicate Tracker'),
        actions: [
          if (_allDuplicates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.auto_fix_high_rounded),
              tooltip: 'Auto-Clean (Keep 1st copy)',
              onPressed: _isAutoCleaning ? null : _autoCleanDuplicates,
            ),
        ],
      ),
      body: _isAutoCleaning
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cleaning duplicate files…'),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search duplicates…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${filteredKeys.length} groups · ${_allDuplicates.length} files',
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      const Spacer(),
                      if (_allDuplicates.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
                          label: const Text('Auto-Clean', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          onPressed: _autoCleanDuplicates,
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredKeys.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.greenAccent),
                              SizedBox(height: 12),
                              Text('No duplicates found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('Your library is completely organized!', style: TextStyle(fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredKeys.length,
                          itemBuilder: (ctx, i) {
                            final key = filteredKeys[i];
                            return DuplicateGroupCard(
                              groupKey: key,
                              songs: groups[key]!,
                              onDeleteSong: _handleDelete,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
