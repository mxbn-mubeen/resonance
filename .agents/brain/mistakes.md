# Mistakes

- Problem: Agent Operating Protocol ignored on initialization. Brain was never created, `Before Every Task` checklist skipped.
- Cause: Protocol drift.
- Fix: Manually ran brain auto-init process and admitted fault.
- Status: Resolved
- Date: 2026-08-09

- Problem: Using `.firstOrNull` (Dart 3.5 feature) caused analyzer/compilation errors in the environment which was running a lower version.
- Cause: Assumed modern Dart version features were available without checking the pubspec constraints strictly.
- Fix: Changed to `collection.isEmpty ? null : collection.first` (or similar) to ensure Dart 3.3.0 compatibility.
- Status: Resolved
- Date: 2026-08-09

- Problem: `RenderFlex overflowed by 39 pixels on the right` in player secondary controls row.
- Cause: Added 4th button (Queue) to a fixed `Row(mainAxisAlignment: spaceEvenly)` without checking device width.
- Fix: Wrapped the Row in `SingleChildScrollView(scrollDirection: Axis.horizontal)`.
- Status: Resolved
- Date: 2026-08-09

- Problem: Compilation error `Too few positional arguments: 2 required, 1 given` for `repo.toggleFavorite(song.id)`.
- Cause: Missed passing the second argument `!song.favorite` when adding the toggleFavorite call to GroupDetailScreen.
- Fix: Updated the call to `await repo.toggleFavorite(song.id, !song.favorite)`.
- Status: Resolved
- Date: 2026-08-09

- Problem: Failed to split `player_screen.dart`, `playlist_detail_screen.dart`, `group_detail_screen.dart`, `settings_screen.dart`, `library_screen.dart`, and `home_screen.dart` after they exceeded ~230 lines.
- Cause: Ignored the component size threshold rule from the AGENTS.md Project Rules.
- Fix: Extracted all files into `components/` sub-files; all screen files are now under ~160 lines.
- Status: Resolved
- Date: 2026-08-09

- Problem: Post-extraction flutter analyze found 6 errors: missing import (`playbackControllerProvider` in playlist_header), spurious extra `}` in player_screen, missing `dart:io` in library_screen, stale `equalizer_screen.dart` import with no backing file, unused `audio_service` import, and `const_with_non_const` in settings_screen.
- Cause: Import and brace cleanup during multi-file extraction was not verified before declaring done.
- Fix: Added missing `providers.dart` import; removed duplicate brace; restored `dart:io`; created equalizer stub; removed unused imports; moved `const` to children list instead of ListView.
- Status: Resolved
- Date: 2026-08-09
