import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/metadata/metadata_fetch_state.dart';
import 'metadata_history_screen.dart';

class MetadataFetchScreen extends ConsumerWidget {
  const MetadataFetchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metadataFetchNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Fetch Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusHeader(state: state),
            const SizedBox(height: 32),
            _StatsCard(state: state),
            if (state.firstError != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(error: state.firstError!),
            ],
            const SizedBox(height: 16),
            if (!state.isFetching) ...[
              _StartButton(
                onStart: () async {
                  try {
                    await ref.read(metadataFetchNotifierProvider.notifier).startFetch();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MetadataHistoryScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('View Fetch History'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final MetadataFetchState state;
  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isFetching && state.totalSongs == 0) {
      return const Column(children: [
        Icon(Icons.info_outline, size: 64, color: Colors.blue),
        SizedBox(height: 12),
        Text('Ready to Fetch', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]);
    }

    if (state.isFetching) {
      return Column(children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        const Text('Fetching Metadata…', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        if (state.currentSongTitle != null) ...[
          const SizedBox(height: 8),
          Text('Processing: ${state.currentSongTitle}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Text(_formatElapsed(state.elapsedSeconds),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
      ]);
    }

    return Column(children: [
      const Icon(Icons.check_circle, size: 64, color: Colors.green),
      const SizedBox(height: 12),
      Text(state.totalSongs == 0 ? 'Nothing to fetch' : 'Fetch Complete ✅',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text('Took ${_formatElapsed(state.elapsedSeconds)}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
    ]);
  }

  static String _formatElapsed(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _StatsCard extends StatelessWidget {
  final MetadataFetchState state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final showBreakdown = state.processedSongs > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow(label: 'Total Pending', value: '${state.totalSongs}'),
            const Divider(height: 20),
            _StatRow(label: 'Processed', value: '${state.processedSongs}'),
            if (showBreakdown) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceChip(label: 'API Match', count: state.matchedByApi, color: Colors.green),
                  _SourceChip(label: 'Skipped', count: state.matchedByLocal, color: Colors.blue),
                  _SourceChip(label: 'API Error', count: state.matchedByApiError, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _StatRow(label: 'No Match', value: '${state.noMatchSongs}'),
            _StatRow(label: 'Errors', value: '${state.errorSongs}',
                color: state.errorSongs > 0 ? Colors.red : null),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 16),
              SizedBox(width: 6),
              Text('First Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ]),
            const SizedBox(height: 6),
            Text(error, style: const TextStyle(fontSize: 12), maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onStart;
  const _StartButton({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onStart,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Fetch'),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SourceChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
