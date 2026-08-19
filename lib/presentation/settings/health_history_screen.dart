import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/isar_schemas.dart';

class HealthHistoryScreen extends ConsumerWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepoAsync = ref.watch(libraryHealthHistoryRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Health History'),
      ),
      body: historyRepoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (repo) {
          return FutureBuilder<List<LibraryHealthHistoryRecord>>(
            future: repo.getRecentRuns(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final runs = snapshot.data ?? [];
              if (runs.isEmpty) {
                return const Center(
                  child: Text('No health scans yet. Tap "Run Library Health report" to start.'),
                );
              }

              return ListView.separated(
                itemCount: runs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = runs[i];
                  final hasIssues = r.missingTags > 0 || r.brokenArtwork > 0 || r.duplicates > 0;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(_formatDate(r.ranAt)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${r.totalSongs} total songs scanned'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (r.missingTags > 0) ...[
                              _Badge(label: '${r.missingTags} missing tags', color: Colors.orange),
                              const SizedBox(width: 8),
                            ],
                            if (r.brokenArtwork > 0) ...[
                              _Badge(label: '${r.brokenArtwork} broken art', color: Colors.red),
                              const SizedBox(width: 8),
                            ],
                            if (r.duplicates > 0) ...[
                              _Badge(label: '${r.duplicates} duplicates', color: Colors.orange),
                            ],
                            if (!hasIssues)
                              const _Badge(label: 'Perfect health', color: Colors.green),
                          ],
                        ),
                      ],
                    ),
                    leading: Icon(
                      hasIssues ? Icons.warning_amber : Icons.check_circle,
                      color: hasIssues ? Colors.orange : Colors.green,
                      size: 28,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
