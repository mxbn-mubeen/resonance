import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/song.dart';

/// Wraps a single AudioPlayer + exposes queue/shuffle/repeat/speed/
/// sleep-timer/gapless/crossfade controls. Registered as a background
/// AudioHandler so notification + lock-screen controls work (see main.dart).
class PlaybackController extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _queue = [];

  PlaybackController() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });
    // This is what actually drives the Android notification's title/
    // artist/artwork. queue.add() alone is NOT enough - without keeping
    // mediaItem in sync with the current index, the notification shows
    // blank (or may not reliably appear at all) even though playback and
    // the control buttons work.
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      final sequence = _player.sequence;
      if (sequence == null || index >= sequence.length) return;
      mediaItem.add(sequence[index].tag as MediaItem);
    });
  }

  AudioPlayer get rawPlayer => _player;

  Future<void> loadQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = songs;
    final playlist = ConcatenatingAudioSource(
      children: songs
          .map((s) => AudioSource.uri(Uri.file(s.path),
              tag: MediaItem(
                id: s.id,
                title: s.title ?? s.filename,
                artist: s.artist,
                album: s.album,
                duration: s.duration,
                artUri: s.artworkPath != null ? Uri.file(s.artworkPath!) : null,
              )))
          .toList(),
    );
    final mediaItems = playlist.sequence.map((s) => s.tag as MediaItem).toList();
    await _player.setAudioSource(playlist, initialIndex: startIndex);
    queue.add(mediaItems);
    // Set the notification content immediately - don't wait for
    // currentIndexStream's first event, which can lag behind setAudioSource
    // and leave the notification blank for a moment right as playback starts.
    mediaItem.add(mediaItems[startIndex]);
  }

  /// Convenience for screens: load a queue and start playing in one call -
  /// this is what actually triggers the OS media notification to appear
  /// (audio_service shows it once play() is called on an active session
  /// with a non-null mediaItem set).
  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    await loadQueue(songs, startIndex: startIndex);
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setShuffleEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) await _player.shuffle();
  }

  Future<void> setRepeatMode(LoopMode mode) => _player.setLoopMode(mode);

  /// Sleep timer: stop playback after [duration] elapses.
  Future<void> setSleepTimer(Duration duration) async {
    await Future.delayed(duration);
    await pause();
  }

  // TODO(playback_controller): Equalizer / Bass Boost - just_audio doesn't
  // expose platform EQ directly; on Android this needs a native
  // AudioEffect (Equalizer/BassBoost) hooked to the player's audio session
  // ID via a platform channel, or a package like `just_audio_media_kit`
  // /native plugin that exposes it.

  // TODO(playback_controller): Crossfade - requires running two
  // AudioPlayer instances and manually fading volume between them near
  // track boundaries; just_audio doesn't do this natively.

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  Future<void> dispose() => _player.dispose();
}
