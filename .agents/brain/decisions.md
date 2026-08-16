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
