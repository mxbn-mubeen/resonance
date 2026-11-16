import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

class FolderPickerSheet extends ConsumerStatefulWidget {
  const FolderPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FolderPickerSheet(),
    );
  }

  @override
  ConsumerState<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<FolderPickerSheet> {
  final List<String> _detectedFolders = [];
  final Set<String> _selectedDetected = {};
  bool _scanningDirectories = true;

  @override
  void initState() {
    super.initState();
    _detectCommonFolders();
  }

  Future<void> _detectCommonFolders() async {
    final candidates = <String>[];
    if (Platform.isAndroid) {
      candidates.addAll([
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Audiobooks',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/Snaptube/download/Audio',
        '/storage/emulated/0/Telegram/Telegram Audio',
        '/sdcard/Music',
        '/sdcard/Download',
      ]);
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      if (userProfile.isNotEmpty) {
        candidates.addAll([
          '$userProfile\\Music',
          '$userProfile\\Downloads',
        ]);
      }
    }

    final found = <String>[];
    for (final path in candidates) {
      try {
        if (Directory(path).existsSync()) {
          found.add(path);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _detectedFolders.addAll(found);
        _scanningDirectories = false;
      });
    }
  }

  Future<void> _pickSingleFolder() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir != null && mounted) {
      await ref.read(includedFoldersProvider.notifier).addFolder(dir);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $dir')),
        );
      }
    }
  }

  Future<void> _addSelectedFolders() async {
    if (_selectedDetected.isEmpty) return;
    await ref.read(includedFoldersProvider.notifier).addFolders(_selectedDetected.toList());
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Added ${_selectedDetected.length} folders')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIncluded = ref.watch(includedFoldersProvider).valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Include Music Folders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select multiple folders at once or browse your device storage.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Browse Device Storage'),
            onPressed: _pickSingleFolder,
          ),
          const SizedBox(height: 16),
          if (_scanningDirectories)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_detectedFolders.isNotEmpty) ...[
            const Text(
              'Common Storage Folders Found',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _detectedFolders.length,
                itemBuilder: (ctx, i) {
                  final folder = _detectedFolders[i];
                  final isAlreadyAdded = currentIncluded.contains(folder);
                  final isChecked = _selectedDetected.contains(folder);

                  return CheckboxListTile(
                    dense: true,
                    title: Text(folder.split(Platform.pathSeparator).last,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(folder,
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    value: isAlreadyAdded ? true : isChecked,
                    onChanged: isAlreadyAdded
                        ? null
                        : (val) {
                            setState(() {
                              if (val == true) {
                                _selectedDetected.add(folder);
                              } else {
                                _selectedDetected.remove(folder);
                              }
                            });
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text('Add Selected (${_selectedDetected.length})'),
              onPressed: _selectedDetected.isEmpty ? null : _addSelectedFolders,
            ),
          ],
        ],
      ),
    );
  }
}
