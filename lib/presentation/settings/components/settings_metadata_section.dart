import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../metadata_fetch_screen.dart';

class SettingsMetadataSection extends ConsumerWidget {
  const SettingsMetadataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Metadata Providers', style: Theme.of(context).textTheme.labelLarge),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('MusicBrainz'),
          subtitle: Text('Primary source — authoritative, no API key needed'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        const ListTile(
          leading: Icon(Icons.cloud),
          title: Text('iTunes'),
          subtitle: Text('Fallback source — good for Tamil/regional music'),
          trailing: Icon(Icons.check_circle, color: Colors.green),
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('Fetch missing metadata now'),
          subtitle: const Text('MusicBrainz → iTunes → local ID3 fallback'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MetadataFetchScreen()),
            );
          },
        ),
      ],
    );
  }
}