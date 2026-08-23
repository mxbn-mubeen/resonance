import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/playback/playback_controller.dart';
import '../../core/di/providers.dart';
import '../../data/remote/lrclib_api.dart';
import '../../domain/entities/song.dart';
import 'components/plain_lyrics_view.dart';
import 'components/synced_lyrics_view.dart';

/// Full-screen lyrics view, Apple Music style - slides up over the player.
/// Deliberately inherits the exact same blurred-backdrop treatment as
/// PlayerScreen (same palette service, same blur radius/opacity) so it
/// reads as part of the same screen, not a bolted-on separate feature.
class LyricsScreen extends ConsumerStatefulWidget {
  final Song song;
  final PlaybackController controller;
  final String? artworkPath;

  const LyricsScreen({
    super.key,
    required this.song,
    required this.controller,
    required this.artworkPath,
  });

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  // Cache the future so rebuilds (e.g. from palette resolution) don't
  // create a new Future each time and reset FutureBuilder back to waiting.
  late final Future<LyricsResult?> _lyricsFuture;
  // Warm golden fallback — replaced once the palette resolves.
  Color _accentColor = const Color(0xFFFFD580);

  @override
  void initState() {
    super.initState();
    _lyricsFuture = ref
        .read(lyricsManagerProvider.future)
        .then((m) => m.getLyricsForSong(widget.song));
    // Resolve accent once — don't use a FutureBuilder so _SyncedLyricsView
    // isn't destroyed/recreated each time the palette resolves.
    _resolveAccent();
  }

  Future<void> _resolveAccent() async {
    final paletteService = ref.read(artworkPaletteServiceProvider);
    final color = await paletteService.accentColorFor(widget.artworkPath);
    if (color != null && mounted) {
      setState(() => _accentColor = color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paletteService = ref.watch(artworkPaletteServiceProvider);

    return FutureBuilder<Color?>(
      future: paletteService.dominantColorFor(widget.artworkPath),
      builder: (context, paletteSnapshot) {
        final backdropColor = paletteSnapshot.data ?? Theme.of(context).colorScheme.primaryContainer;

        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            color: backdropColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.artworkPath != null)
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.file(File(widget.artworkPath!), fit: BoxFit.cover, alignment: Alignment.center),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Expanded(
                      child: FutureBuilder<LyricsResult?>(
                        future: _lyricsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.white70));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                          }
                          final result = snapshot.data;
                          if (result == null || result.isEmpty) {
                            return _NoLyricsState(widget.song);
                          }
                          if (result.syncedLyrics != null && result.syncedLyrics!.trim().isNotEmpty) {
                            return SyncedLyricsView(
                              rawLrc: result.syncedLyrics!,
                              controller: widget.controller,
                              accentColor: _accentColor,
                            );
                          }
                          return PlainLyricsView(
                            text: result.plainLyrics ?? '',
                            accentColor: _accentColor,
                          );
                        },
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoLyricsState extends StatelessWidget {
  final Song song;
  const _NoLyricsState(this.song);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No lyrics found',
            style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Searched: ${song.title ?? song.filename}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}


