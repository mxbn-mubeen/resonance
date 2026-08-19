import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/local/isar_schemas.dart';

class MetadataHistoryScreen extends ConsumerWidget {
  const MetadataHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepoAsync = ref.watch(metadataFetchHistoryRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metadata Fetch History'),
      ),
      body: historyRepoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (repo) {
          return FutureBuilder<List<MetadataFetchHistoryRecord>>(
            future: repo.getRecentRuns(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final runs = snapshot.data ?? [];
              if (runs.isEmpty) {
                return const Center(
                  child: Text('No fetch runs yet. Tap "Fetch missing metadata now" to start.'),
                );
              }

              return ListView.separated(
                itemCount: runs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = runs[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(_formatDate(r.ranAt)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${r.totalProcessed} total processed'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Badge(label: '${r.totalUpdated} updated', color: Colors.green),
                            const SizedBox(width: 8),
                            _Badge(label: '${r.totalNoMatch} no match', color: Colors.blue),
                            if (r.totalErrors > 0) ...[
                              const SizedBox(width: 8),
                              _Badge(label: '${r.totalErrors} errors', color: Colors.red),
                            ]
                          ],
                        ),
                        if (r.firstError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'First error: ${r.firstError}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ]
                      ],
                    ),
                    leading: Icon(
                      r.totalErrors > 0 ? Icons.warning_amber : Icons.check_circle,
                      color: r.totalErrors > 0 ? Colors.orange : Colors.green,
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
