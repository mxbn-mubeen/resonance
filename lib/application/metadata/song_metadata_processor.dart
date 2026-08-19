import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../data/repositories/library_repository.dart';
import '../artwork/artwork_manager.dart';
import 'metadata_cleaner.dart';
import 'song_matcher.dart';

class SingleSongProcessResult {
  final bool isNoMatch;

  const SingleSongProcessResult({required this.isNoMatch});
}

class SongMetadataProcessor {
  const SongMetadataProcessor._();

  /// Processes a single song, fetching metadata and artwork, and upserting into the DB.
  /// Returns a [SingleSongProcessResult] indicating if the song was a no-match (used local ID3).
  /// Throws an exception if an error occurs.
  static Future<SingleSongProcessResult> processSong({
    required dynamic song,
    required LibraryRepository libraryRepo,
    required SongMatcher matcher,
    required ArtworkManager artworkMgr,
    required int maxDimension,
    required int jpegQuality,
  }) async {
    dynamic result;
    try {
      result = await matcher.match(
        rawFilename: song.filename,
        knownArtist: song.artist,
        knownAlbum: song.album,
        knownDuration: song.duration,
      );
    } catch (_) {
      result = null;
    }

    String finalTitle = song.title ?? song.filename;
    String finalArtist = song.artist ?? 'Unknown Artist';
    String? finalAlbum = song.album;
    bool isNoMatch = false;

    if (result != null) {
      finalTitle = result.officialTitle;
      finalArtist = result.officialArtist;
      finalAlbum = result.album;
    } else {
      isNoMatch = true;
      try {
        final metadata = readMetadata(File(song.path), getImage: false);
        final localArtist = metadata.artist?.trim() ?? '';
        final localTitle = metadata.title?.trim() ?? '';
        final localAlbum = metadata.album?.trim() ?? '';
        if (localTitle.isNotEmpty) finalTitle = MetadataCleaner.clean(localTitle);
        if (localArtist.isNotEmpty &&
            localArtist.toLowerCase() != 'unknown artist') {
          finalArtist = MetadataCleaner.clean(localArtist);
        }
        if (localAlbum.isNotEmpty) finalAlbum = MetadataCleaner.clean(localAlbum);
      } catch (_) {
        finalTitle = MetadataCleaner.clean(finalTitle);
        finalArtist = MetadataCleaner.clean(finalArtist);
      }
    }

    String? localArtworkPath = song.artworkPath;
    if (localArtworkPath == null) {
      try {
        final metadataImg = readMetadata(File(song.path), getImage: true);
        final pictures = metadataImg.pictures;
        if (pictures.isNotEmpty) {
          final rawBytes = pictures.first.bytes;
          if (rawBytes.isNotEmpty) {
            localArtworkPath = await artworkMgr.saveCompressedBytes(
              rawBytes,
              song.id,
              maxDimension: maxDimension,
              jpegQuality: jpegQuality,
            );
          }
        }
      } catch (_) {}

      if (localArtworkPath == null && result != null && result.artworkUrl != null) {
        try {
          localArtworkPath = await artworkMgr.downloadAndCache(
            artworkUrl: result.artworkUrl!,
            cacheKey: song.id,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          );
        } catch (_) {}
      }
    }

    await libraryRepo.upsertScannedSong(
      path: song.path,
      filename: song.filename,
      duration: song.duration,
      modified: song.modified,
      title: finalTitle,
      artist: finalArtist,
      album: finalAlbum,
      artworkPath: localArtworkPath,
    );

    return SingleSongProcessResult(isNoMatch: isNoMatch);
  }
}
