import 'package:flutter/material.dart';
import '../../../application/playback/playback_controller.dart';
import '../../../domain/entities/song.dart';
import '../../equalizer/equalizer_screen.dart';
import '../lyrics_screen.dart';
import 'queue_sheet.dart';
import 'secondary_pill_button.dart';

class PlayerSecondaryControls extends StatefulWidget {
  final PlaybackController controller;
  final Song? song;
  final String? artworkPath;

  const PlayerSecondaryControls({
    super.key,
    required this.controller,
    this.song,
    this.artworkPath,
  });

  @override
  State<PlayerSecondaryControls> createState() => _PlayerSecondaryControlsState();
}

class _PlayerSecondaryControlsState extends State<PlayerSecondaryControls> {
  double _speed = 1.0;

  void _showSpeedPicker() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...speeds.map((s) => ListTile(
                title: Text('${s}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                trailing: _speed == s ? const Icon(Icons.check_rounded, color: Colors.greenAccent) : null,
                onTap: () {
                  setState(() => _speed = s);
                  widget.controller.setSpeed(s);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showSleepTimer() {
    final options = [
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(hours: 1),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...options.map((d) {
            final label = d.inHours >= 1 ? '${d.inHours}h' : '${d.inMinutes} min';
            return ListTile(
              title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              onTap: () {
                widget.controller.setSleepTimer(d);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('😴 Sleep timer set for $label')),
                );
              },
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) {
          return QueueSheet(
            controller: widget.controller,
            scrollController: scrollController,
            onClose: () => Navigator.pop(ctx),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SecondaryPillButton(
              onTap: widget.song == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LyricsScreen(
                            song: widget.song!,
                            controller: widget.controller,
                            artworkPath: widget.artworkPath,
                          ),
                        ),
                      ),
              icon: Icons.lyrics_rounded,
              label: 'Lyrics',
              enabled: widget.song != null,
            ),
            SecondaryPillButton(
              onTap: _showSpeedPicker,
              icon: Icons.speed_rounded,
              label: _speed == 1.0 ? 'Speed' : '${_speed}x',
              isActive: _speed != 1.0,
            ),
            SecondaryPillButton(
              onTap: _showSleepTimer,
              icon: Icons.bedtime_rounded,
              label: 'Sleep',
            ),
            SecondaryPillButton(
              onTap: _showQueueSheet,
              icon: Icons.queue_music_rounded,
              label: 'Queue',
            ),
            SecondaryPillButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EqualizerScreen()),
              ),
              icon: Icons.equalizer_rounded,
              label: 'EQ',
            ),
          ],
        ),
      ),
    );
  }
}