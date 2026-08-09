import 'package:isar/isar.dart';

import '../../domain/entities/library_entities.dart';
import '../local/isar_schemas.dart';

class PlaylistRepository {
  final Isar isar;

  PlaylistRepository(this.isar);

  PlaylistEntity _toEntity(PlaylistRecord r) => PlaylistEntity(
        id: r.id.toString(),
        name: r.name,
        songIds: r.songIdsOrdered.map((e) => e.toString()).toList(),
        isAuto: r.isAuto,
        isAiGenerated: r.isAiGenerated,
      );

  Future<List<PlaylistEntity>> getAll() async {
    final records = await isar.playlistRecords.where().findAll();
    return records.map(_toEntity).toList();
  }

  Future<String> createManual(String name) async {
    late int id;
    await isar.writeTxn(() async {
      id = await isar.playlistRecords
          .put(PlaylistRecord()..name = name..songIdsOrdered = []);
    });
    return id.toString();
  }

  Future<void> addSong(String playlistId, String songId) async {
    await isar.writeTxn(() async {
      final rec = await isar.playlistRecords.get(int.parse(playlistId));
      if (rec == null) return;
      final sid = int.parse(songId);
      if (!rec.songIdsOrdered.contains(sid)) {
        rec.songIdsOrdered = [...rec.songIdsOrdered, sid];
        await isar.playlistRecords.put(rec);
      }
    });
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await isar.writeTxn(() async {
      final rec = await isar.playlistRecords.get(int.parse(playlistId));
      if (rec == null) return;
      final sid = int.parse(songId);
      rec.songIdsOrdered = rec.songIdsOrdered.where((e) => e != sid).toList();
      await isar.playlistRecords.put(rec);
    });
  }

  Future<void> reorder(String playlistId, List<String> newOrderSongIds) async {
    await isar.writeTxn(() async {
      final rec = await isar.playlistRecords.get(int.parse(playlistId));
      if (rec == null) return;
      rec.songIdsOrdered = newOrderSongIds.map(int.parse).toList();
      await isar.playlistRecords.put(rec);
    });
  }

  Future<void> delete(String playlistId) async {
    await isar.writeTxn(() async {
      await isar.playlistRecords.delete(int.parse(playlistId));
    });
  }

  Future<void> rename(String playlistId, String newName) async {
    await isar.writeTxn(() async {
      final rec = await isar.playlistRecords.get(int.parse(playlistId));
      if (rec == null) return;
      rec.name = newName;
      await isar.playlistRecords.put(rec);
    });
  }
}
