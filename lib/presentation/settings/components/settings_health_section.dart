import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/metadata/metadata_fetch_runner.dart';
import '../health_history_screen.dart';
import '../../../core/di/providers.dart';
import '../../../data/local/isar_schemas.dart';

class SettingsHealthSection extends ConsumerWidget {
  const SettingsHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Library Health', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety),
          title: const Text('Run Library Health report'),
          subtitle: const Text('Missing tags, duplicates, broken artwork, corrupted files'),
          onTap: () => _runLibraryHealthReport(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('View health history'),
          subtitle: const Text('See past Library Health scan results'),
          onTap: () => _showHealthHistory(context, ref),
        ),
      ],
    );
  }

  Future<void> _runLibraryHealthReport(BuildContext context, WidgetRef ref) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔍 Scanning library…'), duration: Duration(seconds: 2)),
      );
    }

    final repo = await ref.read(libraryRepositoryProvider.future);
    final songs = await repo.getAllSongs();

    // 1. Missing tags
    final missingTags = songs.where((s) {
      final a = s.artist?.trim().toLowerCase() ?? '';
      return a.isEmpty || a == 'unknown artist' || a == '<unknown>' ||
          (s.title?.trim().isEmpty ?? true);
    }).toList();

    // 2. Broken artwork (path in DB but file doesn't exist on disk)
    final brokenArtwork = <dynamic>[];
    for (final s in songs) {
      if (s.artworkPath != null && !File(s.artworkPath!).existsSync()) {
        brokenArtwork.add(s);
      }
    }

    // 3. Duplicates (same title + artist, different paths)
    final seen = <String, dynamic>{};
    final duplicates = <dynamic>[];
    for (final s in songs) {
      final key = '${s.title?.trim().toLowerCase()}|${s.artist?.trim().toLowerCase()}';
      if (seen.containsKey(key)) {
        duplicates.add(s);
      } else {
        seen[key] = s;
      }
    }

    if (!context.mounted) return;

    // Save run to history
    try {
      final historyRepo = await ref.read(libraryHealthHistoryRepositoryProvider.future);
      final record = LibraryHealthHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalSongs = songs.length
        ..missingTags = missingTags.length
        ..brokenArtwork = brokenArtwork.length
        ..duplicates = duplicates.length;
      await historyRepo.saveRun(record);
    } catch (e) {
      debugPrint('Failed to save health history: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.health_and_safety, color: Colors.green), SizedBox(width: 8), Text('Library Health')],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HealthStatRow(
                  icon: Icons.label_off,
                  label: 'Missing / dirty tags',
                  count: missingTags.length,
                  color: missingTags.isEmpty ? Colors.green : Colors.orange,
                ),
                if (missingTags.isNotEmpty)
                  _ExpandableList(
                    items: missingTags.take(10).map((s) => s.title ?? s.filename).toList(),
                    extra: missingTags.length > 10 ? '… and ${missingTags.length - 10} more' : null,
                  ),
                const SizedBox(height: 12),
                _HealthStatRow(
                  icon: Icons.image_not_supported,
                  label: 'Broken artwork paths',
                  count: brokenArtwork.length,
                  color: brokenArtwork.isEmpty ? Colors.green : Colors.red,
                ),
                if (brokenArtwork.isNotEmpty)
                  _ExpandableList(
                    items: brokenArtwork.take(5).map<String>((s) => s.title ?? s.filename as String).toList(),
                    extra: brokenArtwork.length > 5 ? '… and ${brokenArtwork.length - 5} more' : null,
                  ),
                const SizedBox(height: 12),
                _HealthStatRow(
                  icon: Icons.copy,
                  label: 'Potential duplicates',
                  count: duplicates.length,
                  color: duplicates.isEmpty ? Colors.green : Colors.orange,
                ),
                if (duplicates.isNotEmpty)
                  _ExpandableList(
                    items: duplicates.take(5).map<String>((s) => '${s.artist} — ${s.title}').toList(),
                    extra: duplicates.length > 5 ? '… and ${duplicates.length - 5} more' : null,
                  ),
                const SizedBox(height: 8),
                Text(
                  '${songs.length} total songs scanned',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (missingTags.isNotEmpty)
            FilledButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Fix now'),
              onPressed: () {
                Navigator.pop(ctx);
                MetadataFetchRunner.run(context, ref);
              },
            ),
        ],
      ),
    );
  }

  void _showHealthHistory(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
    );
  }
}

class _HealthStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _HealthStatRow({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ExpandableList extends StatelessWidget {
  final List<String> items;
  final String? extra;

  const _ExpandableList({required this.items, this.extra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((i) => Text('• $i', style: const TextStyle(fontSize: 12, color: Colors.grey))),
          if (extra != null) Text(extra!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
