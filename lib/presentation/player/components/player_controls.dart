import 'package:flutter/material.dart';
import '../../../application/playback/playback_controller.dart';

class PlayerControls extends StatelessWidget {
  final PlaybackController controller;
  final bool shuffleEnabled;
  final int repeatMode;
  final bool playing;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final Color? accentColor;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.playing,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = accentColor ?? Colors.greenAccent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shuffle_rounded,
                color: shuffleEnabled ? activeAccent : Colors.white.withValues(alpha: 0.55),
                size: 24,
              ),
              if (shuffleEnabled)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onPressed: onToggleShuffle,
        ),

        // Skip Previous
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
          onPressed: controller.skipToPrevious,
        ),

        // Play / Pause Elevated Floating Circle
        GestureDetector(
          onTap: playing ? controller.pause : controller.play,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: activeAccent.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 38,
                color: const Color(0xFF0F1015),
              ),
            ),
          ),
        ),

        // Skip Next
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
          onPressed: controller.skipToNext,
        ),

        // Repeat
        IconButton(
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                color: repeatMode == 0 ? Colors.white.withValues(alpha: 0.55) : activeAccent,
                size: 24,
              ),
              if (repeatMode != 0)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onPressed: onToggleRepeat,
        ),
      ],
    );
  }
}
