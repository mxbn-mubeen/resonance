import 'package:dio/dio.dart';

/// Wraps the free iTunes Search API - no auth key required.
/// Used as a fast, high-availability fallback source in the
/// Metadata Matching pipeline (see SongMatcher).
class ItunesApi {
  final Dio _dio;

  ItunesApi({Dio? dio}) : _dio = dio ?? Dio();

  /// Returns raw result maps: {trackName, artistName, collectionName,
  /// artworkUrl100, releaseDate, trackTimeMillis, ...}
  Future<List<Map<String, dynamic>>> search({
    required String term,
    int limit = 5,
    String country = 'in', // Default to India for Tamil/regional music coverage
  }) async {
    final response = await _dio.get(
      'https://itunes.apple.com/search',
      queryParameters: {
        'term': term,
        'media': 'music',
        'entity': 'song',
        'limit': limit,
        'country': country,
      },
    );
    final results = (response.data['results'] as List?) ?? [];
    return results.cast<Map<String, dynamic>>();
  }
}
