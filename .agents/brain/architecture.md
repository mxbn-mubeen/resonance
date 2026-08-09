# Architecture

Based on `README.md` and repository scan.

- **Clean Architecture** via `lib/` split:
  - `domain/` - Pure Dart models (Song, Album, etc.)
  - `data/` - Repositories, Isar schemas (`local/`), API clients (`remote/`)
  - `application/` - Business logic (scanner, metadata, artwork, lyrics, playback, playlist, etc.)
  - `presentation/` - UI layer (Riverpod ConsumerWidgets, screens like home, library, player, settings)
  - `core/` - Dependency injection (`di/providers.dart`), constants, theme

- **State Management**: `flutter_riverpod` provides global access to services, repos, and async state.
- **Data Persistence**: `isar` database used for fast, offline search and library caching. Never stores audio itself.

## Directory Mappings
- `lib/core/di/providers.dart`: Central location for all Riverpod providers (repos, services, controllers).
- `lib/data/local/isar_schemas.dart`: Central location for Isar database collections (SongRecord, MetadataFetchHistoryRecord, LibraryHealthHistoryRecord, etc.)
