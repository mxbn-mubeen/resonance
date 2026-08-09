import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/di/providers.dart';

class HomeEmptyPrompt extends ConsumerWidget {
  const HomeEmptyPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('No music found yet', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Pick the folder where your music is stored to begin scanning.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Folder & Scan'),
              onPressed: () async {
                final selectedDir = await FilePicker.getDirectoryPath();
                if (selectedDir == null) return;
                if (!context.mounted) return;

                await ref.read(includedFoldersProvider.notifier).addFolder(selectedDir);

                final scanner = await ref.read(scannerServiceProvider.future);
                final granted = await scanner.requestPermission();
                if (!granted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Storage permission denied')),
                    );
                  }
                  return;
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scanning $selectedDir…')),
                  );
                }

                final result = await scanner.scan(includedFolderPaths: [selectedDir]);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.newOrUpdated} new, ${result.updated} updated, '
                        '${result.unchanged} unchanged',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
