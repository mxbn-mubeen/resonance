import 'package:flutter/material.dart';

import '../../../data/local/isar_schemas.dart';

class HealthRunExpandedDetail extends StatelessWidget {
  final LibraryHealthHistoryRecord record;
  final Color scoreColor;

  const HealthRunExpandedDetail({
    super.key,
    required this.record,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    final dateStr =
        '${r.ranAt.toLocal().day.toString().padLeft(2, '0')}/'
        '${r.ranAt.toLocal().month.toString().padLeft(2, '0')}/'
        '${r.ranAt.toLocal().year}  '
        '${r.ranAt.toLocal().hour.toString().padLeft(2, '0')}:'
        '${r.ranAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.label_off_rounded,
            label: 'Missing Tags',
            value: r.missingTags,
            issueColor: Colors.orangeAccent,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.broken_image_rounded,
            label: 'Broken Artwork',
            value: r.brokenArtwork,
            issueColor: Colors.redAccent,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.content_copy_rounded,
            label: 'Duplicates',
            value: r.duplicates,
            issueColor: Colors.orangeAccent,
          ),
          const SizedBox(height: 10),
          if (r.totalSongs > 0)
            _IssueBar(
              totalSongs: r.totalSongs,
              missingTags: r.missingTags,
              brokenArtwork: r.brokenArtwork,
              duplicates: r.duplicates,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color issueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.issueColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = value > 0 ? issueColor : Colors.greenAccent;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _IssueBar extends StatelessWidget {
  final int totalSongs;
  final int missingTags;
  final int brokenArtwork;
  final int duplicates;

  const _IssueBar({
    required this.totalSongs,
    required this.missingTags,
    required this.brokenArtwork,
    required this.duplicates,
  });

  @override
  Widget build(BuildContext context) {
    final clean = (totalSongs - missingTags - brokenArtwork - duplicates).clamp(0, totalSongs);
    final total = totalSongs.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Breakdown', style: TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              _BarSegment(flex: clean, total: total, color: Colors.greenAccent),
              _BarSegment(flex: missingTags, total: total, color: Colors.orangeAccent),
              _BarSegment(flex: brokenArtwork, total: total, color: Colors.redAccent),
              _BarSegment(flex: duplicates, total: total, color: Colors.amber),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarSegment extends StatelessWidget {
  final int flex;
  final double total;
  final Color color;

  const _BarSegment({required this.flex, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    if (flex <= 0 || total <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(height: 6, color: color),
    );
  }
}
