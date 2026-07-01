import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../../data/services/offline_queue_service.dart';

class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  Timer? _timer;
  bool _syncing = false;
  int _pendingCount = 0;

  int get pendingCount => _pendingCount;
  bool get hasPending => _pendingCount > 0;

  Future<void> init() async {
    _pendingCount = await OfflineQueueService.instance.count();
    notifyListeners();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => flush());
    flush();
  }

  Future<void> enqueue(Map<String, dynamic> payload) async {
    await OfflineQueueService.instance.enqueue(payload);
    _pendingCount = await OfflineQueueService.instance.count();
    notifyListeners();
  }

  Future<int> flush() async {
    if (_syncing) return 0;
    _syncing = true;
    int sent = 0;
    try {
      final pending = await OfflineQueueService.instance.getPending();
      for (final report in pending) {
        try {
          await ApiClient.instance.dio.post('/reports/anonymous', data: report.payload);
          await OfflineQueueService.instance.remove(report.id);
          sent++;
        } catch (_) {
          break; // network still down — stop trying
        }
      }
      if (sent > 0) {
        _pendingCount = await OfflineQueueService.instance.count();
        notifyListeners();
      }
    } finally {
      _syncing = false;
    }
    return sent;
  }
}
