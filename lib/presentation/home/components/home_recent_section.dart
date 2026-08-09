import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_screen.dart';

class HomeRecentSection extends ConsumerWidget {
  const HomeRecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Song>>(
      future: ref.read(playlistEngineProvider.future).then((e) => e.recentlyAdded(limit: 10)),
      builder: (context, snapshot) {
        final recent = snapshot.data ?? [];
        if (recent.isEmpty) {
          return const SizedBox(height: 76);
        }
        return SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final song = recent[index];
              return GestureDetector(
                onTap: () async {
                  await ref.read(playbackControllerProvider).playSongs(recent, startIndex: index);
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                  }
                },
                child: SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: song.artworkPath != null
                                ? Image.file(File(song.artworkPath!), width: 80, height: 80, fit: BoxFit.cover)
                                : Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                  ),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  await ref.read(playbackControllerProvider).playSongs(recent, startIndex: index);
                                  if (context.mounted) {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
                                  }
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.title ?? song.filename,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
