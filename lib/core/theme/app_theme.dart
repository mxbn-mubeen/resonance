import 'package:flutter/material.dart';

/// Central theme definition. `Settings > Accent Color` and
/// `Settings > Dynamic theme from album art` (Advanced Features) both
/// hook into [accentColor] via a Riverpod StateProvider - see
/// core/di/providers.dart -> accentColorProvider.
class AppTheme {
  static ThemeData light(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: accent,
    );
  }

  static ThemeData dark(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accent,
    );
  }

  static const defaultAccent = Color(0xFF1DB954); // Spotify-esque green default
}
