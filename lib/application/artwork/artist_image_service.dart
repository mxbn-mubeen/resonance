import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/remote/deezer_api.dart';

class ArtistImageService {
  final DeezerApi _deezerApi;
  final Dio _dio;

  ArtistImageService(this._deezerApi, {Dio? dio}) : _dio = dio ?? Dio();

  Future<String> _getCacheDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final artistDir = Directory('${docsDir.path}/artist_images');
    if (!await artistDir.exists()) {
      await artistDir.create(recursive: true);
    }
    return artistDir.path;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Returns the local file path to the artist's image, or null if not found
  Future<String?> getArtistImage(String artistName) async {
    if (artistName.trim().isEmpty || artistName.toLowerCase() == 'unknown artist') {
      return null;
    }

    final cacheDir = await _getCacheDirectory();
    final sanitizedName = _sanitizeFileName(artistName);
    final localFile = File('$cacheDir/$sanitizedName.jpg');

    if (await localFile.exists()) {
      return localFile.path;
    }

    // Not found locally, fetch from Deezer
    print('ArtistImageService: Fetching from Deezer for $artistName');
    final imageUrl = await _deezerApi.getArtistImageUrl(artistName);
    if (imageUrl != null) {
      try {
        await _dio.download(imageUrl, localFile.path);
        print('ArtistImageService: Downloaded image for $artistName to ${localFile.path}');
        return localFile.path;
      } catch (e) {
        // Download failed
        print('ArtistImageService: Download failed for $artistName: $e');
        return null;
      }
    }

    print('ArtistImageService: No image URL found for $artistName');
    return null;
  }
}
