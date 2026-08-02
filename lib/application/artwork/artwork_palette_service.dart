import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracts a dominant color from cached album artwork to drive the
/// cinematic player's backdrop tint (and, optionally, the app-wide accent
/// color - see the "Dynamic theme from album art" advanced feature).
class ArtworkPaletteService {
  final Map<String, Color> _cache = {};

  /// Returns a color suited for a backdrop (muted, not too light/dark) or
  /// null if there's no artwork / extraction fails - callers should fall
  /// back to the theme's default surface in that case.
  Future<Color?> dominantColorFor(String? artworkPath) async {
    if (artworkPath == null) return null;
    if (_cache.containsKey(artworkPath)) return _cache[artworkPath];

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(artworkPath)),
        maximumColorCount: 12,
      );
      // Prefer a muted/dark-muted swatch over the raw dominant swatch -
      // vivid swatches make text on top hard to read; muted swatches are
      // built for exactly this "color behind content" use case.
      final swatch = palette.darkMutedColor ?? palette.mutedColor ?? palette.dominantColor;
      final color = swatch?.color;
      if (color != null) _cache[artworkPath] = color;
      return color;
    } catch (_) {
      return null;
    }
  }

  void clearCache() => _cache.clear();
}
