import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import 'folder_picker_sheet.dart';

class SettingsLibrarySection extends ConsumerWidget {
  const SettingsLibrarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiOnly = ref.watch(wifiOnlyDownloadsProvider);
    final artworkQuality = ref.watch(artworkQualityProvider);
    final includedAsync = ref.watch(includedFoldersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Folders', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.create_new_folder_rounded),
          title: const Text('Add folders to scan'),
          subtitle: const Text('Select multiple folders or common directories at once'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => FolderPickerSheet.show(context),
        ),
        ...includedAsync.when(
          data: (folders) {
            if (folders.isEmpty) {
              return [
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.info_outline, size: 20, color: Colors.orangeAccent),
                  title: Text('No custom folders added', style: TextStyle(fontSize: 13)),
                  subtitle: Text('Tap "Add folders to scan" to include music locations.', style: TextStyle(fontSize: 11)),
                ),
              ];
            }
            return folders.map((f) => ListTile(
              dense: true,
              leading: const Icon(Icons.folder_outlined, size: 20),
              title: Text(f, style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                onPressed: () => ref.read(includedFoldersProvider.notifier).removeFolder(f),
              ),
            )).toList();
          },
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
