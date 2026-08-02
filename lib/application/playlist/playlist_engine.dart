import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../domain/entities/library_entities.dart';
import '../../domain/entities/song.dart';

/// Manual playlists (Favorites, Travel, Gym) go straight through
/// [PlaylistRepository]. Auto playlists (Most Played, Recently Added,
/// Recently Played, Never Played, decade/genre splits) and AI/mood
/// playlists (Night Drive, Relax, Workout, Focus) are computed on read
/// here rather than persisted as static song lists.
class PlaylistEngine {
  final PlaylistRepository playlistRepository;
  final LibraryRepository libraryRepository;
  final HistoryRepository historyRepository;

  PlaylistEngine({
    required this.playlistRepository,
    required this.libraryRepository,
    required this.historyRepository,
  });

  Future<String> createManualPlaylist(String name) =>
      playlistRepository.createManual(name);

  Future<void> addSongToPlaylist(String playlistId, String songId) =>
      playlistRepository.addSong(playlistId, songId);

  /// "Most Played" - real, driven by SongRecord.playCount.
  Future<List<Song>> mostPlayed({int limit = 50}) async {
    final all = await libraryRepository.getAllSongs();
    final sorted = [...all]..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted.take(limit).toList();
  }

  /// "Recently Added" - real, driven by SongRecord.modified (scan time).
  Future<List<Song>> recentlyAdded({int limit = 50}) async {
    final all = await libraryRepository.getAllSongs();
    final sorted = [...all]..sort((a, b) => b.modified.compareTo(a.modified));
    return sorted.take(limit).toList();
  }

  /// "Never Played" - real, playCount == 0.
  Future<List<Song>> neverPlayed() async {
    final all = await libraryRepository.getAllSongs();
    return all.where((s) => s.playCount == 0).toList();
  }

  /// "90's Songs" / decade-based auto playlists.
  /// TODO(playlist_engine): needs MetadataResult.year joined in - currently
  /// Song doesn't carry year directly; join via metadataId once
  /// MetadataRepository batch-lookup helper exists.
  Future<List<Song>> byDecade(int decadeStartYear) async {
    throw UnimplementedError(
        'byDecade needs Song<->MetadataResult year join - see TODO');
  }

  /// AI/mood playlists (Night Drive, Relax, Workout, Focus) generated from
  /// listening history + audio characteristics.
  /// TODO(playlist_engine): this is the Recommendation Engine's job really -
  /// delegate to RecommendationEngine once tempo/energy features exist
  /// (would need audio analysis, e.g. via an on-device feature extractor).
  Future<List<Song>> moodPlaylist(String mood) async {
    throw UnimplementedError('AI mood playlists depend on RecommendationEngine');
  }
}
