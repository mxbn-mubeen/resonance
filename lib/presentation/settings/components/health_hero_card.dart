import 'package:flutter/material.dart';

class HealthHeroCard extends StatelessWidget {
  final int healthScore;
  final int totalSongs;
  final int totalIssues;
  final bool hasScanned;
  final bool isScanning;
  final VoidCallback onScan;

  const HealthHeroCard({
    super.key,
    required this.healthScore,
    required this.totalSongs,
    required this.totalIssues,
    required this.hasScanned,
    required this.isScanning,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = healthScore >= 90
        ? Colors.greenAccent
        : healthScore >= 70
            ? Colors.orangeAccent
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: hasScanned ? (healthScore / 100.0) : 0,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: scoreColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasScanned ? '$healthScore%' : '--',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const Text(
                    'HEALTH',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            !hasScanned
                ? 'Checking library health…'
                : healthScore == 100
                    ? 'Library is in pristine condition! 🎉'
                    : '$totalIssues issue${totalIssues == 1 ? '' : 's'} detected in library',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$totalSongs total tracks scanned',
            style: TextStyle(color: theme.textTheme.bodySmall?.color ?? Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isScanning ? null : onScan,
            icon: isScanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            label: Text(isScanning ? 'Diagnosing…' : 'Run Health Diagnostic'),
          ),
        ],
      ),
    );
  }
}

