import 'package:flutter/material.dart';
import 'player_screen.dart';

/// Slides the PlayerScreen up from the bottom of the screen.
///
/// Key properties vs the default MaterialPageRoute:
/// - **Opaque**: `opaque: true` (default) means the route is fully opaque,
///   so Flutter does NOT paint the previous route behind it during the transition.
///   This eliminates the "flicker" caused by the MiniPlayer or other StreamBuilders
///   in the underlying screen repainting mid-animation.
/// - **Slide up**: feels natural for a "now playing" overlay — pressing back
///   slides it back down, matching user expectation for a bottom-sheet-like panel.
class PlayerRoute extends PageRouteBuilder {
  PlayerRoute()
      : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PlayerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        );
}
