class MetadataFetchResult {
  final int processed;
  final int updated;
  final int noMatch;
  final int errors;
  final String? firstError;
  final bool abortedByTimeout;

  const MetadataFetchResult({
    required this.processed,
    required this.updated,
    required this.noMatch,
    required this.errors,
    this.firstError,
    this.abortedByTimeout = false,
  });
}
