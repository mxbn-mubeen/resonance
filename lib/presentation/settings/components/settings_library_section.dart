import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';

class SettingsLibrarySection extends ConsumerWidget {
  const SettingsLibrarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiOnly = ref.watch(wifiOnlyDownloadsProvider);
    final artworkQuality = ref.watch(artworkQualityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Folders', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Add folder to scan'),
          subtitle: const Text('Choose specific directories to include'),
          onTap: () async {
            String? selectedDirectory = await FilePicker.getDirectoryPath();
            if (selectedDirectory != null) {
              ref.read(includedFoldersProvider.notifier).addFolder(selectedDirectory);
            }
          },
        ),
        ...ref.watch(includedFoldersProvider).when(
          data: (folders) => folders.map((f) => ListTile(
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: Text(f),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
              onPressed: () => ref.read(includedFoldersProvider.notifier).removeFolder(f),
            ),
          )).toList(),
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (err, _) => [ListTile(title: Text('Error: $err'))],
        ),
        ListTile(
          leading: const Icon(Icons.block),
          title: const Text('Default excluded folders'),
          subtitle: Text(kDefaultExcludedFolderNames.join(', ')),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Storage', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.high_quality),
          title: const Text('Artwork quality'),
          subtitle: Text('${artworkQuality.maxDimension}px, quality ${artworkQuality.jpegQuality}'),
          trailing: DropdownButton<ArtworkQuality>(
            value: artworkQuality,
            underline: const SizedBox.shrink(),
            items: ArtworkQuality.values
                .map((q) => DropdownMenuItem(value: q, child: Text(q.name)))
                .toList(),
            onChanged: (q) {
              if (q != null) ref.read(artworkQualityProvider.notifier).state = q;
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('Clear artwork cache'),
          subtitle: const Text('Frees storage — artwork will be re-extracted on next scan'),
          onTap: () async {
            await ref.read(artworkManagerProvider).clearCache();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Artwork cache cleared')),
              );
            }
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.wifi),
          title: const Text('Download on Wi-Fi only'),
          subtitle: const Text('Artwork and metadata fetching skipped on mobile data'),
          value: wifiOnly,
          onChanged: (v) => ref.read(wifiOnlyDownloadsProvider.notifier).state = v,
        ),
      ],
    );
  }
}
