import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the foreground task isolate. Must be a top-level
/// function with this pragma, or Android can't find it after the app
/// process is restarted.
@pragma('vm:entry-point')
void startWorkoutTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

/// The handler runs in a separate isolate. It stays intentionally empty:
/// its only job is to hold the foreground service (and its wakelock) so
/// Android keeps our process — with the ticking WorkoutEngine — alive and
/// un-throttled while the screen is off or another app is in front.
class _WorkoutTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Thin wrapper around flutter_foreground_task for the workout notification.
/// All methods are safe no-ops on platforms without foreground services.
class WorkoutForegroundService {
  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.android && !kIsWeb;

  static void init() {
    if (!_supported) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fittimer_workout',
        channelName: 'Workout in progress',
        channelDescription:
            'Persistent notification while a workout timer is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
  }

  /// Ask for the Android 13+ notification permission (needed to show the
  /// persistent workout notification).
  static Future<void> requestPermissions() async {
    if (!_supported) return;
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  static Future<void> start(String title, String text) async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 1,
        notificationTitle: title,
        notificationText: text,
        callback: startWorkoutTaskCallback,
      );
    }
  }

  static Future<void> update(String title, String text) async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    }
  }

  static Future<void> stop() async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
