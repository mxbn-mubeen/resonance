import 'dart:convert';
import 'package:dio/dio.dart';

/// Wraps the MusicBrainz recording search API. Free, no key, but rate
/// limited (1 req/sec) - callers must throttle (see SongMatcher TODO).
class MusicBrainzApi {
  final Dio _dio;

  MusicBrainzApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {
                'User-Agent': 'ResonanceApp/1.0.0 (https://github.com/mxbn-mubeen/resonance)'
              },
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<List<Map<String, dynamic>>> searchRecording({
    required String title,
    String? artist,
    int limit = 5,
  }) async {
    final cleanArtist = (artist?.trim() ?? '');
    final isUnknown = cleanArtist.isEmpty ||
        cleanArtist.toLowerCase() == 'unknown artist' ||
        cleanArtist.toLowerCase() == '<unknown>' ||
        cleanArtist.toLowerCase() == 'unknown';

    // Sanitize Lucene query characters
    final safeTitle = title.replaceAll(RegExp(r'["\\]'), ' ').trim();
    final safeArtist = cleanArtist.replaceAll(RegExp(r'["\\]'), ' ').trim();

    final query = (!isUnknown && safeArtist.isNotEmpty)
        ? 'recording:"$safeTitle" AND artist:"$safeArtist"'
        : 'recording:"$safeTitle"';

    final response = await _dio.get(
      'https://musicbrainz.org/ws/2/recording',
      queryParameters: {
        'query': query,
        'fmt': 'json',
        'limit': limit,
      },
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    final raw = response.data;
    if (raw == null) return [];
    final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) return [];
    final results = (decoded['recordings'] as List?) ?? [];
    return results
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }
}
