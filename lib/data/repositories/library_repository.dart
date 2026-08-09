import 'package:isar/isar.dart';

import '../../domain/entities/song.dart';
import '../local/isar_schemas.dart';

/// Single source of truth for reading/writing the song library.
/// All screens/services go through this - nobody touches Isar directly
/// outside the data layer.
class LibraryRepository {
  final Isar isar;

  LibraryRepository(this.isar);

  Song _toEntity(SongRecord r) => Song(
        id: r.id.toString(),
        path: r.path,
        filename: r.filename,
        duration: Duration(milliseconds: r.durationMs),
        artist: r.artist,
        album: r.album,
        title: r.title,
        modified: r.modified,
        contentHash: r.contentHash,
        artworkPath: r.artworkPath,
        metadataId: r.metadataId?.toString(),
        favorite: r.favorite,
        playCount: r.playCount,
        rating: r.rating,
        hidden: r.hidden,
        bitrate: r.bitrate,
        codec: r.codec,
        sizeBytes: r.sizeBytes,
      );

  Future<List<Song>> getAllSongs({bool includeHidden = false}) async {
    final query = includeHidden
        ? isar.songRecords.where()
        : isar.songRecords.filter().hiddenEqualTo(false);
    final records = await query.findAll();
    return records.map(_toEntity).toList();
  }

  Future<List<Song>> search(String queryText) async {
    final records = await isar.songRecords
        .filter()
        .titleContains(queryText, caseSensitive: false)
        .or()
        .artistContains(queryText, caseSensitive: false)
        .or()
        .albumContains(queryText, caseSensitive: false)
        .findAll();
    return records.map(_toEntity).toList();
  }

  Future<void> upsertScannedSong({
    required String path,
    required String filename,
    required Duration duration,
    required DateTime modified,
    String? title,
    String? artist,
    String? album,
    int? bitrate,
    String? codec,
    int? sizeBytes,
    String? artworkPath,
  }) async {
    await isar.writeTxn(() async {
      final existing =
          await isar.songRecords.filter().pathEqualTo(path).findFirst();
      final record = existing ?? SongRecord();
      record
        ..path = path
        ..filename = filename
        ..durationMs = duration.inMilliseconds
        ..modified = modified
        ..title = title ?? filename
        ..artist = artist
        ..album = album
        ..bitrate = bitrate
        ..codec = codec
        ..sizeBytes = sizeBytes;
      if (artworkPath != null) {
        record.artworkPath = artworkPath;
      }
      await isar.songRecords.put(record);
    });
  }

  /// Removes songs whose file paths no longer exist on disk (part of the
  /// Scanner's "detect deleted songs" responsibility).
  Future<void> removeByPaths(List<String> deletedPaths) async {
    await isar.writeTxn(() async {
      for (final path in deletedPaths) {
        final rec =
            await isar.songRecords.filter().pathEqualTo(path).findFirst();
        if (rec != null) await isar.songRecords.delete(rec.id);
      }
    });
  }

  Future<void> toggleFavorite(String songId, bool value) async {
    await isar.writeTxn(() async {
      final rec = await isar.songRecords.get(int.parse(songId));
      if (rec != null) {
        rec.favorite = value;
        await isar.songRecords.put(rec);
      }
    });
  }

  Future<void> incrementPlayCount(String songId) async {
    await isar.writeTxn(() async {
      final rec = await isar.songRecords.get(int.parse(songId));
      if (rec != null) {
        rec.playCount += 1;
        await isar.songRecords.put(rec);
      }
    });
  }

  Stream<List<Song>> watchAllSongs() {
    return isar.songRecords
        .filter()
        .hiddenEqualTo(false)
        .watch(fireImmediately: true)
        .map((records) => records.map(_toEntity).toList());
  }
}
