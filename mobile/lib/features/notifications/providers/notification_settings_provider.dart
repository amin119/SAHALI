import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/status_badge.dart';

/// User-controlled preferences for the local/push notification system.
/// Mirrors the shape of [ThemeProvider]/[LanguageProvider]: a
/// [ChangeNotifier] backed by [SharedPreferences].
class NotificationSettingsProvider extends ChangeNotifier {
  static const _pushKey = 'notif_push_enabled';
  static const _statusesKey = 'notif_enabled_statuses';

  bool _pushEnabled = true;
  Set<String> _enabledStatuses = ReportStatus.values.map((s) => s.name).toSet();

  bool get pushEnabled => _pushEnabled;
  bool isStatusEnabled(ReportStatus status) => _enabledStatuses.contains(status.name);

  NotificationSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _pushEnabled = prefs.getBool(_pushKey) ?? true;
    final saved = prefs.getStringList(_statusesKey);
    if (saved != null) _enabledStatuses = saved.toSet();
    notifyListeners();
  }

  Future<void> setPushEnabled(bool value) async {
    if (_pushEnabled == value) return;
    _pushEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, value);
  }

  Future<void> toggleStatus(ReportStatus status) async {
    if (_enabledStatuses.contains(status.name)) {
      _enabledStatuses.remove(status.name);
    } else {
      _enabledStatuses.add(status.name);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_statusesKey, _enabledStatuses.toList());
  }
}
