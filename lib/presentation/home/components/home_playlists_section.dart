import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../playlists/playlist_detail_screen.dart';
import '../../playlists/playlists_screen.dart' show openSmartPlaylist;
import '../../playlists/smart_playlist_definitions.dart';
import '../../widgets/playlist_cover_widget.dart';

/// Shows manual playlists AND the Automatic/AI smart playlists in one
/// combined horizontal scroll, in that order. Manual playlists get a real
/// artwork-mosaic cover (PlaylistCoverWidget); smart playlists get an
/// icon tile since they have no persisted song list to pull artwork from
/// until you actually tap one.
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
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: totalCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (i < manual.length) {
                final p = manual[i];
                return _PlaylistCard(
                  cover: PlaylistCoverWidget(songIds: p.songIds, size: 80),
                  label: p.name,
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
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox(),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Widget cover;
  final String label;
  final VoidCallback onTap;

  const _PlaylistCard({required this.cover, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          const SizedBox(height: 4),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon-tile version for Automatic/AI playlists - same card shape as
/// manual playlists' artwork mosaic, but there's no song list to pull
/// artwork from until the query actually runs on tap.
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
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _loading
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : Icon(widget.def.icon, color: Colors.white, size: 32),
        ),
      ),
      label: widget.def.title,
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