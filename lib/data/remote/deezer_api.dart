import 'package:dio/dio.dart';

class DeezerApi {
  final Dio _dio;

  DeezerApi({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> getArtistImageUrl(String artistName) async {
    try {
      final response = await _dio.get(
        'https://api.deezer.com/search/artist',
        queryParameters: {'q': artistName},
      );
      
      final data = response.data;
      if (data != null && data['data'] != null) {
        final results = data['data'] as List;
        if (results.isNotEmpty) {
          final firstResult = results.first;
          final url = firstResult['picture_xl'] ?? 
                 firstResult['picture_medium'] ?? 
                 firstResult['picture'];
          print('Deezer API returned URL for $artistName: $url');
          return url;
        } else {
          print('Deezer API returned empty results for $artistName');
        }
      }
    } catch (e) {
      print('Deezer API error for $artistName: $e');
    }
    return null;
  }
}
