import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/song.dart';

/// Wraps a single AudioPlayer + exposes queue/shuffle/repeat/speed/
/// sleep-timer/gapless/crossfade controls. Registered as a background
/// AudioHandler so notification + lock-screen controls work (see main.dart).
class PlaybackController extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _queue = [];
  ConcatenatingAudioSource? _playlist;

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
  List<Song> get currentQueue => List.unmodifiable(_queue);
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  Future<void> loadQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List<Song>.from(songs);
    _playlist = ConcatenatingAudioSource(
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
    final mediaItems = _playlist!.sequence.map((s) => s.tag as MediaItem).toList();
    await _player.setAudioSource(_playlist!, initialIndex: startIndex);
    queue.add(mediaItems);
    mediaItem.add(mediaItems[startIndex]);
  }

  /// Convenience for screens: load a queue and start playing in one call -
  /// this is what actually triggers the OS media notification to appear
  /// (audio_service shows it once play() is called on an active session
  /// with a non-null mediaItem set).
  Future<void> playSongs(List<Song> songs, {int startIndex = 0, bool shuffle = false}) async {
    if (shuffle) {
      await setShuffleEnabled(true);
      if (songs.isNotEmpty) {
        startIndex = DateTime.now().millisecondsSinceEpoch % songs.length;
      }
    }
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

  @override
  Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);

  /// Reorders the queue live — uses ConcatenatingAudioSource.move() which
  /// does NOT interrupt playback (just_audio handles it internally).
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_playlist == null) return;
    if (oldIndex < newIndex) newIndex -= 1;
    // Move in the audio source (live, no interruption)
    await _playlist!.move(oldIndex, newIndex);
    // Mirror in our local list
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    queue.add(_playlist!.sequence.map((s) => s.tag as MediaItem).toList());
  }

  /// Appends a song to the very end of the current queue.
  Future<void> addToQueue(Song song) async {
    if (_playlist == null || _queue.isEmpty) {
      // If nothing is currently loaded, just play this song directly
      await playSongs([song]);
      return;
    }

    _queue.add(song);
    final mediaItem = MediaItem(
      id: song.id,
      title: song.title ?? song.filename,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
    );

    // Add to the live just_audio playlist
    await _playlist!.add(AudioSource.uri(
      Uri.file(song.path),
      tag: mediaItem,
    ));
    
    // Update audio_service queue
    queue.add(_playlist!.sequence.map((s) => s.tag as MediaItem).toList());
  }

  /// Inserts a song immediately after the currently playing song (Play Next).
  Future<void> playNext(Song song) async {
    if (_playlist == null || _queue.isEmpty) {
      await playSongs([song]);
      return;
    }

    final currentIndex = _player.currentIndex ?? 0;
    final insertIndex = currentIndex + 1;

    _queue.insert(insertIndex, song);
    final mediaItem = MediaItem(
      id: song.id,
      title: song.title ?? song.filename,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
    );

    await _playlist!.insert(insertIndex, AudioSource.uri(
      Uri.file(song.path),
      tag: mediaItem,
    ));

    queue.add(_playlist!.sequence.map((s) => s.tag as MediaItem).toList());
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> setShuffleEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    if (enabled) await _player.shuffle();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

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
