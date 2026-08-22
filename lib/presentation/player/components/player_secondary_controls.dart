import 'package:flutter/material.dart';
import '../../../application/playback/playback_controller.dart';
import '../../../domain/entities/song.dart';
import '../../equalizer/equalizer_screen.dart';
import '../lyrics_screen.dart';
import 'queue_sheet.dart';

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
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...speeds.map((s) => ListTile(
                title: Text('${s}x', style: const TextStyle(color: Colors.white)),
                trailing: _speed == s ? const Icon(Icons.check, color: Colors.greenAccent) : null,
                onTap: () {
                  setState(() => _speed = s);
                  widget.controller.setSpeed(s);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 8),
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
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ...options.map((d) {
            final label = d.inHours >= 1 ? '${d.inHours}h' : '${d.inMinutes} min';
            return ListTile(
              title: Text(label, style: const TextStyle(color: Colors.white)),
              onTap: () {
                widget.controller.setSleepTimer(d);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('😴 Sleep timer set for $label')),
                );
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showQueueSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: widget.song == null
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
            icon: Icon(Icons.lyrics_outlined,
                color: widget.song == null ? Colors.white30 : Colors.white70, size: 18),
            label: Text('Lyrics', style: TextStyle(color: widget.song == null ? Colors.white30 : Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _showSpeedPicker,
            icon: const Icon(Icons.speed, color: Colors.white70, size: 18),
            label: Text(
              _speed == 1.0 ? 'Speed' : '${_speed}x',
              style: TextStyle(
                color: _speed == 1.0 ? Colors.white70 : Colors.greenAccent,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showSleepTimer,
            icon: const Icon(Icons.bedtime, color: Colors.white70, size: 18),
            label: const Text('Sleep', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: _showQueueSheet,
            icon: const Icon(Icons.queue_music, color: Colors.white70, size: 18),
            label: const Text('Queue', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EqualizerScreen()),
            ),
            icon: const Icon(Icons.equalizer, color: Colors.white70, size: 18),
            label: const Text('EQ', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}