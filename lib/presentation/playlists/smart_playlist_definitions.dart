import 'package:flutter/material.dart';

import '../../application/playlist/playlist_engine.dart';
import '../../domain/entities/song.dart';

/// One "computed on tap" playlist - Automatic or AI. Nothing here is
/// persisted; [loader] runs a live query/filter over the local library
/// each time it's called, so results are always current with zero sync
/// logic needed.
class SmartPlaylistDef {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<List<Song>> Function(PlaylistEngine engine) loader;

  const SmartPlaylistDef({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loader,
  });
}

/// Single source of truth, used by both the Playlists tab and the Home
/// screen rail - defined once here so the two surfaces can't drift out of
/// sync with each other.
const List<SmartPlaylistDef> kAutomaticPlaylistDefs = [
  SmartPlaylistDef(
    icon: Icons.trending_up,
    title: 'Most Played',
    subtitle: 'Your most-listened tracks',
    loader: _mostPlayed,
  ),
  SmartPlaylistDef(
    icon: Icons.fiber_new,
    title: 'Recently Added',
    subtitle: 'Latest additions to your library',
    loader: _recentlyAdded,
  ),
  SmartPlaylistDef(
    icon: Icons.history,
    title: 'Recently Played',
    subtitle: "What you've been listening to",
    loader: _recentlyPlayed,
  ),
  SmartPlaylistDef(
    icon: Icons.new_releases,
    title: 'Never Played',
    subtitle: 'Songs waiting for their first spin',
    loader: _neverPlayed,
  ),
];

const List<SmartPlaylistDef> kAiPlaylistDefs = [
  SmartPlaylistDef(
    icon: Icons.nightlife,
    title: 'Night Drive',
    subtitle: 'Genre-matched · not true mood detection yet',
    loader: _nightDrive,
  ),
  SmartPlaylistDef(
    icon: Icons.spa,
    title: 'Relax',
    subtitle: 'Genre-matched · not true mood detection yet',
    loader: _relax,
  ),
  SmartPlaylistDef(
    icon: Icons.fitness_center,
    title: 'Workout',
    subtitle: 'Genre-matched · not true mood detection yet',
    loader: _workout,
  ),
  SmartPlaylistDef(
    icon: Icons.center_focus_strong,
    title: 'Focus',
    subtitle: 'Genre-matched · not true mood detection yet',
    loader: _focus,
  ),
];

// Top-level functions (not closures) so the const list literals above stay
// const - a lambda capturing nothing still isn't a compile-time constant
// in Dart, but a tear-off of a top-level function is.
Future<List<Song>> _mostPlayed(PlaylistEngine e) => e.mostPlayed();
Future<List<Song>> _recentlyAdded(PlaylistEngine e) => e.recentlyAdded();
Future<List<Song>> _recentlyPlayed(PlaylistEngine e) => e.recentlyPlayed();
Future<List<Song>> _neverPlayed(PlaylistEngine e) => e.neverPlayed();
Future<List<Song>> _nightDrive(PlaylistEngine e) => e.moodPlaylist('Night Drive');
Future<List<Song>> _relax(PlaylistEngine e) => e.moodPlaylist('Relax');
Future<List<Song>> _workout(PlaylistEngine e) => e.moodPlaylist('Workout');
Future<List<Song>> _focus(PlaylistEngine e) => e.moodPlaylist('Focus');