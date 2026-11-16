import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/local/isar_schemas.dart';
import '../../domain/entities/song.dart';
import 'components/duplicates_dialog.dart';
import 'components/health_hero_card.dart';
import 'components/health_issue_tile.dart';
import 'health_history_screen.dart';
import 'metadata_fetch_screen.dart';

class LibraryHealthScreen extends ConsumerStatefulWidget {
  const LibraryHealthScreen({super.key});

  @override
  ConsumerState<LibraryHealthScreen> createState() => _LibraryHealthScreenState();
}

class _LibraryHealthScreenState extends ConsumerState<LibraryHealthScreen> {
  bool _isScanning = false;
  int _totalSongs = 0;
  int _missingTagsCount = 0;
  int _brokenArtworkCount = 0;
  int _duplicatesCount = 0;
  bool _hasScanned = false;
  List<Song> _brokenSongs = [];
  List<Song> _duplicateSongs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runHealthCheck(silent: true));
  }

  Future<void> _runHealthCheck({bool silent = false}) async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      final repo = await ref.read(libraryRepositoryProvider.future);
      final songs = await repo.getAllSongs();

      final missing = songs.where((s) {
        final a = s.artist?.trim().toLowerCase() ?? '';
        final t = s.title?.trim().toLowerCase() ?? '';
        return a.isEmpty || a == 'unknown artist' || a == '<unknown>' || t.isEmpty;
      }).toList();

      final broken = <Song>[];
      for (final s in songs) {
        if (s.artworkPath != null && !File(s.artworkPath!).existsSync()) {
          broken.add(s);
        }
      }

      final seen = <String, Song>{};
      final duplicates = <Song>[];
      for (final s in songs) {
        final key = '${s.title?.trim().toLowerCase()}|${s.artist?.trim().toLowerCase()}';
        if (seen.containsKey(key)) {
          duplicates.add(s);
        } else {
          seen[key] = s;
        }
      }

      if (mounted) {
        setState(() {
          _totalSongs = songs.length;
          _missingTagsCount = missing.length;
          _brokenArtworkCount = broken.length;
          _duplicatesCount = duplicates.length;
          _brokenSongs = broken;
          _duplicateSongs = duplicates;
          _hasScanned = true;
          _isScanning = false;
        });

        final historyRepo = await ref.read(libraryHealthHistoryRepositoryProvider.future);
        final record = LibraryHealthHistoryRecord()
          ..ranAt = DateTime.now()
          ..totalSongs = songs.length
          ..missingTags = missing.length
          ..brokenArtwork = broken.length
          ..duplicates = duplicates.length;
        await historyRepo.saveRun(record);

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Health diagnostic complete!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan error: $e')),
        );
      }
    }
  }

  Future<void> _fixBrokenArtwork() async {
    if (_brokenSongs.isEmpty) return;
    final repo = await ref.read(libraryRepositoryProvider.future);
    int fixed = 0;
    for (final s in _brokenSongs) {
      try {
        await repo.updateArtworkPath(s.id, null);
        fixed++;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _brokenArtworkCount = 0;
        _brokenSongs = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🖼️ Cleared $fixed stale artwork paths — re-fetch to restore.')),
      );
    }
  }

  Future<void> _showDuplicatesDialog() async {
    if (_duplicateSongs.isEmpty) return;
    final repo = await ref.read(libraryRepositoryProvider.future);

    await showDialog<void>(
      context: context,
      builder: (ctx) => DuplicatesDialog(
        duplicates: _duplicateSongs,
        onDelete: (song) async {
          await repo.deleteSongById(song.id);
          if (mounted) {
            setState(() {
              _duplicateSongs.remove(song);
              _duplicatesCount = (_duplicatesCount - 1).clamp(0, _duplicatesCount);
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalIssues = _missingTagsCount + _brokenArtworkCount + _duplicatesCount;
    final healthScore = _totalSongs > 0
        ? (((_totalSongs - totalIssues).clamp(0, _totalSongs) / _totalSongs) * 100).round()
        : 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View Scan History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HealthHeroCard(
              healthScore: healthScore,
              totalSongs: _totalSongs,
              totalIssues: totalIssues,
              hasScanned: _hasScanned,
              isScanning: _isScanning,
              onScan: () => _runHealthCheck(silent: false),
            ),
            const SizedBox(height: 20),
            Text(
              'Diagnostic Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            HealthIssueTile(
              icon: Icons.label_off_rounded,
              iconColor: _missingTagsCount > 0 ? Colors.orangeAccent : Colors.greenAccent,
              title: 'Missing Tags',
              subtitle: 'Tracks with unknown artist or missing title',
              count: _missingTagsCount,
              actionLabel: _missingTagsCount > 0 ? 'Fix via Fetch' : null,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MetadataFetchScreen()),
              ),
            ),
            const SizedBox(height: 10),
            HealthIssueTile(
              icon: Icons.broken_image_rounded,
              iconColor: _brokenArtworkCount > 0 ? Colors.redAccent : Colors.greenAccent,
              title: 'Broken Artwork',
              subtitle: 'Database records with missing image files on disk',
              count: _brokenArtworkCount,
              actionLabel: _brokenArtworkCount > 0 ? 'Clear Stale' : null,
              onAction: _brokenArtworkCount > 0 ? _fixBrokenArtwork : null,
            ),
            const SizedBox(height: 10),
            HealthIssueTile(
              icon: Icons.content_copy_rounded,
              iconColor: _duplicatesCount > 0 ? Colors.orangeAccent : Colors.greenAccent,
              title: 'Duplicate Tracks',
              subtitle: 'Identical title and artist across multiple folders',
              count: _duplicatesCount,
              actionLabel: _duplicatesCount > 0 ? 'Review & Delete' : null,
              onAction: _duplicatesCount > 0 ? _showDuplicatesDialog : null,
            ),
          ],
        ),
      ),
    );
  }
}
