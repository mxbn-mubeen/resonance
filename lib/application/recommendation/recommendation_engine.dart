import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_repository.dart';
import '../../domain/entities/song.dart';

/// Generates listening suggestions from play history.
///
/// HONEST LIMITATION (same caveat as PlaylistEngine.moodPlaylist): this is
/// an artist/genre affinity heuristic - "more of what you already play,
/// minus what you just played" - not real collaborative filtering or
/// audio-similarity recommendation. A proper version would want tempo/
/// energy features (on-device audio analysis) or a listening-pattern model
/// across many users, neither of which fits a fully offline, single-user,
/// privacy-first app. This is the version the module's own original TODO
/// called for as a reasonable first step - it's genuinely useful, just not
/// what "recommendation engine" implies in a streaming-service context.
class RecommendationEngine {
  final HistoryRepository historyRepository;
  final LibraryRepository libraryRepository;
  final MetadataRepository metadataRepository;

  RecommendationEngine({
    required this.historyRepository,
    required this.libraryRepository,
    required this.metadataRepository,
  });

  Future<List<Song>> suggestForYou({
    int limit = 20,
    Duration recentExclusionWindow = const Duration(days: 3),
  }) async {
    final all = await libraryRepository.getAllSongs();
    if (all.isEmpty) return [];
    final byId = {for (final s in all) s.id: s};

    // Build artist affinity from history (weighted by play frequency) and
    // favorites (flat boost) - both are real signals of "songs this
    // person actually likes", unlike genre alone.
    final history = await historyRepository.recent(limit: 500);
    final artistPlayCounts = <String, int>{};
    final recentlyPlayedIds = <String>{};
    final cutoff = DateTime.now().subtract(recentExclusionWindow);

    for (final entry in history) {
      final song = byId[entry.songId.toString()];
      if (song == null) continue;
      if (entry.playedAt.isAfter(cutoff)) {
        recentlyPlayedIds.add(song.id);
      }
      if (song.artist != null) {
        artistPlayCounts[song.artist!] = (artistPlayCounts[song.artist!] ?? 0) + 1;
      }
    }
    for (final s in all.where((s) => s.favorite)) {
      if (s.artist != null) {
        artistPlayCounts[s.artist!] = (artistPlayCounts[s.artist!] ?? 0) + 3; // favorite = strong signal
      }
    }

    if (artistPlayCounts.isEmpty) {
      // No history/favorites yet - nothing to base a recommendation on.
      // Returning an empty list (not a random/fallback list) is the
      // honest answer here: there's no signal to recommend from.
      return [];
    }

    // Genre affinity, joined via the same batch metadata lookup pattern
    // used by PlaylistEngine.moodPlaylist/byDecade.
    final withMetadata = all.where((s) => s.metadataId != null).toList();
    final metadataById =
        await metadataRepository.getByIds(withMetadata.map((s) => s.metadataId!).toList());
    final topArtistGenres = <String>{};
    for (final s in withMetadata) {
      if (s.artist != null && artistPlayCounts.containsKey(s.artist)) {
        final genre = metadataById[s.metadataId]?.genre?.toLowerCase();
        if (genre != null) topArtistGenres.add(genre);
      }
    }

    final candidates = all.where((s) => !recentlyPlayedIds.contains(s.id)).toList();

    double score(Song s) {
      var points = 0.0;
      if (s.artist != null && artistPlayCounts.containsKey(s.artist)) {
        points += 10.0 * artistPlayCounts[s.artist]!;
      }
      final genre = metadataById[s.metadataId]?.genre?.toLowerCase();
      if (genre != null && topArtistGenres.contains(genre)) {
        points += 3.0;
      }
      if (s.playCount == 0) points += 0.5; // slight nudge toward unheard tracks
      return points;
    }

    final scored = candidates.map((s) => (s, score(s))).where((e) => e.$2 > 0).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return scored.take(limit).map((e) => e.$1).toList();
  }
}