import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/local/isar_schemas.dart';
import 'components/health_run_tile.dart';

class HealthHistoryScreen extends ConsumerStatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  ConsumerState<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends ConsumerState<HealthHistoryScreen> {
  List<LibraryHealthHistoryRecord>? _runs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() => _loading = true);
    try {
      final repo = await ref.read(libraryHealthHistoryRepositoryProvider.future);
      final runs = await repo.getRecentRuns(limit: 50);
      if (mounted) setState(() { _runs = runs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _runs = []; _loading = false; });
    }
  }

  Future<void> _deleteRun(LibraryHealthHistoryRecord r) async {
    final repo = await ref.read(libraryHealthHistoryRepositoryProvider.future);
    await repo.deleteRun(r.id);
    if (mounted) setState(() => _runs?.remove(r));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all health scan records? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repo = await ref.read(libraryHealthHistoryRepositoryProvider.future);
    await repo.clearHistory();
    if (mounted) setState(() => _runs = []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
        actions: [
          if (_runs != null && _runs!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all history',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_runs == null || _runs!.isEmpty)
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRuns,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _runs!.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final r = _runs![i];
                      return HealthRunTile(
                        record: r,
                        onDelete: () => _deleteRun(r),
                        theme: theme,
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.health_and_safety_outlined, size: 56, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Run a Library Health check to see your scan history here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
