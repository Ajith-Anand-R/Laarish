import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Opt-in daily reminder, max 1/day (AGENT.md privacy/COPPA-mindedness —
/// nothing is scheduled without the user flipping the toggle on this
/// screen). Uses `periodicallyShow(... RepeatInterval.daily)` rather than
/// `zonedSchedule` so we don't need the `timezone` package as a new dep —
/// good enough for "once a day, mascot-voiced nudge" (GAMIFICATION.md §3).
/// No custom notification icon asset exists yet, so this uses the default
/// app launcher icon (@mipmap/ic_launcher) per the CRITICAL CONSTRAINT.
class GardenNotificationService {
  GardenNotificationService._();
  static final instance = GardenNotificationService._();

  static const _id = 1001;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    await _ensureInit();
    if (!enabled) {
      await _plugin.cancel(_id);
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin.periodicallyShow(
      _id,
      'Misty is thirsty for work! \u{1F4A6}',
      'Your garden has a mission waiting today.',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'garden_daily',
          'Daily garden reminder',
          channelDescription: 'One gentle nudge a day to visit your garden.',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
