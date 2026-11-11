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
      scaffoldBackgroundColor: const Color(0xFFF8F9FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
    );
  }

  static ThemeData dark(Color accent) {
    const deepDarkBg = Color(0xFF0C0D12);
    const surfaceElevated = Color(0xFF141620);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accent,
      scaffoldBackgroundColor: deepDarkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F1118),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardTheme(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF171924),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF141620),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static const defaultAccent = Color(0xFF1DB954); // Spotify-esque green default
}
