import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'application/playback/playback_controller.dart';
import 'core/di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registers the background audio service so playback survives the app
  // being backgrounded and shows notification/lock-screen controls.
  final playbackController = await AudioService.init(
    builder: () => PlaybackController(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yourname.offline_music_platform.channel',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Real singleton instance, overriding the UnimplementedError stub
        // in core/di/providers.dart.
        playbackControllerProvider.overrideWithValue(playbackController),
      ],
      child: const OfflineMusicApp(),
    ),
  );
}
