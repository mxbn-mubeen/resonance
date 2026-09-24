import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/song.dart';
import '../theme/app_theme.dart';
import 'data_providers.dart';

// ---------- Presentation-facing state ----------

final librarySongsProvider = StreamProvider<List<Song>>((ref) async* {
  final repo = await ref.watch(libraryRepositoryProvider.future);
  yield* repo.watchAllSongs();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<String>((ref) => 'all');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  if (query.isEmpty) return [];
  final repo = await ref.watch(libraryRepositoryProvider.future);
  return repo.search(query, filter: filter);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

class AccentColorNotifier extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final val = prefs.getInt('accent_color');
    return val != null ? Color(val) : AppTheme.defaultAccent;
  }

  Future<void> setColor(Color c) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    await prefs.setInt('accent_color', c.toARGB32());
    state = AsyncValue.data(c);
  }
}

final accentColorProvider = AsyncNotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class IncludedFoldersNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getStringList('included_folders') ?? [];
  }

  Future<void> addFolder(String path) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (!current.contains(path)) {
      final updated = [...current, path];
      await prefs.setStringList('included_folders', updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> removeFolder(String path) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final current = state.value ?? [];
    if (current.contains(path)) {
      final updated = current.where((p) => p != path).toList();
      await prefs.setStringList('included_folders', updated);
      state = AsyncValue.data(updated);
    }
  }
}

final includedFoldersProvider = AsyncNotifierProvider<IncludedFoldersNotifier, List<String>>(IncludedFoldersNotifier.new);

final wifiOnlyDownloadsProvider = StateProvider<bool>((ref) => true);

/// Backs Settings -> "Artwork Quality". (maxDimension px, jpeg quality).
enum ArtworkQuality {
  low(300, 75),
  medium(600, 85),
  high(900, 90);

  final int maxDimension;
  final int jpegQuality;
  const ArtworkQuality(this.maxDimension, this.jpegQuality);
}

final artworkQualityProvider = StateProvider<ArtworkQuality>((ref) => ArtworkQuality.medium);
