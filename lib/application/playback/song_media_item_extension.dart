import 'package:audio_service/audio_service.dart';
import '../../domain/entities/song.dart';

extension SongMediaItemExtension on Song {
  /// Converts a Song entity into an audio_service MediaItem for playback
  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title ?? filename,
      artist: artist,
      album: album,
      duration: duration,
      artUri: artworkPath != null ? Uri.file(artworkPath!) : null,
    );
  }
}
