import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/providers.dart';

class SettingsThemeSection extends ConsumerWidget {
  const SettingsThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Appearance', style: Theme.of(context).textTheme.labelLarge),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Accent Color'),
          trailing: CircleAvatar(
            backgroundColor: ref.watch(accentColorProvider).valueOrNull ?? AppTheme.defaultAccent,
            radius: 12,
          ),
          onTap: () {
            final currentColor = ref.read(accentColorProvider).valueOrNull ?? AppTheme.defaultAccent;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick an accent color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: currentColor,
                    onColorChanged: (c) {
                      ref.read(accentColorProvider.notifier).setColor(c);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
