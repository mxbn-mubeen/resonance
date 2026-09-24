import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/settings_library_section.dart';
import 'components/settings_metadata_section.dart';
import 'components/settings_background_reliability_section.dart';
import 'components/settings_theme_section.dart';
import 'components/settings_health_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Library'),
              Tab(text: 'Metadata'),
              Tab(text: 'Background'),
              Tab(text: 'Theme'),
              Tab(text: 'Health'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SingleChildScrollView(child: SettingsLibrarySection()),
            SingleChildScrollView(child: SettingsMetadataSection()),
            SingleChildScrollView(child: SettingsBackgroundReliabilitySection()),
            SingleChildScrollView(child: SettingsThemeSection()),
            SingleChildScrollView(child: SettingsHealthSection()),
          ],
        ),
      ),
    );
  }
}