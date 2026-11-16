import 'dart:convert';
import 'package:dio/dio.dart';

/// Wraps the free iTunes Search API - no auth key required.
/// Used as a fast, high-availability fallback source in the
/// Metadata Matching pipeline (see SongMatcher).
class ItunesApi {
  final Dio _dio;

  ItunesApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

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
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    final raw = response.data;
    if (raw == null) return [];
    final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) return [];
    final results = (decoded['results'] as List?) ?? [];
    return results
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }
}
