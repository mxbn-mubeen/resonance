import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../application/metadata/metadata_cleaner.dart';
import '../../../application/metadata/song_matcher.dart';
import '../../../data/local/isar_schemas.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

class SettingsMetadataSection extends ConsumerWidget {
  const SettingsMetadataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Metadata Providers', style: Theme.of(context).textTheme.labelLarge),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('MusicBrainz'),
          subtitle: Text('Primary source — authoritative, no API key needed'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('iTunes'),
          subtitle: Text('Fallback source — good for Tamil/regional music'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_off),
          title: const Text('AcoustID'),
          subtitle: const Text('Audio fingerprint matching — coming soon'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AcoustID coming soon!')),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_off),
          title: const Text('Discogs'),
          subtitle: const Text('Vinyl/collector database — coming soon'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discogs coming soon!')),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('Fetch missing metadata now'),
          subtitle: const Text('MusicBrainz → iTunes → local ID3 fallback'),
          onTap: () => _runMetadataFetch(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('View fetch history'),
          subtitle: const Text('See past metadata fetch runs and their results'),
          onTap: () => _showFetchHistory(context, ref),
        ),
      ],
    );
  }

  /// Called from SettingsHealthSection "Fix now" button.
  Future<void> runFetchFromHealthReport(BuildContext context, WidgetRef ref) =>
      _runMetadataFetch(context, ref);

  Future<void> _runMetadataFetch(BuildContext context, WidgetRef ref) async {
    // Wi-Fi gate
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
        } catch (apiError) {
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
          // Fallback: read ID3 tags directly and clean them
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

        // 2. Extract artwork from ID3 tags if not already cached, respecting quality setting
        String? localArtworkPath = song.artworkPath;
        if (localArtworkPath == null) {
          try {
            final metadataImg = readMetadata(File(song.path), getImage: true);
            final pictures = metadataImg.pictures;
            if (pictures.isNotEmpty) {
              final rawBytes = pictures.first.bytes;
              if (rawBytes.isNotEmpty) {
                final compressed = await artworkMgr.compressBytes(
                  rawBytes,
                  maxDimension: artworkQuality.maxDimension,
                  jpegQuality: artworkQuality.jpegQuality,
                );
                final docsDir = await getApplicationDocumentsDirectory();
                final artDir = Directory('${docsDir.path}/artworks');
                if (!await artDir.exists()) await artDir.create(recursive: true);
                final file = File('${artDir.path}/${song.id}.jpg');
                await file.writeAsBytes(compressed);
                localArtworkPath = file.path;
              }
            }
          } catch (_) {
            // Artwork extraction failed — skip silently
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
      // Don't fail the whole operation if history save fails
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

  Future<void> _showFetchHistory(BuildContext context, WidgetRef ref) async {
    final historyRepo = await ref.read(metadataFetchHistoryRepositoryProvider.future);
    final runs = await historyRepo.getRecentRuns();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Metadata Fetch History'),
        content: SizedBox(
          width: double.maxFinite,
          child: runs.isEmpty
              ? const Text('No fetch runs yet. Tap "Fetch missing metadata now" to start.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: runs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = runs[i];
                    return ListTile(
                      dense: true,
                      title: Text(_formatDate(r.ranAt)),
                      subtitle: Text(
                        '${r.totalUpdated} updated · ${r.totalNoMatch} no match · '
                        '${r.totalErrors} errors  (${r.totalProcessed} total)',
                      ),
                      leading: Icon(
                        r.totalErrors > 0 ? Icons.warning_amber : Icons.check_circle,
                        color: r.totalErrors > 0 ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
