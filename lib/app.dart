import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/theme/app_theme.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/library/library_screen.dart';
import 'presentation/playlists/playlists_screen.dart';
import 'presentation/search/search_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'presentation/widgets/mini_player.dart';

class OfflineMusicApp extends ConsumerStatefulWidget {
  const OfflineMusicApp({super.key});

  @override
  ConsumerState<OfflineMusicApp> createState() => _OfflineMusicAppState();
}

class _OfflineMusicAppState extends ConsumerState<OfflineMusicApp> {
  int _tabIndex = 0;

  static const _tabs = [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider).valueOrNull ?? AppTheme.defaultAccent;
    final themeMode = ref.watch(themeModeProvider);
    // Activates the play-history logging subscription for the app's
    // lifetime - see historyLoggerProvider's doc comment in providers.dart.
    ref.watch(historyLoggerProvider);

    return MaterialApp(
      title: 'Resonance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      home: Scaffold(
        body: IndexedStack(index: _tabIndex, children: _tabs),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
                NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
                NavigationDestination(icon: Icon(Icons.queue_music_outlined), selectedIcon: Icon(Icons.queue_music), label: 'Playlists'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}