import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/di/providers.dart';
import '../../data/local/isar_schemas.dart';
import 'background_metadata_worker.dart';
import 'song_matcher.dart';
import 'song_metadata_processor.dart';

part 'metadata_fetch_state.g.dart';

class MetadataFetchState {
  final bool isFetching;
  final int totalSongs;
  final int processedSongs;
  final int updatedSongs;
  final int noMatchSongs;
  final int errorSongs;
  final String? firstError;
  final String? currentSongTitle;
  // New: breakdown of match source
  final int matchedByApi;
  final int matchedByLocal;
  final int matchedByApiError;
  // New: elapsed time in seconds
  final int elapsedSeconds;

  const MetadataFetchState({
    this.isFetching = false,
    this.totalSongs = 0,
    this.processedSongs = 0,
    this.updatedSongs = 0,
    this.noMatchSongs = 0,
    this.errorSongs = 0,
    this.firstError,
    this.currentSongTitle,
    this.matchedByApi = 0,
    this.matchedByLocal = 0,
    this.matchedByApiError = 0,
    this.elapsedSeconds = 0,
  });

  MetadataFetchState copyWith({
    bool? isFetching,
    int? totalSongs,
    int? processedSongs,
    int? updatedSongs,
    int? noMatchSongs,
    int? errorSongs,
    String? firstError,
    String? currentSongTitle,
    int? matchedByApi,
    int? matchedByLocal,
    int? matchedByApiError,
    int? elapsedSeconds,
  }) {
    return MetadataFetchState(
      isFetching: isFetching ?? this.isFetching,
      totalSongs: totalSongs ?? this.totalSongs,
      processedSongs: processedSongs ?? this.processedSongs,
      updatedSongs: updatedSongs ?? this.updatedSongs,
      noMatchSongs: noMatchSongs ?? this.noMatchSongs,
      errorSongs: errorSongs ?? this.errorSongs,
      firstError: firstError ?? this.firstError,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      matchedByApi: matchedByApi ?? this.matchedByApi,
      matchedByLocal: matchedByLocal ?? this.matchedByLocal,
      matchedByApiError: matchedByApiError ?? this.matchedByApiError,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

@riverpod
class MetadataFetchNotifier extends _$MetadataFetchNotifier {
  @override
  MetadataFetchState build() {
    return const MetadataFetchState();
  }

  Future<void> startFetch() async {
    if (state.isFetching) return;

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    final wifiOnly = ref.read(wifiOnlyDownloadsProvider);
    if (wifiOnly && !await SongMatcher.isOnWifi()) {
      throw Exception('Not on Wi-Fi. Turn off "Download on Wi-Fi only" to fetch on mobile data.');
    }

    final songs = ref.read(librarySongsProvider).valueOrNull ?? [];
    final unknown = songs.where(SongMetadataProcessor.needsMetadataFetch).toList();

    if (unknown.isEmpty) {
      throw Exception('All songs already have clean metadata and artwork!');
    }

    state = MetadataFetchState(
      isFetching: true,
      totalSongs: unknown.length,
      processedSongs: 0,
    );

    await Workmanager().registerOneOffTask(
      kMetadataFetchTaskName,
      kMetadataFetchTaskName,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    final libraryRepo = await ref.read(libraryRepositoryProvider.future);
    final matcher = ref.read(songMatcherProvider);
    final artworkMgr = ref.read(artworkManagerProvider);
    final artworkQuality = ref.read(artworkQualityProvider);

    int updated = 0;
    int noMatch = 0;
    int errors = 0;
    int apiMatch = 0;
    int localMatch = 0;
    int apiErrors = 0;
    String? firstError;
    String? apiErrorSample;
    final noMatchTitles = <String>[];
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < unknown.length; i++) {
      final song = unknown[i];
      state = state.copyWith(
        currentSongTitle: song.title ?? song.filename,
        elapsedSeconds: stopwatch.elapsed.inSeconds,
      );

      try {
        final singleResult = await BackgroundMetadataWorker.fetchLoop(
          songs: [song],
          libraryRepo: libraryRepo,
          matcher: matcher,
          artworkMgr: artworkMgr,
          maxDimension: artworkQuality.maxDimension,
          jpegQuality: artworkQuality.jpegQuality,
        );

        updated += singleResult.updated;
        noMatch += singleResult.noMatch;
        errors += singleResult.errors;
        firstError ??= singleResult.firstError;

        // Track per-song outcome using the richer result
        if (singleResult.lastOutcome == SongFetchOutcome.apiMatch) {
          apiMatch++;
        } else if (singleResult.lastOutcome == SongFetchOutcome.apiError) {
          apiErrors++;
          apiErrorSample ??= singleResult.lastApiError;
        } else {
          // SongFetchOutcome.skipped — API returned no match, song left as-is
          localMatch++;
        }

        if (singleResult.noMatch > 0 && noMatchTitles.length < 30) {
          noMatchTitles.add(song.title ?? song.filename);
        }
      } catch (e) {
        errors++;
        firstError ??= e.toString();
      }

      state = state.copyWith(
        processedSongs: i + 1,
        updatedSongs: updated,
        noMatchSongs: noMatch,
        errorSongs: errors,
        firstError: firstError,
        matchedByApi: apiMatch,
        matchedByLocal: localMatch,
        matchedByApiError: apiErrors,
        elapsedSeconds: stopwatch.elapsed.inSeconds,
      );
    }

    stopwatch.stop();

    try {
      final historyRepo = await ref.read(metadataFetchHistoryRepositoryProvider.future);
      final record = MetadataFetchHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalProcessed = unknown.length
        ..totalUpdated = updated
        ..totalNoMatch = noMatch
        ..totalErrors = errors
        ..firstError = firstError
        ..durationSeconds = stopwatch.elapsed.inSeconds
        ..matchedByApi = apiMatch
        ..matchedByLocal = localMatch
        ..noMatchSongTitles = noMatchTitles
        ..apiErrorSample = apiErrorSample;
      await historyRepo.saveRun(record);
    } catch (_) {}

    state = state.copyWith(
      isFetching: false,
      currentSongTitle: null,
      elapsedSeconds: stopwatch.elapsed.inSeconds,
    );
  }
}
