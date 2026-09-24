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
        plainLyrics: r.plainLyrics,
        syncedLyrics: r.syncedLyrics,
        fetchAttemptCount: r.fetchAttemptCount,
        lastFetchAttemptAt: r.lastFetchAttemptAt,
      );

  Future<List<Song>> getAllSongs({bool includeHidden = false}) async {
    final query = includeHidden
        ? isar.songRecords.where()
        : isar.songRecords.filter().hiddenEqualTo(false);
    final records = await query.findAll();
    return records.map(_toEntity).toList();
  }

  Future<List<Song>> search(String queryText, {String filter = 'all'}) async {
    final words = queryText.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    var query = isar.songRecords.filter().hiddenEqualTo(false);

    for (final word in words) {
      if (filter == 'songs') {
        query = query.and().titleContains(word, caseSensitive: false);
      } else if (filter == 'artists') {
        query = query.and().artistContains(word, caseSensitive: false);
      } else if (filter == 'albums') {
        query = query.and().albumContains(word, caseSensitive: false);
      } else {
        query = query.and().group((q) => q
            .titleContains(word, caseSensitive: false)
            .or()
            .artistContains(word, caseSensitive: false)
            .or()
            .albumContains(word, caseSensitive: false));
      }
    }

    final records = await query.findAll();
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

  /// Persists lyrics found via LyricsManager (embedded tag, sidecar .lrc
  /// file, or LRCLIB online fetch) so they're only ever looked up once per
  /// song, not re-fetched every time the lyrics view opens.
  /// Called once per song after every metadata-fetch processing attempt,
  /// win or lose - this is what lets SongMetadataProcessor.needsMetadataFetch
  /// eventually stop retrying a song that genuinely has no online match and
  /// no artwork available anywhere, instead of reprocessing it forever.
  Future<void> recordFetchAttempt(String songId) async {
    await isar.writeTxn(() async {
      final rec = await isar.songRecords.get(int.parse(songId));
      if (rec == null) return;
      rec.fetchAttemptCount += 1;
      rec.lastFetchAttemptAt = DateTime.now();
      await isar.songRecords.put(rec);
    });
  }

  Future<void> updateLyrics(String songId, {String? plain, String? synced}) async {
    await isar.writeTxn(() async {
      final rec = await isar.songRecords.get(int.parse(songId));
      if (rec == null) return;
      if (plain != null) rec.plainLyrics = plain;
      if (synced != null) rec.syncedLyrics = synced;
      await isar.songRecords.put(rec);
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