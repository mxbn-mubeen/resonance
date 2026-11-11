import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_repository.dart';
import '../../domain/entities/library_entities.dart';
import '../artwork/artwork_manager.dart';
import 'song_matcher.dart';

enum SongFetchOutcome { apiMatch, skipped, apiError }

class SingleSongProcessResult {
  final bool isNoMatch;
  final SongFetchOutcome outcome;
  final String? apiError;

  const SingleSongProcessResult({
    required this.isNoMatch,
    required this.outcome,
    this.apiError,
  });
}

class SongMetadataProcessor {
  const SongMetadataProcessor._();

  /// A song stops being auto-retried after this many attempts, until
  /// [_retryCooldown] has passed since the last attempt. Without this cap,
  /// a song with no online match AND no artwork available anywhere (embedded
  /// or online) matches this filter forever - artworkPath never becomes
  /// non-null no matter how many times it's retried - so it gets
  /// reprocessed on EVERY single fetch run indefinitely, burning API calls
  /// and time on a song that will never resolve while other genuinely
  /// fixable songs wait behind it in the queue.
  static const _maxAttemptsBeforeCooldown = 3;
  static const _retryCooldown = Duration(days: 7);

  /// Single source of truth for "does this song need a metadata fetch" -
  /// previously duplicated (and able to drift out of sync) between
  /// metadata_fetch_runner.dart's pre-flight count and
  /// background_metadata_worker.dart's actual processing loop.
  ///
  /// A song needs a fetch if ANY of the following is true:
  ///   - artist is empty / unknown / contains garbage site tags
  ///   - no artwork cached
  ///   - never successfully matched via API (metadataId == null)
  ///
  /// Songs that only ever got local-ID3 names (prior runs applied fallback)
  /// are therefore correctly re-queued for an API attempt, since they will
  /// have no metadataId even though they may have a non-empty artist string.
  static bool needsMetadataFetch(dynamic song) {
    final a = (song.artist?.trim() as String? ?? '').toLowerCase();
    final t = (song.title?.trim() as String? ?? '').toLowerCase();
    final hasGarbage = kWebsiteBlacklist.any((site) => a.contains(site) || t.contains(site));

    // A song is considered needing a fetch if its tags look bad OR if it
    // has never been confirmed by an API match (metadataId == null).
    final neverApiMatched = song.metadataId == null;
    final looksUnknown =
        a.isEmpty || a == 'unknown artist' || a == '<unknown>' || song.artworkPath == null || hasGarbage;

    if (!looksUnknown && !neverApiMatched) return false;

    final attempts = (song.fetchAttemptCount as int?) ?? 0;
    if (attempts < _maxAttemptsBeforeCooldown) return true;

    final lastAttempt = song.lastFetchAttemptAt as DateTime?;
    if (lastAttempt == null) return true;
    return DateTime.now().difference(lastAttempt) >= _retryCooldown;
  }

  /// Processes a single song: calls the API (MusicBrainz → iTunes) and, if
  /// a match is found, writes updated title/artist/album/artwork to the DB.
  ///
  /// **No local ID3 fallback.** If the API returns no match the song's
  /// existing tags are left untouched — only embedded artwork is extracted
  /// (purely offline, no network) and cached if the song has none yet.
  /// The fetch attempt counter is always incremented so the cooldown logic
  /// in [needsMetadataFetch] eventually stops retrying hopeless songs.
  ///
  /// Throws if an unexpected exception escapes (callers should catch).
  static Future<SingleSongProcessResult> processSong({
    required dynamic song,
    required LibraryRepository libraryRepo,
    required SongMatcher matcher,
    required ArtworkManager artworkMgr,
    required int maxDimension,
    required int jpegQuality,
  }) async {
    // --- 1. API lookup ---
    dynamic result;
    String? apiError;
    try {
      result = await matcher.match(
        rawFilename: song.filename,
        knownArtist: song.artist,
        knownAlbum: song.album,
        knownDuration: song.duration,
      );
    } catch (e) {
      result = null;
      apiError = e.toString();
    }

    final bool isNoMatch = result == null;

    final outcome = result != null
        ? SongFetchOutcome.apiMatch
        : apiError != null
            ? SongFetchOutcome.apiError
            : SongFetchOutcome.skipped;

    // --- 2. Artwork: always try embedded first (offline), then API URL ---
    String? localArtworkPath = song.artworkPath;
    if (localArtworkPath == null) {
      // Extract embedded artwork regardless of whether the API matched.
      try {
        final metadataImg = readMetadata(File(song.path), getImage: true);
        final pictures = metadataImg.pictures;
        if (pictures.isNotEmpty) {
          final rawBytes = pictures.first.bytes;
          if (rawBytes.isNotEmpty) {
            localArtworkPath = await artworkMgr.saveCompressedBytes(
              rawBytes,
              song.id,
              maxDimension: maxDimension,
              jpegQuality: jpegQuality,
            );
          }
        }
      } catch (_) {}

      // Only download API artwork when we have an actual match.
      if (localArtworkPath == null && result != null && result.artworkUrl != null) {
        try {
          localArtworkPath = await artworkMgr.downloadAndCache(
            artworkUrl: result.artworkUrl!,
            cacheKey: song.id,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          );
        } catch (_) {}
      }
    }

    // --- 3. Persist — only write tags when API matched; skip upsert otherwise ---
    if (result != null) {
      int? savedMetadataId;
      try {
        final metaRepo = MetadataRepository(libraryRepo.isar);
        final idStr = await metaRepo.saveMatch(result as MetadataResult);
        savedMetadataId = int.tryParse(idStr);
      } catch (_) {}

      await libraryRepo.upsertScannedSong(
        path: song.path,
        filename: song.filename,
        duration: song.duration,
        modified: song.modified,
        title: result.officialTitle,
        artist: result.officialArtist,
        album: result.album,
        artworkPath: localArtworkPath,
        metadataId: savedMetadataId,
      );
    } else if (localArtworkPath != null && localArtworkPath != song.artworkPath) {
      // API missed but we found embedded artwork — persist only the artwork.
      await libraryRepo.upsertScannedSong(
        path: song.path,
        filename: song.filename,
        duration: song.duration,
        modified: song.modified,
        title: song.title ?? song.filename,
        artist: song.artist,
        album: song.album,
        artworkPath: localArtworkPath,
      );
    }

    await libraryRepo.recordFetchAttempt(song.id);

    return SingleSongProcessResult(
      isNoMatch: isNoMatch,
      outcome: outcome,
      apiError: apiError,
    );
  }
}