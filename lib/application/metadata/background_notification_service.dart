import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'metadata_fetch_result.dart';

class BackgroundNotificationService {
  const BackgroundNotificationService._();

  static Future<void> postProgressNotification(int processed, int total) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidInit));

    await plugin.show(
      1001,
      'Fetching Metadata',
      'Processed $processed / $total songs...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'resonance_metadata',
          'Resonance Metadata',
          channelDescription: 'Background metadata fetch status',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  /// Posts an Android completion notification. Safe from a background isolate.
  static Future<void> postNotification(MetadataFetchResult result) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: androidInit));

    final parts = <String>['${result.updated} updated'];
    if (result.noMatch > 0) parts.add('${result.noMatch} no match');
    if (result.errors > 0) parts.add('${result.errors} errors');

    String title = result.errors > 0
        ? 'Metadata fetch finished with errors'
        : 'Metadata fetch complete';
        
    if (result.abortedByTimeout) {
      title = 'Metadata fetch paused (time limit reached)';
    }

    await plugin.show(
      1001,
      title,
      parts.join(' · '),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'resonance_metadata',
          'Resonance Metadata',
          channelDescription: 'Background metadata fetch status',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showProgress: false,
        ),
      ),
    );
  }
}
