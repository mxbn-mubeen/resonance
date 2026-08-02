import 'dart:io';

/// Priority chain per design doc: Embedded Lyrics -> .lrc File ->
/// Online Search -> Cache.
class LyricsManager {
  final Map<String, String> _memoryCache = {};

  Future<String?> getLyrics({
    required String songPath,
    String? songId,
    String? embeddedLyrics,
  }) async {
    if (songId != null && _memoryCache.containsKey(songId)) {
      return _memoryCache[songId];
    }

    // 1. Embedded lyrics (from ID3/USLT tag, extracted during scan).
    if (embeddedLyrics != null && embeddedLyrics.trim().isNotEmpty) {
      _cacheAndReturn(songId, embeddedLyrics);
      return embeddedLyrics;
    }

    // 2. Sidecar .lrc file next to the audio file.
    final lrcPath = _lrcPathFor(songPath);
    final lrcFile = File(lrcPath);
    if (await lrcFile.exists()) {
      final contents = await lrcFile.readAsString();
      _cacheAndReturn(songId, contents);
      return contents;
    }

    // 3. Online search (only if user allows it - respect
    // "Download on WiFi Only" setting upstream of this call).
    // TODO(lyrics_manager): wire an actual lyrics provider (e.g. lrclib.net
    // has a free, keyless API well suited for this) and parse LRC/plain text.
    final online = await _fetchOnline(songPath);
    if (online != null) {
      _cacheAndReturn(songId, online);
      return online;
    }

    return null;
  }

  String _lrcPathFor(String songPath) {
    final withoutExt = songPath.substring(0, songPath.lastIndexOf('.'));
    return '$withoutExt.lrc';
  }

  void _cacheAndReturn(String? songId, String lyrics) {
    if (songId != null) _memoryCache[songId] = lyrics;
  }

  Future<String?> _fetchOnline(String songPath) async {
    // Stub - see TODO above.
    return null;
  }
}
