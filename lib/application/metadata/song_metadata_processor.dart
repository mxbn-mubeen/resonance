import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/constants/app_constants.dart';
import '../../data/repositories/library_repository.dart';
import '../artwork/artwork_manager.dart';
import 'metadata_cleaner.dart';
import 'song_matcher.dart';

enum SongFetchOutcome { apiMatch, localId3, apiError }

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
  static bool needsMetadataFetch(dynamic song) {
    final a = (song.artist?.trim() as String? ?? '').toLowerCase();
    final t = (song.title?.trim() as String? ?? '').toLowerCase();
    final hasGarbage = kWebsiteBlacklist.any((site) => a.contains(site) || t.contains(site));
    final looksUnknown =
        a.isEmpty || a == 'unknown artist' || a == '<unknown>' || song.artworkPath == null || hasGarbage;
    if (!looksUnknown) return false;

    final attempts = (song.fetchAttemptCount as int?) ?? 0;
    if (attempts < _maxAttemptsBeforeCooldown) return true;

    final lastAttempt = song.lastFetchAttemptAt as DateTime?;
    if (lastAttempt == null) return true;
    return DateTime.now().difference(lastAttempt) >= _retryCooldown;
  }

  /// Processes a single song, fetching metadata and artwork, and upserting into the DB.
  /// Returns a [SingleSongProcessResult] indicating if the song was a no-match (used local ID3).
  /// Throws an exception if an error occurs.
  static Future<SingleSongProcessResult> processSong({
    required dynamic song,
    required LibraryRepository libraryRepo,
    required SongMatcher matcher,
    required ArtworkManager artworkMgr,
    required int maxDimension,
    required int jpegQuality,
  }) async {
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

    String finalTitle = song.title ?? song.filename;
    String finalArtist = song.artist ?? 'Unknown Artist';
    String? finalAlbum = song.album;
    bool isNoMatch = false;

    if (result != null) {
      finalTitle = result.officialTitle;
      finalArtist = result.officialArtist;
      finalAlbum = result.album;
    } else {
      isNoMatch = true;
      try {
        final metadata = readMetadata(File(song.path), getImage: false);
        final localArtist = metadata.artist?.trim() ?? '';
        final localTitle = metadata.title?.trim() ?? '';
        final localAlbum = metadata.album?.trim() ?? '';
        if (localTitle.isNotEmpty) finalTitle = MetadataCleaner.clean(localTitle);
        if (localArtist.isNotEmpty &&
            localArtist.toLowerCase() != 'unknown artist') {
          finalArtist = MetadataCleaner.clean(localArtist);
        }
        if (localAlbum.isNotEmpty) finalAlbum = MetadataCleaner.clean(localAlbum);
      } catch (_) {
        finalTitle = MetadataCleaner.clean(finalTitle);
        finalArtist = MetadataCleaner.clean(finalArtist);
      }
    }

    final outcome = result != null
        ? SongFetchOutcome.apiMatch
        : apiError != null
            ? SongFetchOutcome.apiError
            : SongFetchOutcome.localId3;

    String? localArtworkPath = song.artworkPath;
    if (localArtworkPath == null) {
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

    await libraryRepo.upsertScannedSong(
      path: song.path,
      filename: song.filename,
      duration: song.duration,
      modified: song.modified,
      title: finalTitle,
      artist: finalArtist,
      album: finalAlbum,
      artworkPath: localArtworkPath,
    );
    await libraryRepo.recordFetchAttempt(song.id);

    return SingleSongProcessResult(
      isNoMatch: isNoMatch,
      outcome: outcome,
      apiError: apiError,
    );
  }
}