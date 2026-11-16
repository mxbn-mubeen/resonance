import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/metadata/metadata_fetch_state.dart';
import 'components/metadata_fetch_stats_card.dart';
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
            MetadataFetchStatsCard(state: state),
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
    if (!state.isFetching && state.totalSongs > 0 && state.processedSongs == 0) {
      return Column(children: [
        const Icon(Icons.pending_actions, size: 64, color: Colors.orange),
        const SizedBox(height: 12),
        Text('${state.totalSongs} songs need metadata',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('Tap "Start Fetch" below to run MusicBrainz + iTunes matching.',
            style: TextStyle(fontSize: 12, color: Colors.white54), textAlign: TextAlign.center),
      ]);
    }
    if (state.isFetching) {
      final progress = state.totalSongs > 0 ? state.processedSongs / state.totalSongs : 0.0;
      return Column(children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 12),
        Text('Fetching metadata… ${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        if (state.currentSongTitle != null) ...[
          const SizedBox(height: 6),
          Text(state.currentSongTitle!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ]);
    }
    return Column(children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
      const SizedBox(height: 12),
      const Text('Fetch Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Elapsed: ${_formatElapsed(state.elapsedSeconds)}',
          style: const TextStyle(fontSize: 12, color: Colors.white54)),
    ]);
  }

  static String _formatElapsed(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
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
