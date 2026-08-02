import 'package:isar/isar.dart';

import '../../domain/entities/library_entities.dart';
import '../local/isar_schemas.dart';

class MetadataRepository {
  final Isar isar;

  MetadataRepository(this.isar);

  Future<String> saveMatch(MetadataResult result) async {
    late int id;
    await isar.writeTxn(() async {
      final record = MetadataRecord()
        ..officialTitle = result.officialTitle
        ..officialArtist = result.officialArtist
        ..album = result.album
        ..genre = result.genre
        ..year = result.year
        ..track = result.track
        ..artworkUrl = result.artworkUrl
        ..confidence = result.confidence
        ..source = result.source;
      id = await isar.metadataRecords.put(record);
    });
    return id.toString();
  }

  Future<MetadataResult?> getById(String id) async {
    final rec = await isar.metadataRecords.get(int.parse(id));
    if (rec == null) return null;
    return MetadataResult(
      id: rec.id.toString(),
      officialTitle: rec.officialTitle,
      officialArtist: rec.officialArtist,
      album: rec.album,
      genre: rec.genre,
      year: rec.year,
      track: rec.track,
      artworkUrl: rec.artworkUrl,
      confidence: rec.confidence,
      source: rec.source,
    );
  }
}
