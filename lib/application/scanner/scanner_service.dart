import 'package:on_audio_query/on_audio_query.dart';

import '../../data/repositories/library_repository.dart';

/// Watches the folders the user opted into (Folder Manager) and performs
/// incremental scans: only touches files whose modified-timestamp changed
/// since the last scan (see design doc's "Performance" section - never
/// rescan everything).
class ScannerService {
  final OnAudioQuery _audioQuery;
  final LibraryRepository libraryRepository;

  ScannerService({required this.libraryRepository, OnAudioQuery? audioQuery})
      : _audioQuery = audioQuery ?? OnAudioQuery();

  /// Returns true if permission was granted.
  Future<bool> requestPermission() => _audioQuery.permissionsRequest();

  /// Full incremental scan pass:
  /// 1. Query MediaStore for all audio files.
  /// 2. Filter to only user-included folders (excludes Telegram/WhatsApp/etc).
  /// 3. Diff against DB by (path, modified) to find new/changed files -
  ///    unchanged files are skipped entirely, not re-written.
  /// 4. Diff DB paths against MediaStore results to find deleted files.
  Future<ScanResult> scan({required List<String> includedFolderPaths}) async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );

    final relevant = songs.where((s) {
      final path = s.data;
      return includedFolderPaths.any((folder) => path.startsWith(folder));
    }).toList();

    // Fetch the existing library once (not per-song) and index by path, so
    // each scanned file is an O(1) lookup instead of a query.
    final existingByPath = {
      for (final s in await libraryRepository.getAllSongs(includeHidden: true)) s.path: s,
    };

    int newCount = 0;
    int updatedCount = 0;
    int unchangedCount = 0;

    for (final song in relevant) {
      final modified = DateTime.fromMillisecondsSinceEpoch((song.dateModified ?? 0) * 1000);
      final existing = existingByPath[song.data];

      if (existing == null) {
        newCount++;
      } else if (existing.modified != modified || existing.sizeBytes != song.size) {
        // Modified timestamp is the primary signal; size is a cheap
        // secondary check that catches edge cases where a file was
        // replaced but the filesystem's mtime granularity/clock made the
        // timestamp compare equal.
        updatedCount++;
      } else {
        unchangedCount++;
        continue; // skip the write entirely - this is the actual fix
      }

      await libraryRepository.upsertScannedSong(
        path: song.data,
        filename: song.displayNameWOExt,
        duration: Duration(milliseconds: song.duration ?? 0),
        modified: modified,
        bitrate: song.bitRate,
        sizeBytes: song.size,
      );
    }

    final currentPaths = relevant.map((s) => s.data).toSet();
    final deletedPaths = existingByPath.keys.toSet().difference(currentPaths).toList();
    if (deletedPaths.isNotEmpty) {
      await libraryRepository.removeByPaths(deletedPaths);
    }

    return ScanResult(
      newOrUpdated: newCount,
      updated: updatedCount,
      unchanged: unchangedCount,
      deleted: deletedPaths.length,
    );
  }
}

class ScanResult {
  final int newOrUpdated;
  final int updated;
  final int unchanged;
  final int deleted;

  ScanResult({
    required this.newOrUpdated,
    required this.updated,
    this.unchanged = 0,
    required this.deleted,
  });
}
