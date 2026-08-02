import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiOnly = ref.watch(wifiOnlyDownloadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Folders'),
          const ListTile(
            leading: Icon(Icons.folder),
            title: Text('Manage scanned folders'),
            subtitle: Text('Choose which folders are included/excluded'),
            // TODO(settings_screen): open a folder picker (e.g. via
            // file_picker or a native SAF intent) and persist the chosen
            // paths into includedFoldersProvider / a settings table.
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Default excluded folders'),
            subtitle: Text(kDefaultExcludedFolderNames.join(', ')),
          ),
          const _SectionHeader('Metadata Providers'),
          const ListTile(leading: Icon(Icons.cloud), title: Text('MusicBrainz'), trailing: Icon(Icons.check_circle, color: Colors.green)),
          const ListTile(leading: Icon(Icons.cloud), title: Text('iTunes'), trailing: Icon(Icons.check_circle, color: Colors.green)),
          const ListTile(leading: Icon(Icons.cloud_off), title: Text('AcoustID (coming soon)')),
          const ListTile(leading: Icon(Icons.cloud_off), title: Text('Discogs (coming soon)')),
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Accent Color'),
            trailing: CircleAvatar(backgroundColor: ref.watch(accentColorProvider), radius: 12),
            onTap: () {
              // TODO(settings_screen): open a color picker and update
              // accentColorProvider.
            },
          ),
          const _SectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Artwork quality'),
            subtitle: Text(
                '${ref.watch(artworkQualityProvider).maxDimension}px, quality ${ref.watch(artworkQualityProvider).jpegQuality}'),
            trailing: DropdownButton<ArtworkQuality>(
              value: ref.watch(artworkQualityProvider),
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
            onTap: () => ref.read(artworkManagerProvider).clearCache(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Download on Wi-Fi only'),
            value: wifiOnly,
            onChanged: (v) => ref.read(wifiOnlyDownloadsProvider.notifier).state = v,
          ),
          const _SectionHeader('Library Health'),
          const ListTile(
            leading: Icon(Icons.health_and_safety),
            title: Text('Run Library Health report'),
            subtitle: Text('Missing tags, duplicates, broken artwork, corrupted files'),
            // TODO(settings_screen): wire to DuplicateDetector + a tag
            // completeness scan + artwork-file-exists check.
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
