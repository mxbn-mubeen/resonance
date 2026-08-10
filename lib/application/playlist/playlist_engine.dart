import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_repository.dart';
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
  final MetadataRepository metadataRepository;

  PlaylistEngine({
    required this.playlistRepository,
    required this.libraryRepository,
    required this.historyRepository,
    required this.metadataRepository,
  });

  Future<String> createManualPlaylist(String name) =>
      playlistRepository.createManual(name);

  Future<void> addSongToPlaylist(String playlistId, String songId) =>
      playlistRepository.addSong(playlistId, songId);

  /// "Most Played" - real, driven by SongRecord.playCount.
  Future<List<Song>> mostPlayed({int limit = 50}) async {
    final all = await libraryRepository.getAllSongs();
    final sorted = [...all]..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted.where((s) => s.playCount > 0).take(limit).toList();
  }

  /// "Recently Added" - real, driven by SongRecord.modified (scan time).
  Future<List<Song>> recentlyAdded({int limit = 50}) async {
    final all = await libraryRepository.getAllSongs();
    final sorted = [...all]..sort((a, b) => b.modified.compareTo(a.modified));
    return sorted.take(limit).toList();
  }

  /// "Recently Played" - real, driven by HistoryRepository.
  ///
  /// NOTE: this only returns results once something actually calls
  /// `historyRepository.logPlay()`. That call is wired centrally via
  /// `historyLoggerProvider` (see core/di/providers.dart), which listens to
  /// PlaybackController.mediaItem so every play-start path gets logged
  /// without each screen needing to remember to call it.
  Future<List<Song>> recentlyPlayed({int limit = 50}) async {
    final history = await historyRepository.recent(limit: limit * 3); // over-fetch to dedupe
    final all = await libraryRepository.getAllSongs(includeHidden: true);
    final byId = {for (final s in all) s.id: s};

    final seen = <String>{};
    final result = <Song>[];
    for (final entry in history) {
      final songId = entry.songId.toString();
      if (seen.contains(songId)) continue;
      seen.add(songId);
      final song = byId[songId];
      if (song != null) result.add(song);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// "Never Played" - real, playCount == 0.
  Future<List<Song>> neverPlayed() async {
    final all = await libraryRepository.getAllSongs();
    return all.where((s) => s.playCount == 0).toList();
  }

  /// "90's Songs" / decade-based auto playlists - real, joined against
  /// MetadataResult.year via a single batch lookup (not one query per song).
  Future<List<Song>> byDecade(int decadeStartYear) async {
    final all = await libraryRepository.getAllSongs();
    final withMetadata = all.where((s) => s.metadataId != null).toList();
    final metadataById = await metadataRepository
        .getByIds(withMetadata.map((s) => s.metadataId!).toList());

    return withMetadata.where((s) {
      final year = metadataById[s.metadataId]?.year;
      if (year == null) return false;
      return year >= decadeStartYear && year < decadeStartYear + 10;
    }).toList();
  }

  /// AI/mood playlists (Night Drive, Relax, Workout, Focus).
  ///
  /// HONEST LIMITATION: this is a genre-keyword heuristic, not real mood
  /// detection. True mood/energy classification needs tempo/audio-feature
  /// analysis, which is RecommendationEngine's job once it exists (see that
  /// class's TODO) - there's no on-device audio feature extractor wired up
  /// yet. This heuristic only works for songs that have matched metadata
  /// with a genre tag; songs without a match are excluded rather than
  /// guessed at, since a wrong genre-based guess is worse than an honest
  /// gap. Treat this as "good enough to ship a first version", not as the
  /// final mood-detection approach.
  static const Map<String, List<String>> _moodGenreKeywords = {
    'Night Drive': ['electronic', 'synth', 'house', 'edm', 'ambient', 'chill'],
    'Relax': ['acoustic', 'ambient', 'classical', 'instrumental', 'lo-fi', 'lofi', 'jazz'],
    'Workout': ['hip hop', 'hip-hop', 'edm', 'dance', 'pop', 'rock', 'electronic'],
    'Focus': ['instrumental', 'classical', 'ambient', 'lo-fi', 'lofi', 'piano'],
  };

  Future<List<Song>> moodPlaylist(String mood, {int limit = 50}) async {
    final keywords = _moodGenreKeywords[mood];
    if (keywords == null) return [];

    final all = await libraryRepository.getAllSongs();
    final withMetadata = all.where((s) => s.metadataId != null).toList();
    final metadataById = await metadataRepository
        .getByIds(withMetadata.map((s) => s.metadataId!).toList());

    final matches = withMetadata.where((s) {
      final genre = metadataById[s.metadataId]?.genre?.toLowerCase();
      if (genre == null) return false;
      return keywords.any((k) => genre.contains(k));
    }).toList();

    // Prefer favorites/frequently-played among matches so the mood
    // playlist leans toward songs the user actually likes, not just
    // whatever happened to match the genre keyword.
    matches.sort((a, b) {
      final aScore = (a.favorite ? 1000 : 0) + a.playCount;
      final bScore = (b.favorite ? 1000 : 0) + b.playCount;
      return bScore.compareTo(aScore);
    });

    return matches.take(limit).toList();
  }
}