# Patterns

## State Management
- `flutter_riverpod` combined with `riverpod_annotation` is used for global state. Use `@riverpod` annotations to generate providers automatically, and run `build_runner` afterwards.

## Database
- `Isar` is used for local database. Models are defined in `isar_schemas.dart` with `@collection`. Run `build_runner` to generate schemas after changes, and register schemas in `database_service.dart`.
