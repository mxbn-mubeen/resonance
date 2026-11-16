import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/song.dart';
import '../../../player/player_route.dart';
import '../../group_detail_screen.dart';

class FoldersTab extends ConsumerWidget {
  final List<String> folderPaths;
  final Map<String, List<Song>> folders;

  const FoldersTab({super.key, required this.folderPaths, required this.folders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (folderPaths.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 56, color: Colors.white24),
            SizedBox(height: 12),
            Text('No folders found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text('Scan folders in Settings to populate your library.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folderPaths.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final dir = folderPaths[index];
        final dirSongs = folders[dir]!;
        final folderName = dir.split(Platform.pathSeparator).last;
        final parentPath = dir.replaceAll(Platform.pathSeparator + folderName, '');

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade700.withValues(alpha: 0.8),
                  Colors.deepOrange.shade600.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_rounded, color: Colors.white, size: 26),
          ),
          title: Text(
            folderName.isNotEmpty ? folderName : dir,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parentPath.isNotEmpty) ...[
                Text(
                  parentPath,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                '${dirSongs.length} track${dirSongs.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Play folder',
            onPressed: () async {
              if (dirSongs.isNotEmpty) {
                await ref.read(playbackControllerProvider).playSongs(dirSongs);
                if (context.mounted) {
                  Navigator.of(context).push(PlayerRoute());
                }
              }
            },
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  title: folderName.isNotEmpty ? folderName : dir,
                  subtitle: '${dirSongs.length} tracks • $dir',
                  songs: dirSongs,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
