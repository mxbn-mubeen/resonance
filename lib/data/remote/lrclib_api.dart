import 'package:dio/dio.dart';

class LyricsResult {
  final String? plainLyrics;
  final String? syncedLyrics; // raw LRC-format text with [mm:ss.xx] tags

  const LyricsResult({this.plainLyrics, this.syncedLyrics});

  bool get isEmpty =>
      (plainLyrics == null || plainLyrics!.trim().isEmpty) &&
      (syncedLyrics == null || syncedLyrics!.trim().isEmpty);
}

/// Wraps LRCLIB (https://lrclib.net) - free, open-source, keyless lyrics
/// API. No auth, no rate-limit documented, matches well on
/// track_name/artist_name/album_name/duration.
class LrcLibApi {
  final Dio _dio;

  LrcLibApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': 'Resonance/1.0 (offline music platform)'},
            ));

  /// Exact match first (stricter, higher quality when it hits), fuzzy
  /// search fallback if that 404s (looser, catches title/artist variants
  /// the exact endpoint would reject).
  Future<LyricsResult?> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    final exact = await _tryGet(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      durationSeconds: durationSeconds,
    );
    if (exact != null && !exact.isEmpty) return exact;

    return _trySearch(trackName: trackName, artistName: artistName);
  }

  Future<LyricsResult?> _tryGet({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      final params = {
        'track_name': trackName,
        'artist_name': artistName,
        if (albumName != null && albumName.trim().isNotEmpty) 'album_name': albumName,
        if (durationSeconds != null) 'duration': durationSeconds,
      };
      print('LRCLIB GET: $params');
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: params,
      );
      print('LRCLIB GET SUCCESS: ${response.statusCode}');
      return _parseResponse(response.data);
    } on DioException catch (e) {
      print('LRCLIB GET FAILED: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 404) return null; // no exact match - not an error
      rethrow;
    }
  }

  Future<LyricsResult?> _trySearch({
    required String trackName,
    required String artistName,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (artistName.isEmpty || artistName.toLowerCase() == 'unknown artist') {
        queryParams['q'] = trackName;
      } else {
        queryParams['track_name'] = trackName;
        queryParams['artist_name'] = artistName;
      }

      print('LRCLIB SEARCH: $queryParams');
      final response = await _dio.get(
        'https://lrclib.net/api/search',
        queryParameters: queryParams,
      );
      final results = response.data as List?;
      print('LRCLIB SEARCH RESULTS: ${results?.length ?? 0}');
      if (results == null || results.isEmpty) return null;
      // Take the first result - LRCLIB's search already ranks by relevance.
      return _parseResponse(results.first);
    } on DioException catch (e) {
      print('LRCLIB SEARCH FAILED: ${e.message}');
      return null;
    }
  }

  LyricsResult? _parseResponse(dynamic data) {
    if (data == null || data is! Map) return null;
    final plain = data['plainLyrics'] as String?;
    final synced = data['syncedLyrics'] as String?;
    final result = LyricsResult(plainLyrics: plain, syncedLyrics: synced);
    return result.isEmpty ? null : result;
  }
}