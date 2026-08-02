import '../../core/constants/app_constants.dart';

/// Turns a messy filename like:
///   "Masstamilan.in-Hukum(320Kbps).mp3"
/// into a clean search query:
///   "Hukum"
///
/// Pipeline (matches the design doc exactly):
///   Remove websites -> Remove bitrate -> Remove resolution ->
///   Remove "Official" -> Remove "Download" -> Normalize spaces
class MetadataCleaner {
  /// Precompiled once; blacklist grows at runtime if the user adds custom
  /// rules in Settings (pass them in via [extraBlacklist]).
  static String clean(String rawFilename, {List<String> extraBlacklist = const []}) {
    var result = rawFilename;

    // Strip file extension.
    result = result.replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|ogg|aac|wma)$', caseSensitive: false), '');

    // Remove website tags (blacklist ∪ user custom rules), together with
    // any attached TLD - e.g. "MassTamilan.com" not just "MassTamilan".
    // Without the TLD in the pattern, tag values like "Remo - MassTamilan.com"
    // (common when the site pollutes every ID3 field, not just the filename)
    // leave a dangling "com" behind after separator normalization.
    for (final site in [...kWebsiteBlacklist, ...extraBlacklist]) {
      result = result.replaceAll(
        RegExp('${RegExp.escape(site)}\\.?(com|in|net|org|co)?\\b', caseSensitive: false),
        '',
      );
    }

    // Remove bitrate markers, e.g. (320kbps), [128 Kbps].
    result = result.replaceAll(
      RegExp(r'[\(\[]?\s*\d{2,3}\s?kbps\s*[\)\]]?', caseSensitive: false),
      '',
    );

    // Remove resolution markers, e.g. 1080p, 4K, 720p.
    result = result.replaceAll(
      RegExp(r'\b\d{3,4}p\b|\b4k\b', caseSensitive: false),
      '',
    );

    // Remove noise tokens (Official, Download, Lyrical, etc.)
    for (final token in kNoiseTokens) {
      result = result.replaceAll(RegExp(RegExp.escape(token), caseSensitive: false), '');
    }

    // Replace separators (- _ .) with spaces, collapse brackets/punctuation.
    result = result.replaceAll(RegExp(r'[._\-]+'), ' ');
    result = result.replaceAll(RegExp(r'[\(\)\[\]{}]'), ' ');

    // Normalize whitespace.
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}
