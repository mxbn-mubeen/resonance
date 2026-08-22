import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import '../../../application/playback/playback_controller.dart';

class QueueSheet extends StatefulWidget {
  final PlaybackController controller;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const QueueSheet({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onClose,
  });

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  static const double _itemHeight = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    final state = widget.controller.rawPlayer.sequenceState;
    if (state == null) return;
    
    // Find the current index within the effective (potentially shuffled) sequence
    final effectiveIndices = widget.controller.rawPlayer.effectiveIndices;
    final idx = effectiveIndices != null ? effectiveIndices.indexOf(state.currentIndex) : state.currentIndex;
    if (idx == -1) return;
    
    if (!widget.scrollController.hasClients) return;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final target = (idx * _itemHeight).clamp(0.0, maxScroll);
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: widget.controller.sequenceStateStream,
      builder: (context, snap) {
        final state = snap.data;
        if (state == null) return const SizedBox.shrink();

        final sequence = state.effectiveSequence;
        final effectiveIndices = widget.controller.rawPlayer.effectiveIndices;
        final currentIdx = effectiveIndices != null ? effectiveIndices.indexOf(state.currentIndex) : state.currentIndex;
        
        final allSongs = widget.controller.currentQueue;
        final shuffleEnabled = widget.controller.rawPlayer.shuffleModeEnabled;
        
        // Map the effective (shuffled) sequence back to our Song models
        final queue = sequence.map((source) {
          final mediaItem = source.tag as MediaItem;
          return allSongs.firstWhere(
            (s) => s.id == mediaItem.id,
            orElse: () => allSongs.first,
          );
        }).toList();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Up Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${queue.length} songs',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: widget.scrollController,
                itemExtent: _itemHeight,
                itemCount: queue.length,
                onReorder: shuffleEnabled
                    ? (a, b) {} // Disable reordering while shuffled
                    : (oldIndex, newIndex) {
                        widget.controller.reorderQueue(oldIndex, newIndex);
                      },
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.grey.shade800.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isCurrent = index == currentIdx;
                  return ListTile(
                    key: ValueKey(song.id + index.toString()),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: SizedBox(
                      width: 36,
                      child: isCurrent
                          ? const Icon(Icons.bar_chart, color: Colors.greenAccent, size: 22)
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ),
                    ),
                    title: Text(
                      song.title ?? song.filename,
                      style: TextStyle(
                        color: isCurrent ? Colors.greenAccent : Colors.white,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? 'Unknown Artist',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: shuffleEnabled
                        ? const SizedBox(width: 24, height: 24) // Hide handle if shuffled
                        : ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: Colors.white38),
                          ),
                    onTap: () async {
                      // We must map the effective index back to the ORIGINAL index to seek!
                      // The index tapped is the `index` in the effective sequence.
                      // state.effectiveIndices maps original index -> effective index?
                      // No, effectiveIndices is a list where each element is an original index,
                      // and the position in the list is the effective index!
                      // E.g. effectiveIndices[3] = 10 means the 3rd item played is actually the 10th item in the original playlist.
                      final effectiveIndices = widget.controller.rawPlayer.effectiveIndices;
                      final originalIndex = effectiveIndices != null ? effectiveIndices[index] : index;
                      await widget.controller.skipToQueueItem(originalIndex);
                      widget.onClose();
                    },
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

