import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/constants/app_constants.dart';
import '../../data/local/isar_schemas.dart';
import '../../data/remote/itunes_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_fetch_history_repository.dart';
import '../artwork/artwork_manager.dart';
import '../metadata/metadata_cleaner.dart';
import '../metadata/song_matcher.dart';

/// Task name constant shared between the dispatcher and the runner.
const kMetadataFetchTaskName = 'fetchMissingMetadata';

/// WorkManager entry point. Runs in a background isolate with NO BuildContext
/// and NO Riverpod. All dependencies are constructed manually.
///
/// The @pragma annotation prevents tree-shaking in release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kMetadataFetchTaskName) return true;

    WidgetsFlutterBinding.ensureInitialized();

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        SongRecordSchema,
        MetadataRecordSchema,
        ArtistRecordSchema,
        AlbumRecordSchema,
        HistoryRecordSchema,
        PlaylistRecordSchema,
        MetadataFetchHistoryRecordSchema,
        LibraryHealthHistoryRecordSchema,
        SearchHistoryRecordSchema,
      ],
      directory: dir.path,
      name: 'resonance',
    );

    try {
      final libraryRepo = LibraryRepository(isar);
      final historyRepo = MetadataFetchHistoryRepository(isar);
      final matcher = SongMatcher(
        musicBrainz: MusicBrainzApi(),
        itunes: ItunesApi(),
      );
      final artworkMgr = ArtworkManager();

      final songs = await libraryRepo.getAllSongs();
      final unknown = songs.where((s) {
        final a = s.artist?.trim().toLowerCase() ?? '';
        final t = s.title?.trim().toLowerCase() ?? '';
        final hasGarbage =
            kWebsiteBlacklist.any((site) => a.contains(site) || t.contains(site));
        return a.isEmpty ||
            a == 'unknown artist' ||
            a == '<unknown>' ||
            s.artworkPath == null ||
            hasGarbage;
      }).toList();

      if (unknown.isEmpty) {
        return true;
      }

      final result = await BackgroundMetadataWorker.fetchLoop(
        songs: unknown,
        libraryRepo: libraryRepo,
        matcher: matcher,
        artworkMgr: artworkMgr,
        maxDimension: 600,
        jpegQuality: 85,
      );

      final record = MetadataFetchHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalProcessed = unknown.length
        ..totalUpdated = result.updated
        ..totalNoMatch = result.noMatch
        ..totalErrors = result.errors
        ..firstError = result.firstError;
      await historyRepo.saveRun(record);

      await BackgroundMetadataWorker.postNotification(result);
    } finally {
      await isar.close();
    }

    return true;
  });
}

/// Result of a completed fetch loop. Shared between foreground and background.
class MetadataFetchResult {
  final int updated;
  final int noMatch;
  final int errors;
  final String? firstError;

  const MetadataFetchResult({
    required this.updated,
    required this.noMatch,
    required this.errors,
    this.firstError,
  });
}

/// Static helpers shared between [callbackDispatcher] (background isolate)
/// and [MetadataFetchRunner] (foreground) to avoid duplicating the fetch loop.
class BackgroundMetadataWorker {
  const BackgroundMetadataWorker._();

  /// Core per-song fetch loop. No Flutter/Riverpod dependencies.
  static Future<MetadataFetchResult> fetchLoop({
    required List<dynamic> songs,
    required LibraryRepository libraryRepo,
    required SongMatcher matcher,
    required ArtworkManager artworkMgr,
    required int maxDimension,
    required int jpegQuality,
  }) async {
    int updated = 0;
    int noMatch = 0;
    int errors = 0;
    String? firstError;

    for (final song in songs) {
      try {
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

        if (result != null) {
          finalTitle = result.officialTitle;
          finalArtist = result.officialArtist;
          finalAlbum = result.album;
        } else {
          noMatch++;
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

          if (localArtworkPath == null &&
              result != null &&
              result.artworkUrl != null) {
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
        updated++;
      } catch (e) {
        errors++;
        firstError ??= e.toString();
      }
    }

    return MetadataFetchResult(
      updated: updated,
      noMatch: noMatch,
      errors: errors,
      firstError: firstError,
    );
  }

  /// Posts an Android completion notification. Safe from a background isolate.
  static Future<void> postNotification(MetadataFetchResult result) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidInit));

    final parts = <String>[' updated'];
    if (result.noMatch > 0) parts.add(' no match');
    if (result.errors > 0) parts.add(' errors');

    final title = result.errors > 0
        ? 'Metadata fetch finished with errors'
        : 'Metadata fetch complete';

    await plugin.show(
      1001,
      title,
      parts.join(' · '),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'resonance_metadata',
          'Resonance Metadata',
          channelDescription: 'Background metadata fetch status',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}