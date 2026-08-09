import 'package:isar/isar.dart';

import '../local/isar_schemas.dart';

/// Persists runs of the "Fetch missing metadata" action so users can review
/// history in Settings.
class MetadataFetchHistoryRepository {
  final Isar _isar;

  MetadataFetchHistoryRepository(this._isar);

  Future<void> saveRun(MetadataFetchHistoryRecord record) async {
    await _isar.writeTxn(() => _isar.metadataFetchHistoryRecords.put(record));
  }

  /// Returns the 20 most recent runs, newest first.
  Future<List<MetadataFetchHistoryRecord>> getRecentRuns({int limit = 20}) async {
    return _isar.metadataFetchHistoryRecords
        .where()
        .sortByRanAtDesc()
        .limit(limit)
        .findAll();
  }
}
