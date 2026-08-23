import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../domain/entities/song.dart';
import '../../group_detail_screen.dart';

class FoldersTab extends StatelessWidget {
  final List<String> folderPaths;
  final Map<String, List<Song>> folders;

  const FoldersTab({super.key, required this.folderPaths, required this.folders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: folderPaths.length,
      itemBuilder: (context, index) {
        final dir = folderPaths[index];
        final dirSongs = folders[dir]!;
        final folderName = dir.split(Platform.pathSeparator).last;
        return ListTile(
          leading: const Icon(Icons.folder_rounded),
          title: Text(folderName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${dirSongs.length} songs'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  title: folderName,
                  subtitle: '${dirSongs.length} songs',
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
