import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../../../application/playback/playback_controller.dart';
import 'player_controls.dart';

/// The dynamic portion of the player: slider, time labels, transport buttons.
/// Isolated into its own widget so only this subtree rebuilds on every
/// playback-state / position stream event.
class PlayerDynamicSection extends StatelessWidget {
  final PlaybackController controller;
  final MediaItem? item;
  final bool shuffleEnabled;
  final int repeatMode;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final String Function(Duration) formatDuration;

  const PlayerDynamicSection({
    super.key,
    required this.controller,
    required this.item,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final total = item?.duration ?? Duration.zero;

    return StreamBuilder<PlaybackState>(
      stream: controller.playbackState,
      builder: (context, stateSnapshot) {
        final playing = stateSnapshot.data?.playing ?? false;

        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ??
                stateSnapshot.data?.updatePosition ??
                Duration.zero;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: total.inMilliseconds > 0
                        ? position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble()
                        : 0,
                    max: total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1,
                    onChanged: total.inMilliseconds > 0
                        ? (v) => controller.seek(Duration(milliseconds: v.round()))
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(formatDuration(total), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                PlayerControls(
                  controller: controller,
                  shuffleEnabled: shuffleEnabled,
                  repeatMode: repeatMode,
                  playing: playing,
                  onToggleShuffle: onToggleShuffle,
                  onToggleRepeat: onToggleRepeat,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
