import '../models/notification_model.dart';
import '../../core/network/api_client.dart';

class NotificationService {
  final _dio = ApiClient.instance.dio;

  Future<List<NotificationModel>> listNotifications() async {
    final res = await _dio.get('/notifications');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }
}
