import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../library/group_detail_screen.dart';
import '../smart_playlist_definitions.dart';

class AutoPlaylistTile extends ConsumerStatefulWidget {
  final SmartPlaylistDef def;

  const AutoPlaylistTile({super.key, required this.def});

  @override
  ConsumerState<AutoPlaylistTile> createState() => _AutoPlaylistTileState();
}

class _AutoPlaylistTileState extends ConsumerState<AutoPlaylistTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(widget.def.icon, color: Colors.white, size: 24),
      ),
      title: Text(widget.def.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        widget.def.subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.white54),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: _loading ? null : () => openSmartPlaylist(context, ref, widget.def),
    );
  }
}

Future<void> openSmartPlaylist(BuildContext context, WidgetRef ref, SmartPlaylistDef def) async {
  final engine = await ref.read(playlistEngineProvider.future);
  final songs = await def.loader(engine);
  if (!context.mounted) return;

  if (songs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No songs match "${def.title}" yet')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => GroupDetailScreen(
        title: def.title,
        songs: songs,
        subtitle: '${songs.length} tracks',
      ),
    ),
  );
}
