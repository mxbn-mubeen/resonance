import 'package:flutter/material.dart';
import '../../../application/playback/playback_controller.dart';

class PlayerControls extends StatelessWidget {
  final PlaybackController controller;
  final bool shuffleEnabled;
  final int repeatMode;
  final bool playing;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.playing,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: shuffleEnabled ? Colors.greenAccent : Colors.white70,
          ),
          onPressed: onToggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: controller.skipToPrevious,
        ),
        IconButton(
          iconSize: 56,
          icon: Icon(
            playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Colors.white,
          ),
          onPressed: playing ? controller.pause : controller.play,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: controller.skipToNext,
        ),
        IconButton(
          icon: Icon(
            repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
            color: repeatMode == 0 ? Colors.white70 : Colors.greenAccent,
          ),
          onPressed: onToggleRepeat,
        ),
      ],
    );
  }
}
