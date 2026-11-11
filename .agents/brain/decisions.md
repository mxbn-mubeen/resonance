# Decisions

- Decision: Enforce Dart 3.3.0 environment compatibility
- Reason: User explicitly requested avoiding syntax from newer Dart versions (like `.firstOrNull`) as their environment setup prevents upgrading.
- Alternatives considered: Updating SDK constraint to allow newer features, but rejected due to environment constraints.
- Affected modules: Entire codebase
- Date: 2026-08-09

- Decision: Use Android WorkManager (workmanager package) + flutter_local_notifications for background metadata fetch
- Reason: User wants the metadata API fetch to finish even if the app is closed. WorkManager survives app close; the background isolate opens its own Isar instance directly without Riverpod. flutter_local_notifications posts a completion notification.
- Alternatives considered: (1) Foreground service — would require a persistent notification while running, too intrusive. (2) Dart Isolate alone — killed when app process dies. WorkManager is the standard Android pattern for deferrable background work.
- Affected modules: lib/application/metadata/background_metadata_worker.dart (NEW), lib/application/metadata/metadata_fetch_runner.dart, lib/main.dart, pubspec.yaml, AndroidManifest.xml
- Date: 2026-08-16

- Decision: Implement Immersive Dark & Glassmorphic UI for Mini-Player & Fullscreen Player
- Reason: User requested an overall UI overhaul with deep dark surfaces, frosted glass floating mini-player, dynamic radiant backdrop glows from album art, and refined typography.
- Alternatives considered: Flat Material 3 default styling (rejected for lack of visual depth and modern music app feel).
- Affected modules: lib/core/theme/app_theme.dart, lib/presentation/widgets/mini_player.dart, lib/presentation/widgets/mini_progress_bar.dart, lib/presentation/player/player_screen.dart, lib/presentation/player/components/player_content.dart, lib/presentation/player/components/player_dynamic_section.dart, lib/presentation/player/components/player_controls.dart, lib/presentation/player/components/player_secondary_controls.dart, lib/presentation/player/components/secondary_pill_button.dart
- Date: 2026-11-11

- Decision: Extract Library Health into a dedicated full-screen page
- Reason: User requested a separate page for Library Health instead of a modal dialog. Provides a visual health gauge, diagnostic breakdown tiles with direct one-tap fix actions, and seamless history view.
- Alternatives considered: Keeping a dialog popup in Settings (rejected as requested by user).
- Affected modules: lib/presentation/settings/library_health_screen.dart, lib/presentation/settings/components/health_hero_card.dart, lib/presentation/settings/components/health_issue_tile.dart, lib/presentation/settings/components/settings_health_section.dart, lib/presentation/library/library_screen.dart
- Date: 2026-11-11
