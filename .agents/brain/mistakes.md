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

- Problem: Created a duplicate equalizer stub at `presentation/player/equalizer/equalizer_screen.dart` — the real implementation already existed at `presentation/equalizer/equalizer_screen.dart`.
- Cause: When fixing the missing-import analyzer error, I created a stub without checking whether the file already existed elsewhere.
- Fix: Deleted the stub, fixed the import in `player_secondary_controls.dart` to point to the real screen at `../../equalizer/equalizer_screen.dart`.
- Status: Resolved
- Date: 2026-08-10

- Problem: `settings_metadata_section.dart` was 291 lines — 61 over the 230-line limit — because the entire `_runMetadataFetch` business logic (~180 lines) was kept inside the widget.
- Cause: The logic was moved into the widget class during extraction instead of being placed in the application layer.
- Fix: Extracted fetch logic to `application/metadata/metadata_fetch_runner.dart` as a static class; widget now delegates to `MetadataFetchRunner.run()` and is ~100 lines.
- Status: Resolved
- Date: 2026-08-10

- Problem: Songs with existing local ID3 tags were not detected for API metadata fetching, failed API matches overwrote tags with unverified local data, and matched API records were never persisted or linked to `SongRecord.metadataId`.
- Cause: `needsMetadataFetch` only checked for empty artist or missing artwork (ignoring songs that had local tags but no API match), `processSong` had a fallback writing local ID3 data back to the database, and `upsertScannedSong` did not take or persist `metadataId`.
- Fix: Updated `needsMetadataFetch` to re-queue unlinked songs (`metadataId == null`), eliminated local ID3 tag overwriting in `processSong` (API-only matching), saved matched `MetadataResult` into `MetadataRecord` via `MetadataRepository`, and linked `metadataId` into `SongRecord`.
- Status: Resolved
- Date: 2026-11-11

- Problem: GitHub Actions build failed with `FAILURE: Build failed with an exception. * What went wrong: 25.0.5`.
- Cause: `.github/workflows/build.yml` lacked a Java setup step, causing the runner to default to system Java 25.0.5. Gradle 8.14 does not support Java 25 and crashes on startup.
- Fix: Added `actions/setup-java@v4` with `distribution: 'temurin'` and `java-version: '17'` to `.github/workflows/build.yml`.
- Status: Resolved
- Date: 2026-11-11

- Problem: Compilation error `The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'` and `'DialogTheme'` to `'DialogThemeData?'` in `lib/core/theme/app_theme.dart`.
- Cause: Flutter 3.27+ separated the widget `CardTheme`/`DialogTheme` from the theme data classes `CardThemeData`/`DialogThemeData`.
- Fix: Updated `cardTheme` to `CardThemeData` and `dialogTheme` to `DialogThemeData`.
- Status: Resolved
- Date: 2026-11-11

- Problem: Updating the existing app on Android phone failed with "App not installed" / package conflict error.
- Cause: Release builds in `android/app/build.gradle.kts` were signed using the ephemeral `debug` signingConfig. GitHub Actions runners generate a new ephemeral debug key each run, and local developer machines have different debug keys. Android strictly blocks APK updates if the signing certificate does not match the installed version.
- Fix: Created a dedicated permanent keystore `android/app/resonance-keystore.jks`, whitelisted it in `android/.gitignore`, and configured `android/app/build.gradle.kts` to sign all release builds with this keystore so every build has an identical signature.
- Status: Resolved
- Date: 2026-11-12

- Problem: Metadata fetch skipped online API matches on valid songs, Library Health report lacked actionable fix buttons, and Health History was non-interactive.
- Cause: 1) MusicBrainz and iTunes APIs received plain string responses without explicit `jsonDecode`, "Unknown Artist" poisoned MusicBrainz Lucene queries, and matcher only received raw filename instead of cleaned title. 2) Broken artwork and duplicates had no handlers or repository mutators. 3) Health History was a flat un-dismissible list.
- Fix: Added `ResponseType.plain` and explicit `jsonDecode` to remote APIs; filtered out "Unknown Artist" before API queries; passed `knownTitle` from `SongMetadataProcessor` into `SongMatcher`; implemented `updateArtworkPath` and `deleteSongById` in `LibraryRepository` and wired up "Clear Stale" and "Review & Delete" actions; redesigned `HealthHistoryScreen` with swipe-to-delete, expandable visual score charts, and clear all history dialog.
- Status: Resolved
- Date: 2026-11-16

- Problem: GitHub Actions build failed with `song_matcher.dart:244:1: Expected a method, getter, setter or operator declaration`.
- Cause: An accidental duplicate closing brace `}` at line 206 closed `class SongMatcher` prematurely, causing `_score` and `_yearFrom` to be parsed outside the class.
- Fix: Removed the duplicate closing brace at line 206.
- Status: Resolved
- Date: 2026-11-16

- Problem: During metadata fetch, exiting/backgrounding the app caused the notification progress to reset from `3/189` down to `0/186`.
- Cause: WorkManager started concurrently in a background isolate, found 186 songs left (since 3 were already processed by the foreground), and immediately dispatched `onProgress(0, 186)` to the system notification tray, overwriting live foreground progress.
- Fix: Added `is_foreground_fetching` flag check in `callbackDispatcher` to prevent background WorkManager from running concurrently with the active foreground fetch loop, removed the premature initial `onProgress(0, ...)` notification reset, and routed live notification updates directly from `MetadataFetchNotifier`.
- Status: Resolved
- Date: 2026-11-16

- Problem: Compilation error `A value of type 'String' can't be assigned to a variable of type 'int?'` in `duplicate_group_card.dart:154:69`.
- Cause: `_deletingSongId` was declared as `int?`, while `Song.id` is of type `String`.
- Fix: Changed `_deletingSongId` to `String?`.
- Status: Resolved
- Date: 2026-11-16
