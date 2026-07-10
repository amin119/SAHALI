import 'dart:io';
import 'package:dio/dio.dart';
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
    List<String> photoUrls = const [],
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
      'photo_urls': photoUrls,
    });
    return ReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  static const _contentTypeByExt = {
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    '3gp': 'video/3gpp',
  };

  /// Uploads any single media file (photo, video, or voice note) and
  /// returns its URL. The backend's `/reports/photo` endpoint is a fully
  /// generic byte-blob store despite the name — reused for every media
  /// type rather than adding separate upload endpoints.
  Future<String> uploadFile(File file) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    final ext = filename.split('.').last.toLowerCase();
    final contentType = _contentTypeByExt[ext] ?? 'application/octet-stream';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    final res = await _dio.post(
      '/reports/photo',
      data: formData,
      options: Options(sendTimeout: const Duration(seconds: 60)),
    );
    return res.data['photo_url'] as String;
  }

  Future<ReportModel> updateStatus(String id, String status, {String? note}) async {
    final res = await _dio.patch('/reports/$id/status', data: {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return ReportModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createResolutionReport(
    String id, {
    required String comment,
    String? materials,
    List<String> photoUrls = const [],
    String? videoUrl,
    String? voiceNoteUrl,
  }) async {
    await _dio.post('/reports/$id/resolution-report', data: {
      'comment': comment,
      if (materials != null && materials.isNotEmpty) 'materials': materials,
      'photo_urls': photoUrls,
      if (videoUrl != null) 'video_url': videoUrl,
      if (voiceNoteUrl != null) 'voice_note_url': voiceNoteUrl,
    });
  }

  Future<List<StatusHistoryItem>> getHistory(String id) async {
    final res = await _dio.get('/reports/$id/history');
    return (res.data as List<dynamic>)
        .map((h) => StatusHistoryItem.fromJson(h as Map<String, dynamic>))
        .toList();
  }
}
