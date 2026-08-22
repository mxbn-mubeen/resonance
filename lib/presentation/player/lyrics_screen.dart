import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/lyrics/lrc_parser.dart';
import '../../application/playback/playback_controller.dart';
import '../../core/di/providers.dart';
import '../../data/remote/lrclib_api.dart';
import '../../domain/entities/song.dart';

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

  @override
  void initState() {
    super.initState();
    _lyricsFuture = ref
        .read(lyricsManagerProvider.future)
        .then((m) => m.getLyricsForSong(widget.song));
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
                            // Debug: show raw state on screen
                            if (result == null) {
                              return const Center(child: Text('DEBUG: result=null', style: TextStyle(color: Colors.yellow, fontSize: 16)));
                            }
                            if (result.isEmpty) {
                              return _NoLyricsState(widget.song);
                            }
                            if (result.syncedLyrics != null && result.syncedLyrics!.trim().isNotEmpty) {
                              return _SyncedLyricsView(rawLrc: result.syncedLyrics!, controller: widget.controller);
                            }
                            return _PlainLyricsView(text: result.plainLyrics ?? 'DEBUG: plainLyrics is null/empty');
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

class _PlainLyricsView extends StatelessWidget {
  final String text;
  const _PlainLyricsView({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Custom scrolling synced-lyrics list, built from scratch rather than a
/// pre-built package. Auto-scroll uses per-line GlobalKeys +
/// Scrollable.ensureVisible instead of a fixed-height-per-line estimate,
/// since real lyric lines vary in wrapped height and a fixed estimate
/// would drift out of sync over a long song - measuring the actual
/// rendered line position stays accurate regardless of wrapping.
class _SyncedLyricsView extends StatefulWidget {
  final String rawLrc;
  final PlaybackController controller;

  const _SyncedLyricsView({required this.rawLrc, required this.controller});

  @override
  State<_SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<_SyncedLyricsView> {
  late final List<LrcLine> _lines;
  late final List<GlobalKey> _lineKeys;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _lines = LrcParser.parse(widget.rawLrc);
    _lineKeys = List.generate(_lines.length, (_) => GlobalKey());
  }

  void _handlePosition(Duration position) {
    final newIndex = LrcParser.activeLineIndex(_lines, position);
    if (newIndex != _activeIndex && newIndex >= 0) {
      setState(() => _activeIndex = newIndex);
      // Wait a frame so the highlighted line's new style/size is laid out
      // before measuring where to scroll to.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _lineKeys[newIndex].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return const Center(child: Text('Failed to parse lyrics', style: TextStyle(color: Colors.white70)));
    }

    return StreamBuilder<Duration>(
      stream: widget.controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        // Scheduled after build, not during - this callback can trigger a
        // setState, which isn't allowed mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) => _handlePosition(position));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
          itemCount: _lines.length,
          itemBuilder: (context, index) {
            final isActive = index == _activeIndex;
            return Padding(
              key: _lineKeys[index],
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: isActive ? 22 : 18,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  height: 1.4,
                ),
                child: Text(
                  _lines[index].text.isEmpty ? '♪' : _lines[index].text,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
