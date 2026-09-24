import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_route.dart';

/// Mirrors HomeRecentSection's layout - same card size, same tap-to-play
/// behavior - so the two rails feel like one design language, not two.
class HomeRecommendedSection extends ConsumerWidget {
  const HomeRecommendedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Song>>(
      future: ref.read(recommendationEngineProvider.future).then((e) => e.suggestForYou(limit: 10)),
      builder: (context, snapshot) {
        final recommended = snapshot.data ?? [];
        // No history/favorites yet means no signal to recommend from -
        // RecommendationEngine.suggestForYou returns [] honestly rather
        // than a fallback list, so hide the whole section instead of
        // showing an empty rail with a heading above nothing.
        if (recommended.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final song = recommended[index];
                  return GestureDetector(
                    onTap: () async {
                      await ref.read(playbackControllerProvider).playSongs(recommended, startIndex: index);
                      if (context.mounted) {
                        Navigator.of(context).push(PlayerRoute());
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
                                        child: Icon(Icons.music_note,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer),
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
            ),
          ],
        );
      },
    );
  }
}