import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

/// Displays a 2×2 grid of the first 4 song artworks from a playlist,
/// mimicking the Spotify playlist cover style.
/// Falls back to a gradient icon tile for empty/missing slots.
class PlaylistCoverWidget extends ConsumerWidget {
  final List<String> songIds; // ordered playlist song IDs
  final double size;

  const PlaylistCoverWidget({
    super.key,
    required this.songIds,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String?>>(
      future: _fetchArtworkPaths(ref, songIds.take(4).toList()),
      builder: (context, snapshot) {
        final paths = snapshot.data ?? [];
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.12),
          child: SizedBox(
            width: size,
            height: size,
            child: _buildCover(context, paths),
          ),
        );
      },
    );
  }

  Widget _buildCover(BuildContext context, List<String?> paths) {
    // Filter valid paths
    final valid = paths.where((p) => p != null && File(p!).existsSync()).toList();

    if (valid.isEmpty) {
      return _gradientPlaceholder(context);
    }

    if (valid.length == 1) {
      return Image.file(File(valid[0]!), fit: BoxFit.cover);
    }

    // 2×2 grid — fill remaining slots with placeholder color
    final slots = List<String?>.generate(4, (i) => i < valid.length ? valid[i] : null);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      children: slots.map((path) {
        if (path != null) {
          return Image.file(File(path), fit: BoxFit.cover);
        }
        return Container(color: Colors.grey.shade800);
      }).toList(),
    );
  }

  Widget _gradientPlaceholder(BuildContext context) {
    return Container(
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
      child: Icon(Icons.queue_music, color: Colors.white, size: size * 0.45),
    );
  }

  Future<List<String?>> _fetchArtworkPaths(WidgetRef ref, List<String> ids) async {
    if (ids.isEmpty) return [];
    final repo = await ref.read(libraryRepositoryProvider.future);
    final allSongs = await repo.getAllSongs();
    return ids.map((id) {
      try {
        return allSongs.firstWhere((s) => s.id == id).artworkPath;
      } catch (_) {
        return null;
      }
    }).toList();
  }
}
