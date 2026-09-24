import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import 'background_notification_service.dart';
import 'metadata_fetch_result.dart';
import 'song_metadata_processor.dart';

import '../../data/local/isar_schemas.dart';
import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_fetch_history_repository.dart';
import '../artwork/artwork_manager.dart';
import '../metadata/song_matcher.dart';

/// Task name constant shared between the dispatcher and the runner.
const kMetadataFetchTaskName = 'fetchMissingMetadata';

/// WorkManager entry point. Runs in a background isolate with NO BuildContext
/// and NO Riverpod. All dependencies are constructed manually.
///
/// The @pragma annotation prevents tree-shaking in release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kMetadataFetchTaskName) return true;

    final stopwatch = Stopwatch()..start();

    WidgetsFlutterBinding.ensureInitialized();

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        SongRecordSchema,
        MetadataRecordSchema,
        ArtistRecordSchema,
        AlbumRecordSchema,
        HistoryRecordSchema,
        PlaylistRecordSchema,
        MetadataFetchHistoryRecordSchema,
        LibraryHealthHistoryRecordSchema,
        SearchHistoryRecordSchema,
      ],
      directory: dir.path,
      name: 'resonance',
    );

    try {
      final libraryRepo = LibraryRepository(isar);
      final historyRepo = MetadataFetchHistoryRepository(isar);
      final matcher = SongMatcher(
        musicBrainz: MusicBrainzApi(),
        itunes: ItunesApi(),
      );
      final artworkMgr = ArtworkManager();

      final songs = await libraryRepo.getAllSongs();
      final unknown = songs.where(SongMetadataProcessor.needsMetadataFetch).toList();

      if (unknown.isEmpty) {
        return true;
      }

      final result = await BackgroundMetadataWorker.fetchLoop(
        songs: unknown,
        libraryRepo: libraryRepo,
        matcher: matcher,
        artworkMgr: artworkMgr,
        maxDimension: 600,
        jpegQuality: 85,
        stopwatch: stopwatch,
        timeLimitMinutes: 9,
        onProgress: (processed, total) {
          BackgroundNotificationService.postProgressNotification(processed, total);
        },
      );

      final record = MetadataFetchHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalProcessed = result.processed
        ..totalUpdated = result.updated
        ..totalNoMatch = result.noMatch
        ..totalErrors = result.errors
        ..firstError = result.firstError;
      await historyRepo.saveRun(record);

      await BackgroundNotificationService.postNotification(result);
      
      if (result.abortedByTimeout) {
        // Explicitly queue a new task to continue the batch instead of failing.
        // This avoids Android's exponential backoff making us wait hours between batches.
        await Workmanager().registerOneOffTask(
          '${kMetadataFetchTaskName}_continuation_${DateTime.now().millisecondsSinceEpoch}',
          kMetadataFetchTaskName,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(networkType: NetworkType.connected),
        );
        return true;
      }
    } finally {
      await isar.close();
    }

    return true;
  });
}

/// Static helpers shared between [callbackDispatcher] (background isolate)
/// and [MetadataFetchRunner] (foreground) to avoid duplicating the fetch loop.
class BackgroundMetadataWorker {
  const BackgroundMetadataWorker._();

  /// Core per-song fetch loop. No Flutter/Riverpod dependencies.
  static Future<MetadataFetchResult> fetchLoop({
    required List<dynamic> songs,
    required LibraryRepository libraryRepo,
    required SongMatcher matcher,
    required ArtworkManager artworkMgr,
    required int maxDimension,
    required int jpegQuality,
    Stopwatch? stopwatch,
    int? timeLimitMinutes,
    Function(int processed, int total)? onProgress,
  }) async {
    int processed = 0;
    int updated = 0;
    int noMatch = 0;
    int errors = 0;
    String? firstError;
    bool abortedByTimeout = false;
    SongFetchOutcome? lastOutcome;
    String? lastApiError;

    // Show initial notification before processing starts
    if (onProgress != null) {
      onProgress(0, songs.length);
    }

    for (final song in songs) {
      if (stopwatch != null && timeLimitMinutes != null) {
        if (stopwatch.elapsed.inMinutes >= timeLimitMinutes) {
          abortedByTimeout = true;
          break;
        }
      }
      try {
        final songResult = await SongMetadataProcessor.processSong(
          song: song,
          libraryRepo: libraryRepo,
          matcher: matcher,
          artworkMgr: artworkMgr,
          maxDimension: maxDimension,
          jpegQuality: jpegQuality,
        );
        if (songResult.isNoMatch) {
          noMatch++;
        }
        updated++;
        lastOutcome = songResult.outcome;
        lastApiError = songResult.apiError;
      } catch (e) {
        errors++;
        firstError ??= e.toString();
        lastOutcome = SongFetchOutcome.apiError;
        lastApiError = e.toString();
      }
      
      processed++;
      // Update progress frequently (every 3 songs) or on the very last song
      if ((processed % 3 == 0 || processed == songs.length) && onProgress != null) {
        onProgress(processed, songs.length);
      }
    }

    return MetadataFetchResult(
      processed: processed,
      updated: updated,
      noMatch: noMatch,
      errors: errors,
      firstError: firstError,
      abortedByTimeout: abortedByTimeout,
      lastOutcome: lastOutcome,
      lastApiError: lastApiError,
    );
  }
}
