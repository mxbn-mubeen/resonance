import 'package:flutter/material.dart';
import '../../application/playback/playback_controller.dart';

/// Slim accent progress line pinned along the bottom of the MiniPlayer.
class MiniProgressBar extends StatelessWidget {
  final PlaybackController controller;
  final Duration totalDuration;
  final Color accentColor;

  const MiniProgressBar({
    super.key,
    required this.controller,
    required this.totalDuration,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (totalDuration.inMilliseconds <= 0) {
      return const SizedBox(height: 2.5);
    }

    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final fraction = (position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final progressWidth = constraints.maxWidth * fraction;
            return Container(
              height: 2.5,
              width: constraints.maxWidth,
              color: Colors.white.withValues(alpha: 0.08),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: progressWidth,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.8),
                      accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

