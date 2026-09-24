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
      appBar: AppBar(title: const Text('Metadata Fetch History')),
      body: historyRepoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (repo) => FutureBuilder<List<MetadataFetchHistoryRecord>>(
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
              itemBuilder: (context, i) => _RunTile(run: runs[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  final MetadataFetchHistoryRecord run;
  const _RunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    final hasErrors = run.totalErrors > 0;
    final durationLabel = _formatDuration(run.durationSeconds);

    return ExpansionTile(
      leading: Icon(
        hasErrors ? Icons.warning_amber : Icons.check_circle,
        color: hasErrors ? Colors.orange : Colors.green,
        size: 28,
      ),
      title: Text(_formatDate(run.ranAt)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('${run.totalProcessed} processed · $durationLabel'),
          const SizedBox(height: 6),
          Row(
            children: [
              if (run.matchedByApi > 0)
                _Badge(label: '${run.matchedByApi} API', color: Colors.green),
              if (run.matchedByLocal > 0) ...[
                const SizedBox(width: 6),
                _Badge(label: '${run.matchedByLocal} local', color: Colors.blue),
              ],
              if (run.totalNoMatch > 0) ...[
                const SizedBox(width: 6),
                _Badge(label: '${run.totalNoMatch} no match', color: Colors.grey),
              ],
              if (hasErrors) ...[
                const SizedBox(width: 6),
                _Badge(label: '${run.totalErrors} error', color: Colors.red),
              ],
            ],
          ),
        ],
      ),
      children: [
        if (run.apiErrorSample != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API Error Sample:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent)),
                  const SizedBox(height: 4),
                  Text(run.apiErrorSample!, style: const TextStyle(fontSize: 12, color: Colors.redAccent), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        if (run.noMatchSongTitles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Songs with no API match (${run.noMatchSongTitles.length} shown):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...run.noMatchSongTitles.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    const Icon(Icons.music_off, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                )),
              ],
            ),
          ),
        if (run.noMatchSongTitles.isEmpty && run.apiErrorSample == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('No detail data recorded for this run.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(int seconds) {
    if (seconds == 0) return '–';
    if (seconds < 60) return '${seconds}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
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
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
