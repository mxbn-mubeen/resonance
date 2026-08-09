import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../playlists/playlist_detail_screen.dart';
import '../../widgets/playlist_cover_widget.dart';

class HomePlaylistsSection extends ConsumerWidget {
  const HomePlaylistsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    return playlistsAsync.when(
      data: (playlists) {
        final manual = playlists.where((p) => !p.isAuto && !p.isAiGenerated).toList();
        if (manual.isEmpty) {
          return Container(
            height: 90,
            alignment: Alignment.centerLeft,
            child: Text(
              'No playlists yet. Create one in the Playlists tab!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: manual.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = manual[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: p),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlaylistCoverWidget(
                      songIds: p.songIds,
                      size: 80,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 72,
                      child: Text(
                        p.name,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox(),
    );
  }
}
