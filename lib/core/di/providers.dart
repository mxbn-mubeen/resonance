import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../../application/artwork/artwork_manager.dart';
import '../../application/artwork/artwork_palette_service.dart';
import '../../application/duplicates/duplicate_detector.dart';
import '../../application/lyrics/lyrics_manager.dart';
import '../../application/metadata/metadata_cleaner.dart';
import '../../application/metadata/song_matcher.dart';
import '../../application/playback/playback_controller.dart';
import '../../application/playlist/playlist_engine.dart';
import '../../application/recommendation/recommendation_engine.dart';
import '../../application/scanner/scanner_service.dart';
import '../../data/local/database_service.dart';
import '../../data/local/isar_schemas.dart';
import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_health_history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_fetch_history_repository.dart';
import '../../data/repositories/metadata_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/search_history_repository.dart';
import '../../domain/entities/library_entities.dart';
import '../../domain/entities/song.dart';
import '../theme/app_theme.dart';

// ---------- Data layer ----------

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final isarProvider = FutureProvider<Isar>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.open();
});

final libraryRepositoryProvider = FutureProvider<LibraryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return LibraryRepository(isar);
});

final metadataRepositoryProvider = FutureProvider<MetadataRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MetadataRepository(isar);
});

final playlistRepositoryProvider = FutureProvider<PlaylistRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PlaylistRepository(isar);
});

final historyRepositoryProvider = FutureProvider<HistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return HistoryRepository(isar);
});

final metadataFetchHistoryRepositoryProvider =
    FutureProvider<MetadataFetchHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MetadataFetchHistoryRepository(isar);
});

final libraryHealthHistoryRepositoryProvider =
    FutureProvider<LibraryHealthHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return LibraryHealthHistoryRepository(isar);
});

final searchHistoryRepositoryProvider =
    FutureProvider<SearchHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return SearchHistoryRepository(isar);
});

// ---------- Reactive Streams ----------

final playlistsStreamProvider = StreamProvider<List<PlaylistEntity>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final repo = await ref.watch(playlistRepositoryProvider.future);

  // Use Isar's collection watch via the generated collection accessor.
  await for (final _ in isar.collection<PlaylistRecord>().watchLazy(fireImmediately: true)) {
    yield await repo.getAll();
  }
});

// ---------- Remote clients ----------

final itunesApiProvider = Provider<ItunesApi>((ref) => ItunesApi());
final musicBrainzApiProvider = Provider<MusicBrainzApi>((ref) => MusicBrainzApi());

// ---------- Application layer (engines) ----------

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

final lyricsManagerProvider = Provider<LyricsManager>((ref) => LyricsManager());

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
/// current track changes. This is the actual fix for "Recently Played"
/// (PlaylistEngine.recentlyPlayed) ever returning results -
/// `historyRepository.logPlay()` previously existed but was never called
/// from anywhere. Centralizing it here means every play-start path
/// (Library, Search, Playlists, Home, Group detail...) gets history
/// logging for free instead of each screen needing to remember to call it
/// individually.
///
/// Must be activated once - see `ref.watch(historyLoggerProvider)` in
/// app.dart's build method - a Provider with no watchers never runs.
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
      // TODO(history_logger): true listened-duration/skipped/completed
      // tracking needs to watch playbackState until the NEXT track change
      // (or pause+long-idle) and compute the delta - logging zero/false
      // here is honest about what's actually measured today, not a
      // fabricated value.
      listenedDuration: Duration.zero,
      skipped: false,
      completed: false,
    ));
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

/// The PlaybackController is a long-lived AudioHandler; in a full app this
/// should be created once via `AudioService.init()` in main.dart and
/// exposed here as a plain value, not constructed fresh per rebuild.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  throw UnimplementedError(
      'Override this in main.dart with the instance returned by AudioService.init()');
});

// ---------- Presentation-facing state ----------

final librarySongsProvider = StreamProvider<List<Song>>((ref) async* {
  final repo = await ref.watch(libraryRepositoryProvider.future);
  yield* repo.watchAllSongs();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final repo = await ref.watch(libraryRepositoryProvider.future);
  return repo.search(query);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

class AccentColorNotifier extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final val = prefs.getInt('accent_color');
    return val != null ? Color(val) : AppTheme.defaultAccent;
  }

  Future<void> setColor(Color c) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    await prefs.setInt('accent_color', c.value);
    state = AsyncValue.data(c);
  }
}

final accentColorProvider = AsyncNotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class IncludedFoldersNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getStringList('included_folders') ?? [];
  }

  Future<void> addFolder(String path) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (!current.contains(path)) {
      final updated = [...current, path];
      await prefs.setStringList('included_folders', updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> removeFolder(String path) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (current.contains(path)) {
      final updated = current.where((p) => p != path).toList();
      await prefs.setStringList('included_folders', updated);
      state = AsyncValue.data(updated);
    }
  }
}

final includedFoldersProvider = AsyncNotifierProvider<IncludedFoldersNotifier, List<String>>(IncludedFoldersNotifier.new);

final wifiOnlyDownloadsProvider = StateProvider<bool>((ref) => true);

/// Backs Settings -> "Artwork Quality". (maxDimension px, jpeg quality).
enum ArtworkQuality {
  low(300, 75),
  medium(600, 85),
  high(900, 90);

  final int maxDimension;
  final int jpegQuality;
  const ArtworkQuality(this.maxDimension, this.jpegQuality);
}

final artworkQualityProvider = StateProvider<ArtworkQuality>((ref) => ArtworkQuality.medium);