import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  final String id;
  final String name; // canonical, post "Smart Artist Merge"
  final String? artworkPath;
  final String? biography;
  final int songCount;

  const Artist({
    required this.id,
    required this.name,
    this.artworkPath,
    this.biography,
    this.songCount = 0,
  });

  @override
  List<Object?> get props => [id, name];
}

class Album extends Equatable {
  final String id;
  final String artistId;
  final String title; // canonical, post "Smart Album Merge"
  final String? artworkPath;
  final int? year;

  const Album({
    required this.id,
    required this.artistId,
    required this.title,
    this.artworkPath,
    this.year,
  });

  @override
  List<Object?> get props => [id, title, artistId];
}

/// Result of the Metadata Matching engine (MusicBrainz / iTunes / future
/// AcoustID + Discogs) attached 1:1 to a Song via Song.metadataId.
class MetadataResult extends Equatable {
  final String id;
  final String officialTitle;
  final String officialArtist;
  final String? album;
  final String? genre;
  final int? year;
  final int? track;
  final String? artworkUrl;
  final double confidence; // 0.0 - 1.0
  final String source; // "musicbrainz" | "itunes" | "acoustid" | "discogs"

  const MetadataResult({
    required this.id,
    required this.officialTitle,
    required this.officialArtist,
    this.album,
    this.genre,
    this.year,
    this.track,
    this.artworkUrl,
    required this.confidence,
    required this.source,
  });

  @override
  List<Object?> get props => [id, officialTitle, officialArtist, confidence, source];
}

class PlaylistEntity extends Equatable {
  final String id;
  final String name;
  final List<String> songIds; // ordered
  final bool isAuto; // "Most Played", "Recently Added" etc.
  final bool isAiGenerated; // "Night Drive", "Focus" etc.

  const PlaylistEntity({
    required this.id,
    required this.name,
    required this.songIds,
    this.isAuto = false,
    this.isAiGenerated = false,
  });

  @override
  List<Object?> get props => [id, name, songIds];
}

class PlayHistoryEntry extends Equatable {
  final String songId;
  final DateTime playedAt;
  final Duration listenedDuration;
  final bool skipped;
  final bool completed;

  const PlayHistoryEntry({
    required this.songId,
    required this.playedAt,
    required this.listenedDuration,
    required this.skipped,
    required this.completed,
  });

  @override
  List<Object?> get props => [songId, playedAt];
}
