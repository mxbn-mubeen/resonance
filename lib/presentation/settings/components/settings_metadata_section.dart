import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/metadata/metadata_fetch_runner.dart';
import '../../../core/di/providers.dart';

class SettingsMetadataSection extends ConsumerWidget {
  const SettingsMetadataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Metadata Providers', style: Theme.of(context).textTheme.labelLarge),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('MusicBrainz'),
          subtitle: Text('Primary source — authoritative, no API key needed'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('iTunes'),
          subtitle: Text('Fallback source — good for Tamil/regional music'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('Fetch missing metadata now'),
          subtitle: const Text('MusicBrainz → iTunes → local ID3 fallback'),
          onTap: () => MetadataFetchRunner.run(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('View fetch history'),
          subtitle: const Text('See past metadata fetch runs and their results'),
          onTap: () => _showFetchHistory(context, ref),
        ),
      ],
    );
  }

  Future<void> _showFetchHistory(BuildContext context, WidgetRef ref) async {
    final historyRepo = await ref.read(metadataFetchHistoryRepositoryProvider.future);
    final runs = await historyRepo.getRecentRuns();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Metadata Fetch History'),
        content: SizedBox(
          width: double.maxFinite,
          child: runs.isEmpty
              ? const Text('No fetch runs yet. Tap "Fetch missing metadata now" to start.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: runs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = runs[i];
                    return ListTile(
                      dense: true,
                      title: Text(_formatDate(r.ranAt)),
                      subtitle: Text(
                        '${r.totalUpdated} updated · ${r.totalNoMatch} no match · '
                        '${r.totalErrors} errors  (${r.totalProcessed} total)',
                      ),
                      leading: Icon(
                        r.totalErrors > 0 ? Icons.warning_amber : Icons.check_circle,
                        color: r.totalErrors > 0 ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
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