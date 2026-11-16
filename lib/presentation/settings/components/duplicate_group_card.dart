import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_route.dart';

class DuplicateGroupCard extends ConsumerStatefulWidget {
  final String groupKey;
  final List<Song> songs;
  final Future<void> Function(Song) onDeleteSong;

  const DuplicateGroupCard({
    super.key,
    required this.groupKey,
    required this.songs,
    required this.onDeleteSong,
  });

  @override
  ConsumerState<DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends ConsumerState<DuplicateGroupCard> {
  String? _deletingSongId;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatSize(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        final bytes = f.lengthSync();
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.songs.first;
    final title = first.title ?? first.filename;
    final artist = first.artist ?? 'Unknown Artist';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${widget.songs.length} copies',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            ...widget.songs.map((song) {
              final sizeStr = _formatSize(song.path);
              final durStr = _formatDuration(song.duration);
              final isDeleting = _deletingSongId == song.id;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline, size: 22),
                      tooltip: 'Preview track',
                      onPressed: () async {
                        await ref.read(playbackControllerProvider).playSongs([song]);
                        if (context.mounted) {
                          Navigator.of(context).push(PlayerRoute());
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.path,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [if (durStr.isNotEmpty) durStr, if (sizeStr.isNotEmpty) sizeStr]
                                .join(' • '),
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                    isDeleting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete this copy',
                            onPressed: () async {
                              setState(() => _deletingSongId = song.id);
                              await widget.onDeleteSong(song);
                              if (mounted) setState(() => _deletingSongId = null);
                            },
                          ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
