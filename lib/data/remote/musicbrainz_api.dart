import 'package:dio/dio.dart';

/// Wraps the MusicBrainz recording search API. Free, no key, but rate
/// limited (1 req/sec) - callers must throttle (see SongMatcher TODO).
class MusicBrainzApi {
  final Dio _dio;

  MusicBrainzApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // MusicBrainz requires an identifying User-Agent per their
              // usage policy - set a real contact string before shipping.
              headers: {
                'User-Agent': 'OfflineMusicPlatform/0.1 (contact@example.com)'
              },
            ));

  Future<List<Map<String, dynamic>>> searchRecording({
    required String title,
    String? artist,
    int limit = 5,
  }) async {
    final query = artist != null && artist.isNotEmpty
        ? 'recording:"$title" AND artist:"$artist"'
        : 'recording:"$title"';

    final response = await _dio.get(
      'https://musicbrainz.org/ws/2/recording',
      queryParameters: {
        'query': query,
        'fmt': 'json',
        'limit': limit,
      },
    );
    final results = (response.data['recordings'] as List?) ?? [];
    return results.cast<Map<String, dynamic>>();
  }
}
