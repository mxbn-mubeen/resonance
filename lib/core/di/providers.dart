import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../domain/entities/song.dart';
import '../theme/app_theme.dart';

// ---------- Data layer ----------

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final isarProvider = FutureProvider<Isar>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.open();
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return LibraryRepository(isar);
});

final metadataRepositoryProvider = Provider<MetadataRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return MetadataRepository(isar);
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return PlaylistRepository(isar);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return HistoryRepository(isar);
});

// ---------- Remote clients ----------

final itunesApiProvider = Provider<ItunesApi>((ref) => ItunesApi());
final musicBrainzApiProvider = Provider<MusicBrainzApi>((ref) => MusicBrainzApi());

// ---------- Application layer (engines) ----------

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return ScannerService(libraryRepository: ref.watch(libraryRepositoryProvider));
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

final playlistEngineProvider = Provider<PlaylistEngine>((ref) {
  return PlaylistEngine(
    playlistRepository: ref.watch(playlistRepositoryProvider),
    libraryRepository: ref.watch(libraryRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
  );
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine(
    historyRepository: ref.watch(historyRepositoryProvider),
    libraryRepository: ref.watch(libraryRepositoryProvider),
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

final librarySongsProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(libraryRepositoryProvider).watchAllSongs();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.watch(libraryRepositoryProvider).search(query);
});

final accentColorProvider = StateProvider<Color>((ref) => AppTheme.defaultAccent);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final includedFoldersProvider = StateProvider<List<String>>((ref) => []);

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
