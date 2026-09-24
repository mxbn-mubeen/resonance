import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/local/database_service.dart';
import '../../data/local/isar_schemas.dart';
import '../../data/remote/deezer_api.dart';
import '../../data/remote/itunes_api.dart';
import '../../data/remote/lrclib_api.dart';
import '../../data/remote/musicbrainz_api.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/library_health_history_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/repositories/metadata_fetch_history_repository.dart';
import '../../data/repositories/metadata_repository.dart';
import '../../data/repositories/playlist_repository.dart';
import '../../data/repositories/search_history_repository.dart';
import '../../domain/entities/library_entities.dart';

// ---------- Data layer ----------

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final isarProvider = FutureProvider<Isar>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.open();
});

final libraryRepositoryProvider = FutureProvider<LibraryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return LibraryRepository(isar);
});

final metadataRepositoryProvider = FutureProvider<MetadataRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MetadataRepository(isar);
});

final playlistRepositoryProvider = FutureProvider<PlaylistRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PlaylistRepository(isar);
});

final historyRepositoryProvider = FutureProvider<HistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return HistoryRepository(isar);
});

final metadataFetchHistoryRepositoryProvider =
    FutureProvider<MetadataFetchHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MetadataFetchHistoryRepository(isar);
});

final libraryHealthHistoryRepositoryProvider =
    FutureProvider<LibraryHealthHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return LibraryHealthHistoryRepository(isar);
});

final searchHistoryRepositoryProvider =
    FutureProvider<SearchHistoryRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return SearchHistoryRepository(isar);
});

// ---------- Reactive Streams ----------

final playlistsStreamProvider = StreamProvider<List<PlaylistEntity>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final repo = await ref.watch(playlistRepositoryProvider.future);

  // Use Isar's collection watch via the generated collection accessor.
  await for (final _ in isar.collection<PlaylistRecord>().watchLazy(fireImmediately: true)) {
    yield await repo.getAll();
  }
});

// ---------- Remote clients ----------

final itunesApiProvider = Provider<ItunesApi>((ref) => ItunesApi());
final musicBrainzApiProvider = Provider<MusicBrainzApi>((ref) => MusicBrainzApi());
final deezerApiProvider = Provider<DeezerApi>((ref) => DeezerApi());
final lrcLibApiProvider = Provider<LrcLibApi>((ref) => LrcLibApi());
