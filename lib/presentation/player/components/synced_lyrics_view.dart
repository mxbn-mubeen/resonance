import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../application/lyrics/lrc_parser.dart';
import '../../../../application/playback/playback_controller.dart';

/// Custom scrolling synced-lyrics list, built from scratch rather than a
/// pre-built package. Auto-scroll uses per-line GlobalKeys +
/// Scrollable.ensureVisible instead of a fixed-height-per-line estimate,
/// since real lyric lines vary in wrapped height and a fixed estimate
/// would drift out of sync over a long song - measuring the actual
/// rendered line position stays accurate regardless of wrapping.
class SyncedLyricsView extends StatefulWidget {
  final String rawLrc;
  final PlaybackController controller;
  final Color accentColor;

  const SyncedLyricsView({
    super.key,
    required this.rawLrc,
    required this.controller,
    required this.accentColor,
  });

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  late final List<LrcLine> _lines;
  late final List<GlobalKey> _lineKeys;
  late final ScrollController _scrollController;
  StreamSubscription<Duration>? _positionSub;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _lines = LrcParser.parse(widget.rawLrc);
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());
    _scrollController = ScrollController();

    // Subscribe once — don't rebuild the whole ListView on every tick.
    _positionSub = widget.controller.positionStream.listen(_handlePosition);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger a redraw when accent color is updated from the palette resolution.
    if (oldWidget.accentColor != widget.accentColor) {
      setState(() {});
    }
  }

  /// Returns true if the line's first strongly-directional char is RTL
  /// (covers Arabic U+0600-06FF, Hebrew U+0590-05FF, and other RTL blocks).
  static bool _isRtl(String text) {
    for (final char in text.runes) {
      if ((char >= 0x0590 && char <= 0x05FF) || // Hebrew
          (char >= 0x0600 && char <= 0x06FF) || // Arabic
          (char >= 0x0700 && char <= 0x074F) || // Syriac
          (char >= 0x0750 && char <= 0x077F) || // Arabic Supplement
          (char >= 0xFB50 && char <= 0xFDFF) || // Arabic Presentation Forms-A
          (char >= 0xFE70 && char <= 0xFEFF)) { // Arabic Presentation Forms-B
        return true;
      }
      // Skip neutral characters (spaces, punctuation) and check next
      if ((char >= 0x0041 && char <= 0x007A) || // Latin
          (char >= 0x0900)) { // Non-RTL Unicode blocks start here
        return false;
      }
    }
    return false;
  }

  /// Ensures the accent color from the palette is vibrant and readable.
  /// If the palette returned a desaturated color (like white or grey),
  /// it falls back to a warm golden tone. Dark colors are brightened.
  static Color _ensureReadable(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.15) {
      // If it's effectively grayscale/white, force a warm golden accent
      return const Color(0xFFFFD580);
    }
    // Ensure it's bright enough to stand out against the dark blurred backdrop
    final targetLightness = hsl.lightness < 0.65 ? 0.75 : hsl.lightness;
    return hsl
        .withLightness(targetLightness)
        .withSaturation(hsl.saturation.clamp(0.5, 1.0))
        .toColor()
        .withOpacity(1.0);
  }

  void _handlePosition(Duration position) {
    if (!mounted) return;
    final newIndex = LrcParser.activeLineIndex(_lines, position);
    if (newIndex != _activeIndex && newIndex >= 0) {
      setState(() => _activeIndex = newIndex);
      // Wait a frame so the highlighted line's new size is laid out first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _lineKeys[newIndex].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return const Center(child: Text('Failed to parse lyrics', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final isActive = index == _activeIndex;
        final lineText = _lines[index].text.isEmpty ? '♪' : _lines[index].text;
        // Auto-detect RTL for Arabic, Hebrew, etc. — checks if the first
        // strongly-directional character is RTL.
        final isRtl = _isRtl(lineText);

        // Derive a bright accent from the artwork palette for the active line.
        // Use HSL to ensure it's always readable: clamp lightness above 0.6.
        final activeColor = _ensureReadable(widget.accentColor);

        return Padding(
          key: _lineKeys[index],
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive ? activeColor : Colors.white.withOpacity(0.4),
              fontSize: isActive ? 22 : 18,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              height: 1.4,
              fontFamilyFallback: const [
                'NotoSans',
                'NotoSansTamil',
                'NotoSansDevanagari',
                'NotoSansTelugu',
                'NotoSansMalayalam',
                'NotoSansArabic',
                'NotoSansCJK',
              ],
            ),
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                lineText,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
