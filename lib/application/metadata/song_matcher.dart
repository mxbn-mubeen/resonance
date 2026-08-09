import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../domain/entities/library_entities.dart';
import 'metadata_cleaner.dart';

/// Given a cleaned filename (+ any tags already on the file), queries
/// metadata sources in priority order and returns the best-scoring match.
///
/// Source priority (per design doc):
///   MusicBrainz → iTunes → AcoustID (future) → Discogs (future)
///
/// MusicBrainz is queried first (returns MBID-anchored data, no usage fees)
/// and falls back to iTunes when results are empty or low-confidence.
/// MusicBrainz caps at 1 req/sec — callers must ensure at least 1 s between
/// calls; the settings_screen already adds a 500 ms per-song delay which is
/// a reasonable start for batch runs.
class SongMatcher {
  final MusicBrainzApi musicBrainz;
  final ItunesApi itunes;

  SongMatcher({required this.musicBrainz, required this.itunes});

  /// Returns true when we are on Wi-Fi (or when the check can't be run).
  static Future<bool> isOnWifi() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (_) {
      return true; // fail-open: don't block if check throws
    }
  }

  Future<MetadataResult?> match({
    required String rawFilename,
    String? knownArtist,
    String? knownAlbum,
    Duration? knownDuration,
    /// When true, skip network calls and return null immediately.
    bool offlineMode = false,
  }) async {
    if (offlineMode) return null;

    final cleanedQuery = MetadataCleaner.clean(rawFilename);
    if (cleanedQuery.isEmpty) return null;

    // --- 1. Try MusicBrainz first (authoritative MBID data) ---
    MetadataResult? mbResult;
    try {
      final mbCandidates = await musicBrainz.searchRecording(
        title: cleanedQuery,
        artist: knownArtist,
        limit: 5,
      );

      for (final c in mbCandidates) {
        final title = c['title'] as String? ?? '';
        final artistCreditList = c['artist-credit'] as List?;
        final artistCredit = (artistCreditList != null && artistCreditList.isNotEmpty)
            ? artistCreditList.first
            : null;
        final artist = (artistCredit != null && artistCredit is Map)
            ? ((artistCredit['artist'] as Map?)?['name'] as String?) ?? ''
            : '';
        final releases = c['releases'] as List?;
        String? album;
        if (releases != null && releases.isNotEmpty) {
          final firstRelease = releases.first;
          if (firstRelease is Map) {
            album = firstRelease['title'] as String?;
          }
        }

        if (title.isEmpty) continue;

        final score = _score(
          candidateTitle: title,
          candidateArtist: artist,
          candidateAlbum: album,
          candidateDurationMs: ((c['length'] as num?)?.toInt()),
          knownArtist: knownArtist,
          knownAlbum: knownAlbum,
          knownDuration: knownDuration,
        );

        if (mbResult == null || score > mbResult.confidence) {
          mbResult = MetadataResult(
            id: '',
            officialTitle: title.isNotEmpty ? title : cleanedQuery,
            officialArtist: artist.isNotEmpty ? artist : 'Unknown Artist',
            album: album,
            confidence: score,
            source: 'musicbrainz',
          );
        }
      }
    } catch (_) {
      // MusicBrainz failed (rate-limit, network error) — fall through to iTunes
    }

    // If MusicBrainz returned a high-confidence result, use it.
    if (mbResult != null && mbResult.confidence >= 0.65) return mbResult;

    // --- 2. Fall back to iTunes ---
    try {
      // Throttle: give the previous MusicBrainz call at least 500 ms breathing
      // room so back-to-back calls respect the 1 req/sec policy.
      await Future.delayed(const Duration(milliseconds: 500));

      final candidates = await itunes.search(term: cleanedQuery, limit: 5);
      if (candidates.isEmpty) return mbResult; // return MB result even if low-confidence

      MetadataResult? best = mbResult;
      double bestScore = mbResult?.confidence ?? 0;

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
            id: '',
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
    } catch (_) {
      return mbResult; // return whatever MB gave us, even if low-confidence
    }
  }

  /// Weighted scoring: Title, Artist, Album, Duration
  double _score({
    required String candidateTitle,
    required String candidateArtist,
    String? candidateAlbum,
    int? candidateDurationMs,
    String? knownArtist,
    String? knownAlbum,
    Duration? knownDuration,
  }) {
    double score = 0.5; // base confidence for having any candidate at all

    if (knownArtist != null &&
        knownArtist.isNotEmpty &&
        candidateArtist.toLowerCase().contains(
            MetadataCleaner.clean(knownArtist).toLowerCase())) {
      score += 0.2;
    }
    if (knownAlbum != null &&
        knownAlbum.isNotEmpty &&
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
