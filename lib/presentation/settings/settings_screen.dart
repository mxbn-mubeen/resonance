import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/settings_library_section.dart';
import 'components/settings_metadata_section.dart';
import 'components/settings_theme_section.dart';
import 'components/settings_health_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SettingsLibrarySection(),
          SettingsMetadataSection(),
          SettingsThemeSection(),
          SettingsHealthSection(),
        ],
      ),
    );
  }
}
