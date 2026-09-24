import 'package:equatable/equatable.dart';

/// Pure domain representation of a track. Mirrors the "Song Table" in the
/// design doc but has no Isar/DB annotations - those live in
/// data/local/isar_schemas.dart, which maps to/from this entity.
class Song extends Equatable {
  final String id;
  final String path;
  final String filename;
  final Duration duration;
  final String? artist;
  final String? album;
  final String? title;
  final DateTime modified;
  final String? contentHash; // for duplicate detection
  final String? artworkPath; // local cached artwork
  final String? metadataId; // FK -> MetadataResult
  final bool favorite;
  final int playCount;
  final double? rating;
  final bool hidden;
  final int? bitrate;
  final String? codec;
  final int? sizeBytes;
  final String? plainLyrics;
  final String? syncedLyrics;
  final int fetchAttemptCount;
  final DateTime? lastFetchAttemptAt;

  const Song({
    required this.id,
    required this.path,
    required this.filename,
    required this.duration,
    this.artist,
    this.album,
    this.title,
    required this.modified,
    this.contentHash,
    this.artworkPath,
    this.metadataId,
    this.favorite = false,
    this.playCount = 0,
    this.rating,
    this.hidden = false,
    this.bitrate,
    this.codec,
    this.sizeBytes,
    this.plainLyrics,
    this.syncedLyrics,
    this.fetchAttemptCount = 0,
    this.lastFetchAttemptAt,
  });

  Song copyWith({
    String? artist,
    String? album,
    String? title,
    String? artworkPath,
    String? metadataId,
    bool? favorite,
    int? playCount,
    double? rating,
    bool? hidden,
    String? plainLyrics,
    String? syncedLyrics,
  }) {
    return Song(
      id: id,
      path: path,
      filename: filename,
      duration: duration,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      title: title ?? this.title,
      modified: modified,
      contentHash: contentHash,
      artworkPath: artworkPath ?? this.artworkPath,
      metadataId: metadataId ?? this.metadataId,
      favorite: favorite ?? this.favorite,
      playCount: playCount ?? this.playCount,
      rating: rating ?? this.rating,
      hidden: hidden ?? this.hidden,
      bitrate: bitrate,
      codec: codec,
      sizeBytes: sizeBytes,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
    );
  }

  @override
  List<Object?> get props => [id, path, modified, contentHash];
}