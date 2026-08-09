import 'package:isar/isar.dart';

import '../local/isar_schemas.dart';

/// Persists Library Health report runs so users can review history.
class LibraryHealthHistoryRepository {
  final Isar _isar;

  LibraryHealthHistoryRepository(this._isar);

  Future<void> saveRun(LibraryHealthHistoryRecord record) async {
    await _isar.writeTxn(() => _isar.libraryHealthHistoryRecords.put(record));
  }

  /// Returns the 20 most recent runs, newest first.
  Future<List<LibraryHealthHistoryRecord>> getRecentRuns({int limit = 20}) async {
    return _isar.libraryHealthHistoryRecords
        .where()
        .sortByRanAtDesc()
        .limit(limit)
        .findAll();
  }
}
