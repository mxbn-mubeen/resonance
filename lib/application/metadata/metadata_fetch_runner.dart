import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../data/local/isar_schemas.dart';
import '../metadata/metadata_cleaner.dart';
import '../metadata/song_matcher.dart';

/// Drives the "Fetch missing metadata now" operation.
/// Called from [SettingsMetadataSection] and [SettingsHealthSection].
class MetadataFetchRunner {
  const MetadataFetchRunner._();

  static Future<void> run(BuildContext context, WidgetRef ref) async {
    // ── Wi-Fi gate ────────────────────────────────────────────────────────
    final wifiOnly = ref.read(wifiOnlyDownloadsProvider);
    if (wifiOnly && !await SongMatcher.isOnWifi()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Not on Wi-Fi. Turn off "Download on Wi-Fi only" to fetch on mobile data.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final songs = ref.read(librarySongsProvider).valueOrNull ?? [];
    final unknown = songs.where((s) {
      final a = s.artist?.trim().toLowerCase() ?? '';
      final t = s.title?.trim().toLowerCase() ?? '';
      final hasGarbage = kWebsiteBlacklist.any((site) => a.contains(site) || t.contains(site));
      return a.isEmpty || a == 'unknown artist' || a == '<unknown>' || s.artworkPath == null || hasGarbage;
    }).toList();

    if (unknown.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All songs already have clean metadata and artwork!')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔄 Fetching metadata for ${unknown.length} songs…')),
      );
    }

    final matcher = ref.read(songMatcherProvider);
    final repo = await ref.read(libraryRepositoryProvider.future);
    final artworkMgr = ref.read(artworkManagerProvider);
    final artworkQuality = ref.read(artworkQualityProvider);

    int updated = 0;
    int noMatch = 0;
    int errors = 0;
    String? firstError;

    for (int i = 0; i < unknown.length; i++) {
      final song = unknown[i];
      try {
        // 1. Try API sources (MusicBrainz → iTunes)
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
            if (localArtist.isNotEmpty && localArtist.toLowerCase() != 'unknown artist') {
              finalArtist = MetadataCleaner.clean(localArtist);
            }
            if (localAlbum.isNotEmpty) finalAlbum = MetadataCleaner.clean(localAlbum);
          } catch (_) {
            finalTitle = MetadataCleaner.clean(finalTitle);
            finalArtist = MetadataCleaner.clean(finalArtist);
          }
        }

        // 2. Artwork: embedded ID3 first, then online match URL
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
                  maxDimension: artworkQuality.maxDimension,
                  jpegQuality: artworkQuality.jpegQuality,
                );
              }
            }
          } catch (_) {
            // Embedded art failed — try online URL below
          }

          if (localArtworkPath == null && result != null && result.artworkUrl != null) {
            try {
              localArtworkPath = await artworkMgr.downloadAndCache(
                artworkUrl: result.artworkUrl!,
                cacheKey: song.id,
                maxDimension: artworkQuality.maxDimension,
                jpegQuality: artworkQuality.jpegQuality,
              );
            } catch (_) {
              // Network/decode failure — leave artwork null
            }
          }
        }

        await repo.upsertScannedSong(
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

      // Progress every 20 songs
      if (i > 0 && i % 20 == 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress: $updated updated, $i / ${unknown.length} processed…'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Save run to history
    try {
      final historyRepo = await ref.read(metadataFetchHistoryRepositoryProvider.future);
      final record = MetadataFetchHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalProcessed = unknown.length
        ..totalUpdated = updated
        ..totalNoMatch = noMatch
        ..totalErrors = errors
        ..firstError = firstError;
      await historyRepo.saveRun(record);
    } catch (_) {
      // History save failure must not abort the UI result
    }

    if (context.mounted) {
      String msg = '✅ Done: $updated updated';
      if (noMatch > 0) msg += ', $noMatch no match (cleaned locally)';
      if (errors > 0) msg += ', $errors errors';
      if (firstError != null) msg += '\nFirst error: $firstError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
      );
    }
  }
}
