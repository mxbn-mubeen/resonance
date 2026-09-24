import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/artwork/artist_image_service.dart';
import '../../application/artwork/artwork_manager.dart';
import '../../application/artwork/artwork_palette_service.dart';
import '../../application/duplicates/duplicate_detector.dart';
import '../../application/lyrics/lyrics_manager.dart';
import '../../application/metadata/song_matcher.dart';
import '../../application/playback/playback_controller.dart';
import '../../application/playlist/playlist_engine.dart';
import '../../application/recommendation/recommendation_engine.dart';
import '../../application/scanner/scanner_service.dart';
import '../../domain/entities/library_entities.dart';
import 'data_providers.dart';

// ---------- Application layer (engines & services) ----------

final artistImageServiceProvider = Provider<ArtistImageService>((ref) {
  final deezerApi = ref.watch(deezerApiProvider);
  return ArtistImageService(deezerApi);
});

final artistImageProvider = FutureProvider.family<String?, String>((ref, artistName) async {
  final service = ref.watch(artistImageServiceProvider);
  return service.getArtistImage(artistName);
});

final scannerServiceProvider = FutureProvider<ScannerService>((ref) async {
  final libraryRepo = await ref.watch(libraryRepositoryProvider.future);
  return ScannerService(libraryRepository: libraryRepo);
});

final songMatcherProvider = Provider<SongMatcher>((ref) {
  return SongMatcher(
    musicBrainz: ref.watch(musicBrainzApiProvider),
    itunes: ref.watch(itunesApiProvider),
  );
});

final artworkManagerProvider = Provider<ArtworkManager>((ref) => ArtworkManager());

final artworkPaletteServiceProvider = Provider<ArtworkPaletteService>((ref) => ArtworkPaletteService());

final lyricsManagerProvider = FutureProvider<LyricsManager>((ref) async {
  final libraryRepo = await ref.watch(libraryRepositoryProvider.future);
  return LyricsManager(
    lrcLibApi: ref.watch(lrcLibApiProvider),
    libraryRepository: libraryRepo,
  );
});

final duplicateDetectorProvider = Provider<DuplicateDetector>((ref) => DuplicateDetector());

final playlistEngineProvider = FutureProvider<PlaylistEngine>((ref) async {
  final playlistRepo = await ref.watch(playlistRepositoryProvider.future);
  final libraryRepo = await ref.watch(libraryRepositoryProvider.future);
  final historyRepo = await ref.watch(historyRepositoryProvider.future);
  final metadataRepo = await ref.watch(metadataRepositoryProvider.future);
  return PlaylistEngine(
    playlistRepository: playlistRepo,
    libraryRepository: libraryRepo,
    historyRepository: historyRepo,
    metadataRepository: metadataRepo,
  );
});

/// Activates a background subscription that logs play history whenever the
/// current track changes.
final historyLoggerProvider = Provider<void>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  String? lastLoggedSongId;

  final subscription = controller.mediaItem.listen((item) async {
    if (item == null || item.id == lastLoggedSongId) return;
    lastLoggedSongId = item.id;

    final historyRepo = await ref.read(historyRepositoryProvider.future);
    await historyRepo.logPlay(PlayHistoryEntry(
      songId: item.id,
      playedAt: DateTime.now(),
      listenedDuration: Duration.zero,
      skipped: false,
      completed: false,
    ));
  });

  ref.onDispose(subscription.cancel);
});

/// Infinite Auto-Play
final autoPlayManagerProvider = Provider<void>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  int? lastAppendedIndex;

  final subscription = controller.sequenceStateStream.listen((state) async {
    if (state == null || state.sequence.isEmpty) return;

    final currentIndex = state.currentIndex;
    final total = state.sequence.length;

    // Trigger when we reach the very last song in the queue
    if (currentIndex == total - 1 && lastAppendedIndex != currentIndex) {
      lastAppendedIndex = currentIndex;

      try {
        final recommendationEngine = await ref.read(recommendationEngineProvider.future);
        final suggestions = await recommendationEngine.suggestForYou(limit: 3);

        if (suggestions.isNotEmpty) {
          for (final song in suggestions) {
            await controller.addToQueue(song);
          }
        } else {
          // Fallback to random if no history/recommendations are available
          final library = await ref.read(libraryRepositoryProvider.future);
          final all = await library.getAllSongs();
          if (all.isNotEmpty) {
            all.shuffle();
            for (final song in all.take(3)) {
              await controller.addToQueue(song);
            }
          }
        }
      } catch (_) {
        // Silently fail if something goes wrong so playback isn't interrupted
      }
    }
  });

  ref.onDispose(subscription.cancel);
});

final recommendationEngineProvider = FutureProvider<RecommendationEngine>((ref) async {
  final historyRepo = await ref.watch(historyRepositoryProvider.future);
  final libraryRepo = await ref.watch(libraryRepositoryProvider.future);
  final metadataRepo = await ref.watch(metadataRepositoryProvider.future);
  return RecommendationEngine(
    historyRepository: historyRepo,
    libraryRepository: libraryRepo,
    metadataRepository: metadataRepo,
  );
});

/// The PlaybackController is a long-lived AudioHandler.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  throw UnimplementedError(
      'Override this in main.dart with the instance returned by AudioService.init()');
});
