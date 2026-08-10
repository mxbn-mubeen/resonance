import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../domain/entities/library_entities.dart';
import 'metadata_cleaner.dart';

/// Given a cleaned filename (+ any tags already on the file), queries
/// metadata sources in priority order and returns the best-scoring match.
///
/// Source priority (per design doc):
///   MusicBrainz → iTunes (multi-storefront)
///
/// MusicBrainz is queried first (returns MBID-anchored data, global/
/// language-agnostic catalog, no usage fees, and community-maintained so it
/// tends to have surprisingly good coverage of niche content like anime
/// openings/endings and eurobeat compilations that mainstream storefronts
/// miss) and falls back to iTunes when results are empty or low-confidence.
///
/// iTunes' catalog is split per-country storefront - querying only one
/// storefront (e.g. always 'in') means missing anything not licensed for
/// that specific country, which is a real problem for a library spanning
/// Tamil/Hindi/Telugu/Malayalam, English, Russian, Arabic, and anime/
/// eurobeat all at once. [_storefrontsToTry] tries a small ordered set and
/// stops as soon as a high-confidence match is found, rather than either
/// guessing one country or querying every storefront on every song (which
/// would multiply request volume for no benefit on the common case).
///
/// MusicBrainz caps at 1 req/sec — callers must ensure at least 1 s between
/// calls; the settings_screen already adds a 500 ms per-song delay which is
/// a reasonable start for batch runs.
class SongMatcher {
  final MusicBrainzApi musicBrainz;
  final ItunesApi itunes;

  SongMatcher({required this.musicBrainz, required this.itunes});

  /// Ordered storefront attempts. 'in' first since it's the broadest single
  /// catalog for the Indian-language content in this library (Tamil/Hindi/
  /// Telugu/Malayalam all ship on the India storefront, not split per-
  /// language) and also carries a lot of English content. 'us' next as the
  /// broadest general-purpose catalog. 'jp' specifically for anime OST/
  /// eurobeat - most anime music labels (Avex, King Records, Lantis, etc.)
  /// license primarily to the Japan storefront. 'ru' and 'ae' round out
  /// Russian and Arabic-market content.
  ///
  /// This list is intentionally short - each additional storefront tried
  /// is a full extra network round-trip per song, so this stops at "covers
  /// the stated library languages" rather than trying all ~175 storefronts.
  static const List<String> _storefrontsToTry = ['in', 'us', 'jp', 'ru', 'ae'];

  /// Confidence at/above which a storefront result is accepted immediately
  /// without trying the remaining storefronts.
  static const double _earlyStopConfidence = 0.85;

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

    // --- 1. Try MusicBrainz first (authoritative, language-agnostic) ---
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

    // If MusicBrainz returned a high-confidence result, use it - no need to
    // burn iTunes storefront calls when we already have a good answer.
    if (mbResult != null && mbResult.confidence >= 0.65) return mbResult;

    // --- 2. Fall back to iTunes, trying storefronts in order ---
    MetadataResult? best = mbResult;
    double bestScore = mbResult?.confidence ?? 0;

    // Throttle once before the first iTunes call to give MusicBrainz's
    // 1 req/sec policy breathing room after the call above.
    await Future.delayed(const Duration(milliseconds: 500));

    for (final country in _storefrontsToTry) {
      try {
        final candidates = await itunes.search(term: cleanedQuery, limit: 5, country: country);

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
              source: 'itunes ($country)',
            );
          }
        }
      } catch (_) {
        // This storefront failed (network hiccup, rate limit) - move on to
        // the next one rather than aborting the whole match attempt.
      }

      if (bestScore >= _earlyStopConfidence) break; // good enough, stop trying more storefronts

      // iTunes' unauthenticated search endpoint has an unofficial per-IP
      // rate limit; a short gap between storefront attempts for the same
      // song is cheap insurance against getting throttled mid-scan.
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return best;
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