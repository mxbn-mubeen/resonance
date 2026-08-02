import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../domain/entities/library_entities.dart';
import 'metadata_cleaner.dart';

/// Given a cleaned filename (+ any tags already on the file), queries
/// metadata sources in priority order and returns the best-scoring match.
///
/// Source priority (per design doc):
///   MusicBrainz -> iTunes -> AcoustID (future) -> Discogs (future)
class SongMatcher {
  final MusicBrainzApi musicBrainz;
  final ItunesApi itunes;

  SongMatcher({required this.musicBrainz, required this.itunes});

  Future<MetadataResult?> match({
    required String rawFilename,
    String? knownArtist,
    String? knownAlbum,
    Duration? knownDuration,
  }) async {
    final cleanedQuery = MetadataCleaner.clean(rawFilename);
    if (cleanedQuery.isEmpty) return null;

    // TODO(song_matcher): try MusicBrainz first (rate-limited to 1req/sec -
    // queue requests through a single-lane throttler), fall back to iTunes
    // on empty/low-confidence results. Below is the iTunes-only fast path;
    // wire in MusicBrainz + AcoustID/Discogs (future) alongside it.
    final candidates = await itunes.search(term: cleanedQuery, limit: 5);
    if (candidates.isEmpty) return null;

    MetadataResult? best;
    double bestScore = 0;

    for (final c in candidates) {
      final score = _score(
        candidateTitle: c['trackName'] as String? ?? '',
        candidateArtist: c['artistName'] as String? ?? '',
        candidateAlbum: c['collectionName'] as String?,
        candidateDurationMs: (c['trackTimeMillis'] as num?)?.toInt(),
        knownArtist: knownArtist,
        knownAlbum: knownAlbum,
        knownDuration: knownDuration,
      );
      if (score > bestScore) {
        bestScore = score;
        best = MetadataResult(
          id: '', // assigned on save by MetadataRepository
          officialTitle: c['trackName'] as String? ?? cleanedQuery,
          officialArtist: c['artistName'] as String? ?? 'Unknown Artist',
          album: c['collectionName'] as String?,
          genre: c['primaryGenreName'] as String?,
          year: _yearFrom(c['releaseDate'] as String?),
          track: c['trackNumber'] as int?,
          artworkUrl: c['artworkUrl100'] as String?,
          confidence: score,
          source: 'itunes',
        );
      }
    }

    return best;
  }

  /// Weighted scoring: Title, Artist, Album, Duration, Year
  /// (weights per design doc's "Scoring" section - tune empirically).
  double _score({
    required String candidateTitle,
    required String candidateArtist,
    String? candidateAlbum,
    int? candidateDurationMs,
    String? knownArtist,
    String? knownAlbum,
    Duration? knownDuration,
  }) {
    // TODO(song_matcher): replace with a proper fuzzy string similarity
    // (e.g. Jaro-Winkler / token-sort ratio) instead of naive equality.
    double score = 0.5; // base confidence for having any candidate at all

    if (knownArtist != null &&
        candidateArtist.toLowerCase().contains(knownArtist.toLowerCase())) {
      score += 0.2;
    }
    if (knownAlbum != null &&
        candidateAlbum != null &&
        candidateAlbum.toLowerCase().contains(knownAlbum.toLowerCase())) {
      score += 0.15;
    }
    if (knownDuration != null && candidateDurationMs != null) {
      final diff = (knownDuration.inMilliseconds - candidateDurationMs).abs();
      if (diff < 3000) score += 0.15; // within 3 seconds
    }

    return score.clamp(0.0, 1.0);
  }

  int? _yearFrom(String? releaseDate) {
    if (releaseDate == null || releaseDate.length < 4) return null;
    return int.tryParse(releaseDate.substring(0, 4));
  }
}
