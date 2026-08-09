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
    final idx = widget.controller.rawPlayer.currentIndex ?? 0;
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
    return StreamBuilder<int?>(
      stream: widget.controller.currentIndexStream,
      builder: (context, snap) {
        final currentIdx = snap.data ?? 0;
        final queue = widget.controller.currentQueue;

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
                onReorder: (oldIndex, newIndex) {
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
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: Colors.white38),
                    ),
                    onTap: () async {
                      await widget.controller.skipToQueueItem(index);
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
