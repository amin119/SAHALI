import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/status_badge.dart';

/// Wraps `flutter_local_notifications` to surface device-level (native)
/// notifications for in-app events — primarily report status changes.
///
/// This covers the "local" half of the push story: a real system
/// notification while the app is installed and the OS permission is
/// granted. True remote/background push (delivered while the app isn't
/// running) needs Firebase Cloud Messaging wired up on top of this — the
/// backend already sends FCM messages to `user.fcm_token` (see
/// `backend/app/services/notification.py`) and `PATCH /users/me` already
/// accepts a token to store, so that's a follow-up once a Firebase project
/// exists for this app (google-services.json / GoogleService-Info.plist).
class LocalNotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  static const _askedKey = 'notif_permission_asked';
  static const _grantedKey = 'notif_permission_granted';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit, macOS: iosInit),
      );
      _initialized = true;
    } catch (_) {
      // Platform without full local-notification support (e.g. web without
      // the plugin's JS setup) — fail silently, the app works without it.
    }
  }

  /// Requests the OS notification permission once (Android 13+, iOS).
  /// Subsequent calls return the previously recorded answer without
  /// re-prompting, per the platform's own single-prompt convention.
  Future<bool> requestPermissionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) {
      return prefs.getBool(_grantedKey) ?? false;
    }
    await prefs.setBool(_askedKey, true);
    await init();

    var granted = true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        granted = await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        granted = await ios.requestPermissions(alert: true, badge: true, sound: true) ?? true;
      }
    } catch (_) {
      // No native permission API on this platform — assume granted so
      // local notifications are attempted; `notifyStatusChange` no-ops
      // harmlessly if the platform can't actually show one.
    }
    await prefs.setBool(_grantedKey, granted);
    return granted;
  }

  /// Shows a native notification for a report status update, honoring the
  /// user's push master toggle and per-status preferences.
  Future<void> notifyStatusChange({
    required int id,
    required String title,
    required String body,
    required ReportStatus status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
    if (!pushEnabled) return;
    final enabledStatuses = prefs.getStringList('notif_enabled_statuses');
    if (enabledStatuses != null && !enabledStatuses.contains(status.name)) return;
    if (!(prefs.getBool(_grantedKey) ?? false)) return;

    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'status_updates',
        'Mises à jour de signalement',
        channelDescription: 'Alertes de changement de statut de vos signalements',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Best-effort: the in-app notification list is the source of truth,
      // the native banner is a bonus.
    }
  }
}
