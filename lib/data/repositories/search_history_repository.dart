import 'package:isar/isar.dart';

import '../local/isar_schemas.dart';

class SearchHistoryRepository {
  final Isar _isar;

  SearchHistoryRepository(this._isar);

  Future<void> saveQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    await _isar.writeTxn(() async {
      final record = SearchHistoryRecord()
        ..query = trimmed
        ..searchedAt = DateTime.now();
      await _isar.searchHistoryRecords.put(record);

      // Keep only top 15
      final all = await _isar.searchHistoryRecords.where().sortBySearchedAtDesc().findAll();
      if (all.length > 15) {
        final toDelete = all.skip(15).map((e) => e.id).toList();
        await _isar.searchHistoryRecords.deleteAll(toDelete);
      }
    });
  }

  Future<List<String>> getRecentQueries({int limit = 10}) async {
    final records = await _isar.searchHistoryRecords
        .where()
        .sortBySearchedAtDesc()
        .limit(limit)
        .findAll();
    return records.map((e) => e.query).toList();
  }

  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryRecords.clear();
    });
  }
}
