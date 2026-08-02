import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/entities/song.dart';

/// Generates listening suggestions from play history. This is the one
/// module the design doc explicitly marks as forward-looking, so it's
/// left as a clean interface + stub rather than fake logic.
class RecommendationEngine {
  final HistoryRepository historyRepository;
  final LibraryRepository libraryRepository;

  RecommendationEngine({
    required this.historyRepository,
    required this.libraryRepository,
  });

  /// TODO(recommendation_engine): naive first version could be
  /// collaborative-filtering-free "same artist/genre as your top plays,
  /// excluding anything played in the last N days". A real version wants
  /// tempo/energy features (would need audio analysis) to power the mood
  /// playlists (Night Drive, Relax, Workout, Focus) in PlaylistEngine.
  Future<List<Song>> suggestForYou({int limit = 20}) async {
    throw UnimplementedError('RecommendationEngine.suggestForYou not yet implemented');
  }
}
