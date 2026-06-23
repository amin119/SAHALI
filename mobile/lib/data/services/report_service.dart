import '../models/report_model.dart';
import '../../core/network/api_client.dart';

class ReportService {
  final _dio = ApiClient.instance.dio;

  Future<ReportListResponse> listMyReports({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get('/reports', queryParameters: {
      'page': page,
      'page_size': pageSize,
      if (status != null) 'status': status,
    });
    return ReportListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ReportModel> getReport(String id) async {
    final res = await _dio.get('/reports/$id');
    return ReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ReportModel> submitReport({
    required int categoryId,
    required String title,
    String? description,
    required double lat,
    required double lng,
    String? address,
    String? city,
    String? photoUrl,
    String? thumbnailUrl,
  }) async {
    final res = await _dio.post('/reports', data: {
      'category_id': categoryId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'lat': lat,
      'lng': lng,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    });
    return ReportModel.fromJson(res.data as Map<String, dynamic>);
  }
}
