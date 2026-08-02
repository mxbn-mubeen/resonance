import 'package:isar/isar.dart';

import '../../domain/entities/library_entities.dart';
import '../local/isar_schemas.dart';

class HistoryRepository {
  final Isar isar;

  HistoryRepository(this.isar);

  Future<void> logPlay(PlayHistoryEntry entry) async {
    await isar.writeTxn(() async {
      await isar.historyRecords.put(HistoryRecord()
        ..songId = int.parse(entry.songId)
        ..playedAt = entry.playedAt
        ..listenedMs = entry.listenedDuration.inMilliseconds
        ..skipped = entry.skipped
        ..completed = entry.completed);
    });
  }

  /// Backs "Most Played" / "Recently Played" / "Never Played" auto playlists
  /// and the Statistics screen (hours listened, top artists/albums).
  Future<List<HistoryRecord>> recent({int limit = 100}) async {
    return isar.historyRecords
        .where()
        .sortByPlayedAtDesc()
        .limit(limit)
        .findAll();
  }
}
