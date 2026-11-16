import 'package:flutter/material.dart';

import '../../../domain/entities/song.dart';

class DuplicatesDialog extends StatefulWidget {
  final List<Song> duplicates;
  final Future<void> Function(Song) onDelete;

  const DuplicatesDialog({
    super.key,
    required this.duplicates,
    required this.onDelete,
  });

  @override
  State<DuplicatesDialog> createState() => _DuplicatesDialogState();
}

class _DuplicatesDialogState extends State<DuplicatesDialog> {
  late final List<Song> _songs;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.duplicates);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Duplicate Tracks (${_songs.length})'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: _songs.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('All duplicates removed.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _songs.length,
                itemBuilder: (ctx, i) {
                  final s = _songs[i];
                  final name = '${s.artist ?? 'Unknown'} – ${s.title ?? s.filename}';
                  return ListTile(
                    dense: true,
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      s.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    trailing: _deleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () async {
                              setState(() => _deleting = true);
                              await widget.onDelete(s);
                              if (mounted) {
                                setState(() {
                                  _songs.removeAt(i);
                                  _deleting = false;
                                });
                              }
                            },
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
