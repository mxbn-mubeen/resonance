import 'package:flutter/material.dart';

import '../health_history_screen.dart';
import '../library_health_screen.dart';

class SettingsHealthSection extends StatelessWidget {
  const SettingsHealthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Library Health', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety_rounded),
          title: const Text('Library Health Dashboard'),
          subtitle: const Text('Diagnostics for missing tags, duplicates, and broken art'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LibraryHealthScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text('View Health History'),
          subtitle: const Text('See past scan results and diagnostic records'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
          ),
        ),
      ],
    );
  }
}
