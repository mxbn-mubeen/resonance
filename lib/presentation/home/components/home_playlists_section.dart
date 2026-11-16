import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../playlists/playlist_detail_screen.dart';
import '../../playlists/playlists_screen.dart' show openSmartPlaylist;
import '../../playlists/smart_playlist_definitions.dart';
import '../../widgets/playlist_cover_widget.dart';

class HomePlaylistsSection extends ConsumerWidget {
  const HomePlaylistsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    return playlistsAsync.when(
      data: (playlists) {
        final manual = playlists.where((p) => !p.isAuto && !p.isAiGenerated).toList();
        final smartDefs = [...kAutomaticPlaylistDefs, ...kAiPlaylistDefs];
        final totalCount = manual.length + smartDefs.length;

        return SizedBox(
          height: 135,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (i < manual.length) {
                final p = manual[i];
                return _PlaylistCard(
                  cover: PlaylistCoverWidget(songIds: p.songIds, size: 92),
                  label: p.name,
                  subtitle: '${p.songIds.length} tracks',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: p)),
                    );
                  },
                );
              }
              final def = smartDefs[i - manual.length];
              return _SmartPlaylistCard(def: def);
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox(),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Widget cover;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.cover,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: cover,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartPlaylistCard extends ConsumerStatefulWidget {
  final SmartPlaylistDef def;
  const _SmartPlaylistCard({required this.def});

  @override
  ConsumerState<_SmartPlaylistCard> createState() => _SmartPlaylistCardState();
}

class _SmartPlaylistCardState extends ConsumerState<_SmartPlaylistCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return _PlaylistCard(
      cover: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : Icon(widget.def.icon, color: Colors.white, size: 36),
      ),
      label: widget.def.title,
      subtitle: widget.def.subtitle,
      onTap: _loading
          ? () {}
          : () async {
              setState(() => _loading = true);
              await openSmartPlaylist(context, ref, widget.def);
              if (mounted) setState(() => _loading = false);
            },
    );
  }
}
