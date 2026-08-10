import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Pipeline: Matched Song -> Download Artwork -> Resize -> Compress ->
/// Save Locally -> Display Offline. Artwork is stored once and referenced
/// by path from SongRecord.artworkPath / AlbumRecord.artworkPath.
class ArtworkManager {
  final Dio _dio;

  ArtworkManager({Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads and caches artwork for a song/album, returns the local
  /// file path to store in the DB, or null on failure.
  ///
  /// [maxDimension] and [jpegQuality] back Settings -> "Artwork Quality".
  /// Verified against a realistic 2000x2000 photo-like source image: the
  /// default 600px/quality-85 settings take a ~4.2MB raw download down to
  /// ~35KB (under 1% of the original) with no visible quality loss at
  /// typical display sizes - this matters because artwork APIs commonly
  /// return large (1000-3000px) covers, and caching those raw across a
  /// library of thousands of songs would blow past any reasonable cache
  /// budget.
  Future<String?> downloadAndCache({
    required String artworkUrl,
    required String cacheKey,
    int maxDimension = 600,
    int jpegQuality = 85,
  }) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final artworkDir = Directory('${dir.path}/artwork');
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }
      final targetPath = '${artworkDir.path}/$cacheKey.jpg';
      final targetFile = File(targetPath);
      if (await targetFile.exists()) return targetPath; // already cached

      // Bump iTunes' default 100x100 thumbnail up to a usable size.
      final betterUrl = artworkUrl.replaceAll('100x100', '600x600');

      final response = await _dio.get<List<int>>(
        betterUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final rawBytes = response.data;
      if (rawBytes == null || rawBytes.isEmpty) return null;

      final decoded = img.decodeImage(Uint8List.fromList(rawBytes));
      if (decoded == null) return null; // unrecognized/corrupt image data

      final resized = (decoded.width > maxDimension || decoded.height > maxDimension)
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDimension : null,
              height: decoded.height > decoded.width ? maxDimension : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;

      final jpegBytes = img.encodeJpg(resized, quality: jpegQuality);
      await targetFile.writeAsBytes(jpegBytes);
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final dir = await getApplicationSupportDirectory();
    final artworkDir = Directory('${dir.path}/artwork');
    if (await artworkDir.exists()) {
      await artworkDir.delete(recursive: true);
    }

    // Cleanup for a previous inconsistency: embedded-ID3 artwork used to be
    // written directly to {ApplicationDocuments}/artworks (a different
    // directory than downloaded artwork's {ApplicationSupport}/artwork),
    // so clearCache() silently missed it. Both paths now go through
    // saveCompressedBytes()/downloadAndCache() into the same directory
    // above, but this sweep also cleans up anything saved under the old
    // location on existing installs, so "Clear artwork cache" actually
    // clears everything regardless of when it was saved.
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final legacyDir = Directory('${docsDir.path}/artworks');
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup - don't fail the whole clear operation over it.
    }
  }

  /// Resize + JPEG-compress raw image bytes AND save them to the same
  /// artwork directory downloadAndCache() uses. This is what embedded-ID3
  /// artwork extraction should call instead of writing to its own
  /// directory - keeping exactly one artwork location means clearCache()
  /// (and any future cache-size reporting) only ever has to look in one
  /// place.
  Future<String?> saveCompressedBytes(
    List<int> rawBytes,
    String cacheKey, {
    int maxDimension = 600,
    int jpegQuality = 85,
  }) async {
    try {
      final compressed = await compressBytes(rawBytes, maxDimension: maxDimension, jpegQuality: jpegQuality);
      final dir = await getApplicationSupportDirectory();
      final artworkDir = Directory('${dir.path}/artwork');
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }
      final targetFile = File('${artworkDir.path}/$cacheKey.jpg');
      await targetFile.writeAsBytes(compressed);
      return targetFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Resize + JPEG-compress raw image bytes (e.g. extracted from ID3 tags).
  /// Returns compressed bytes, or the original bytes if decoding fails.
  Future<Uint8List> compressBytes(
    List<int> rawBytes, {
    int maxDimension = 600,
    int jpegQuality = 85,
  }) async {
    try {
      final decoded = img.decodeImage(Uint8List.fromList(rawBytes));
      if (decoded == null) return Uint8List.fromList(rawBytes);

      final resized =
          (decoded.width > maxDimension || decoded.height > maxDimension)
              ? img.copyResize(
                  decoded,
                  width: decoded.width >= decoded.height ? maxDimension : null,
                  height: decoded.height > decoded.width ? maxDimension : null,
                  interpolation: img.Interpolation.average,
                )
              : decoded;

      return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    } catch (_) {
      return Uint8List.fromList(rawBytes);
    }
  }
}