import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _loading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _service.listNotifications();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = dioMessage(e);
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = NotificationModel(
          id: _notifications[idx].id,
          reportId: _notifications[idx].reportId,
          title: _notifications[idx].title,
          body: _notifications[idx].body,
          isRead: true,
          createdAt: _notifications[idx].createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    for (final n in _notifications.where((n) => !n.isRead).toList()) {
      await markRead(n.id);
    }
  }
}
