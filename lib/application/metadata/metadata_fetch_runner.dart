import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../data/local/isar_schemas.dart';
import 'background_metadata_worker.dart';
import 'song_matcher.dart';

/// Drives the "Fetch missing metadata now" operation.
///
/// Foreground path: called from [SettingsMetadataSection] / [SettingsHealthSection].
/// Shows live snackbar progress while the user is in the app.
///
/// Background path: also registers a WorkManager one-off task so the fetch
/// continues even if the user closes the app before the foreground run finishes.
/// The background task re-processes only songs still missing metadata at the
/// time Android fires it, so no work is duplicated.
class MetadataFetchRunner {
  const MetadataFetchRunner._();

  static Future<void> run(BuildContext context, WidgetRef ref) async {
    // Request notification permission for Android 13+ before scheduling background task
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    // Wi-Fi gate
    final wifiOnly = ref.read(wifiOnlyDownloadsProvider);
    if (wifiOnly && !await SongMatcher.isOnWifi()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Not on Wi-Fi. Turn off "Download on Wi-Fi only" to fetch on mobile data.'),
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
      final hasGarbage =
          kWebsiteBlacklist.any((site) => a.contains(site) || t.contains(site));
      return a.isEmpty ||
          a == 'unknown artist' ||
          a == '<unknown>' ||
          s.artworkPath == null ||
          hasGarbage;
    }).toList();

    if (unknown.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All songs already have clean metadata and artwork!')),
        );
      }
      return;
    }

    // Schedule the background task FIRST so it is queued even if the user
    // closes the app before the foreground run finishes. WorkManager fires it
    // when Android decides to (usually within seconds on idle).
    // ExistingWorkPolicy.keep prevents queuing two jobs if the user taps twice.
    await Workmanager().registerOneOffTask(
      kMetadataFetchTaskName,
      kMetadataFetchTaskName,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Fetching metadata for ${unknown.length} songs...')),
      );
    }

    final libraryRepo = await ref.read(libraryRepositoryProvider.future);
    final matcher = ref.read(songMatcherProvider);
    final artworkMgr = ref.read(artworkManagerProvider);
    final artworkQuality = ref.read(artworkQualityProvider);

    // Process one song at a time so we can show progress snackbars.
    int updated = 0;
    int noMatch = 0;
    int errors = 0;
    String? firstError;

    for (int i = 0; i < unknown.length; i++) {
      final singleResult = await BackgroundMetadataWorker.fetchLoop(
        songs: [unknown[i]],
        libraryRepo: libraryRepo,
        matcher: matcher,
        artworkMgr: artworkMgr,
        maxDimension: artworkQuality.maxDimension,
        jpegQuality: artworkQuality.jpegQuality,
      );
      updated += singleResult.updated;
      noMatch += singleResult.noMatch;
      errors += singleResult.errors;
      firstError ??= singleResult.firstError;

      if ((i + 1) % 3 == 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress: ${i + 1} / ${unknown.length} processed...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    // Save foreground run to history.
    try {
      final historyRepo =
          await ref.read(metadataFetchHistoryRepositoryProvider.future);
      final record = MetadataFetchHistoryRecord()
        ..ranAt = DateTime.now()
        ..totalProcessed = unknown.length
        ..totalUpdated = updated
        ..totalNoMatch = noMatch
        ..totalErrors = errors
        ..firstError = firstError;
      await historyRepo.saveRun(record);
    } catch (_) {}

    if (context.mounted) {
      String msg = 'Done: $updated updated';
      if (noMatch > 0) msg += ', $noMatch no match (cleaned locally)';
      if (errors > 0) msg += ', $errors errors';
      if (firstError != null) msg += '\nFirst error: $firstError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
      );
    }
  }
}