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
