import 'package:flutter/material.dart';

import '../../../data/local/isar_schemas.dart';
import 'health_run_expanded_detail.dart';

class HealthRunTile extends StatefulWidget {
  final LibraryHealthHistoryRecord record;
  final VoidCallback onDelete;
  final ThemeData theme;

  const HealthRunTile({
    super.key,
    required this.record,
    required this.onDelete,
    required this.theme,
  });

  @override
  State<HealthRunTile> createState() => _HealthRunTileState();
}

class _HealthRunTileState extends State<HealthRunTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final totalIssues = r.missingTags + r.brokenArtwork + r.duplicates;
    final healthScore = r.totalSongs > 0
        ? (((r.totalSongs - totalIssues).clamp(0, r.totalSongs) / r.totalSongs) * 100).round()
        : 100;
    final hasIssues = totalIssues > 0;
    final scoreColor = healthScore >= 90
        ? Colors.greenAccent
        : healthScore >= 70
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: healthScore / 100,
                          strokeWidth: 3.5,
                          backgroundColor: scoreColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                        Text(
                          '$healthScore',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatRelativeTime(r.ranAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.totalSongs} songs · ${hasIssues ? '$totalIssues issues' : 'No issues'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasIssues ? Colors.orangeAccent : Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            HealthRunExpandedDetail(
              record: r,
              scoreColor: scoreColor,
            ),
        ],
      ),
    );
  }
}

String formatRelativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt.toLocal());
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final l = dt.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}
