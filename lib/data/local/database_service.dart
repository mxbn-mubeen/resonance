import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_schemas.dart';

/// Opens/holds the single Isar instance. Injected via Riverpod as a
/// FutureProvider so every repository awaits the same instance.
class DatabaseService {
  Isar? _isar;

  Future<Isar> open() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        SongRecordSchema,
        MetadataRecordSchema,
        ArtistRecordSchema,
        AlbumRecordSchema,
        HistoryRecordSchema,
        PlaylistRecordSchema,
      ],
      directory: dir.path,
      name: 'offline_music_platform',
    );
    return _isar!;
  }

  Isar get instance {
    if (_isar == null) {
      throw StateError('DatabaseService.open() must be awaited before use.');
    }
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
