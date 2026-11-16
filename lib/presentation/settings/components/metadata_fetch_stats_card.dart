import 'package:flutter/material.dart';

import '../../../application/metadata/metadata_fetch_state.dart';

class MetadataFetchStatsCard extends StatelessWidget {
  final MetadataFetchState state;
  const MetadataFetchStatsCard({super.key, required this.state});

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
            _StatRow(
              label: 'Errors',
              value: '${state.errorSongs}',
              color: state.errorSongs > 0 ? Colors.red : null,
            ),
          ],
        ),
      ),
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
          child: Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
