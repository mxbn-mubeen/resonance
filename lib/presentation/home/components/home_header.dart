import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/song.dart';
import '../../player/player_route.dart';
import '../../settings/library_health_screen.dart';

class HomeHeader extends ConsumerWidget {
  final List<Song> songs;

  const HomeHeader({super.key, required this.songs});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final greeting = _greeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${songs.length} tracks in your library',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.health_and_safety_outlined, size: 20),
              tooltip: 'Library Health',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryHealthScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Quick Action Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionChip(
                icon: Icons.shuffle_rounded,
                label: 'Shuffle All',
                isPrimary: true,
                onTap: () async {
                  if (songs.isNotEmpty) {
                    await ref.read(playbackControllerProvider).playSongs(songs, shuffle: true);
                    if (context.mounted) {
                      Navigator.of(context).push(PlayerRoute());
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                icon: Icons.play_arrow_rounded,
                label: 'Play All',
                isPrimary: false,
                onTap: () async {
                  if (songs.isNotEmpty) {
                    await ref.read(playbackControllerProvider).playSongs(songs);
                    if (context.mounted) {
                      Navigator.of(context).push(PlayerRoute());
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
              _QuickActionChip(
                icon: Icons.favorite_rounded,
                iconColor: Colors.pinkAccent,
                label: 'Favorites',
                isPrimary: false,
                onTap: () async {
                  final favs = songs.where((s) => s.favorite).toList();
                  if (favs.isNotEmpty) {
                    await ref.read(playbackControllerProvider).playSongs(favs, shuffle: true);
                    if (context.mounted) {
                      Navigator.of(context).push(PlayerRoute());
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No favorite songs yet')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isPrimary
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fg = isPrimary
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor ?? fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
