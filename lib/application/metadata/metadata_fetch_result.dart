import 'song_metadata_processor.dart';

class MetadataFetchResult {
  final int processed;
  final int updated;
  final int noMatch;
  final int errors;
  final String? firstError;
  final bool abortedByTimeout;
  // For single-song calls from the foreground runner, exposes outcome/error
  final SongFetchOutcome? lastOutcome;
  final String? lastApiError;

  const MetadataFetchResult({
    required this.processed,
    required this.updated,
    required this.noMatch,
    required this.errors,
    this.firstError,
    this.abortedByTimeout = false,
    this.lastOutcome,
    this.lastApiError,
  });
}
