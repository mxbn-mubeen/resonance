import 'dart:math';
import 'package:flutter/material.dart';

class PlayingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const PlayingIndicator({super.key, this.size = 24, this.color});

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = [0.5, 0.8, 0.4]; // Initial heights relative to max
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (_controller.status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (_controller.status == AnimationStatus.dismissed) {
          // Generate new random heights on every cycle for organic feel
          setState(() {
            _heights = [
              _random.nextDouble() * 0.7 + 0.3,
              _random.nextDouble() * 0.7 + 0.3,
              _random.nextDouble() * 0.7 + 0.3,
            ];
          });
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final width = widget.size / 4;
    final spacing = widget.size / 8;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              // Interpolate height based on animation
              final targetHeight = widget.size * _heights[index];
              final currentHeight = _controller.value * targetHeight;
              
              return Container(
                width: width,
                height: currentHeight.clamp(2.0, widget.size),
                margin: EdgeInsets.only(right: index < 2 ? spacing : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(width / 2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
