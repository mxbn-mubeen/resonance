/// One line of synced lyrics with its timestamp.
class LrcLine {
  final Duration timestamp;
  final String text;
  const LrcLine({required this.timestamp, required this.text});
}

/// Parses raw LRC text (e.g. `[01:23.45]Some lyric line`) into a
/// timestamp-sorted list of [LrcLine]. Lines without a valid timestamp tag
/// (metadata tags like `[ar:Artist]`, `[ti:Title]`, blank lines) are
/// skipped rather than causing a parse failure - LRC is a loose format in
/// the wild and real files often mix metadata tags with lyric lines.
class LrcParser {
  const LrcParser._();

  static final _lineTag = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

  static List<LrcLine> parse(String raw) {
    final lines = <LrcLine>[];
    for (final rawLine in raw.split('\n')) {
      final match = _lineTag.firstMatch(rawLine.trim());
      if (match == null) continue;

      final minutes = int.tryParse(match.group(1) ?? '');
      final seconds = int.tryParse(match.group(2) ?? '');
      if (minutes == null || seconds == null) continue;

      final fractionStr = match.group(3) ?? '0';
      // Fraction can be 1-3 digits (.5 = 500ms, .50 = 500ms, .500 = 500ms) -
      // pad/truncate to milliseconds correctly regardless of digit count.
      final millis = int.tryParse(fractionStr.padRight(3, '0').substring(0, 3)) ?? 0;

      final text = (match.group(4) ?? '').trim();
      lines.add(LrcLine(
        timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
        text: text,
      ));
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Index of the line that should be highlighted for [position], or -1 if
  /// before the first line. Linear scan is fine here - lyric files are at
  /// most a few hundred lines, called once per position update, not per frame.
  static int activeLineIndex(List<LrcLine> lines, Duration position) {
    var active = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= position) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }
}