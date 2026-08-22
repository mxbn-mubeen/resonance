import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../data/remote/lrclib_api.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/entities/song.dart';

/// Priority chain: DB cache -> Embedded ID3 tag -> Sidecar .lrc file ->
/// LRCLIB online -> cache the result.
///
/// FETCHING STRATEGY: on-demand, not part of the background metadata
/// worker - only called when the lyrics view actually opens for a song.
/// Faster for the common case (most songs' lyrics are never viewed),
/// respects LRCLIB being a smaller free service than MusicBrainz/iTunes,
/// and doesn't add to the metadata worker's already rate-limit-bound
/// runtime for a feature most sessions won't touch for most songs.
class LyricsManager {
  final LrcLibApi lrcLibApi;
  final LibraryRepository libraryRepository;

  LyricsManager({required this.lrcLibApi, required this.libraryRepository});

  Future<LyricsResult?> getLyricsForSong(Song song) async {
    print("GET LYRICS CALLED FOR ${song.title ?? song.filename}");
    // 0. Already cached from a previous fetch.
    if ((song.syncedLyrics?.trim().isNotEmpty ?? false) || (song.plainLyrics?.trim().isNotEmpty ?? false)) {
      return LyricsResult(plainLyrics: song.plainLyrics, syncedLyrics: song.syncedLyrics);
    }

    // 1. Embedded lyrics tag - free, instant, no network needed.
    try {
      print('LYRICS: Checking embedded tag...');
      final metadata = readMetadata(File(song.path), getImage: false);
      final embedded = metadata.lyrics?.trim();
      print('LYRICS: Embedded tag result = ${embedded?.isNotEmpty} / value="${embedded?.substring(0, embedded.length > 60 ? 60 : embedded.length)}"');
      if (embedded != null && embedded.isNotEmpty && !_isPromoWatermark(embedded)) {
        final looksSynced = RegExp(r'\[\d{1,2}:\d{2}').hasMatch(embedded);
        // Fire-and-forget the DB cache — don't await it to avoid Isar deadlocks
        libraryRepository.updateLyrics(
          song.id,
          plain: looksSynced ? null : embedded,
          synced: looksSynced ? embedded : null,
        );
        return looksSynced
            ? LyricsResult(syncedLyrics: embedded)
            : LyricsResult(plainLyrics: embedded);
      }
    } catch (e) {
      print('LYRICS: Embedded tag error: $e');
    }

    // 2. Sidecar .lrc file next to the audio file.
    try {
      print('LYRICS: Checking sidecar .lrc file...');
      final lrcFile = File(_lrcPathFor(song.path));
      if (await lrcFile.exists()) {
        final contents = await lrcFile.readAsString();
        if (contents.trim().isNotEmpty) {
          libraryRepository.updateLyrics(song.id, synced: contents); // fire-and-forget
          return LyricsResult(syncedLyrics: contents);
        }
      }
      print('LYRICS: No sidecar file found.');
    } catch (e) {
      print('LYRICS: Sidecar error: $e');
    }

    String title = song.title ?? song.filename;
    // Sanitize common junk from downloaded MP3 titles to improve search matches.
    // Dart RegExp doesn't support (?i) inline flags - use caseSensitive: false.
    title = title
        .replaceAll(RegExp(r'\(official[^)]*\)|\[official[^\]]*\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(lyrics[^)]*\)|\[lyrics[^\]]*\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(audio[^)]*\)|\[audio[^\]]*\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(video[^)]*\)|\[video[^\]]*\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\s*masstamilan\.?\w*', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\s*starmusiq\.?\w*', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\s*isaimini\.?\w*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\d{3}\s*kbps', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.mp3|\.m4a|\.flac', caseSensitive: false), '')
        .trim();
                 
    final artist = song.artist ?? '';

    print('LYRICS: Fetching from LRCLIB for title="$title" artist="$artist"');
    try {
      final online = await lrcLibApi.fetchLyrics(
        trackName: title,
        artistName: artist,
        albumName: song.album,
        durationSeconds: song.duration.inSeconds,
      );
      print('LYRICS: LRCLIB result = ${online?.isEmpty == false ? "found" : "not found"}');
      if (online != null && !online.isEmpty) {
        libraryRepository.updateLyrics( // fire-and-forget
          song.id,
          plain: online.plainLyrics,
          synced: online.syncedLyrics,
        );
      }
      return online;
    } catch (e) {
      print('LYRICS: LRCLIB fetch FAILED: $e');
      return null; // network failure - don't crash the lyrics view over it
    }
  }

  String _lrcPathFor(String songPath) {
    final withoutExt = songPath.substring(0, songPath.lastIndexOf('.'));
    return '$withoutExt.lrc';
  }

  /// Returns true if the embedded lyrics tag is just a promotional watermark
  /// (e.g. MassTamilan, StarMusiQ, Kuttyweb) injected by music download sites,
  /// not actual song lyrics. We detect these by checking for known domain names
  /// or typical ad-copy patterns.
  bool _isPromoWatermark(String text) {
    final lower = text.toLowerCase();
    const knownWatermarks = [
      'masstamilan', 'starmusiq', 'kuttyweb', 'isaimini',
      'tamilwire', 'tamildada', 'saavn', 'gaana.com',
      'download', '320kbps', '128kbps', 'kbps latest',
      'visit us', 'www.', '.com', '.org', '.net',
    ];
    // If ≥2 watermark signals present, it's definitely promo text
    final hits = knownWatermarks.where((w) => lower.contains(w)).length;
    return hits >= 2;
  }
}