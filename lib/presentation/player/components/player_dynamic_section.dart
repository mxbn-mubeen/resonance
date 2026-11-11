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
  final Color? accentColor;

  const PlayerDynamicSection({
    super.key,
    required this.controller,
    required this.item,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    required this.formatDuration,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = item?.duration ?? Duration.zero;
    final trackAccent = accentColor ?? Theme.of(context).colorScheme.primary;

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
                    trackHeight: 3.5,
                    activeTrackColor: trackAccent,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
                    thumbColor: Colors.white,
                    overlayColor: trackAccent.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5, elevation: 3),
                    trackShape: const RoundedRectSliderTrackShape(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(position),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        formatDuration(total),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PlayerControls(
                  controller: controller,
                  shuffleEnabled: shuffleEnabled,
                  repeatMode: repeatMode,
                  playing: playing,
                  onToggleShuffle: onToggleShuffle,
                  onToggleRepeat: onToggleRepeat,
                  accentColor: trackAccent,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
