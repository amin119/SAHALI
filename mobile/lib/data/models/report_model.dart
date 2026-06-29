import '../../../core/network/api_client.dart';

class ReportModel {
  final String id;
  final String trackingCode;
  final int categoryId;
  final String status;
  final String priority;
  final String title;
  final String? description;
  final String? photoUrl;
  final String? thumbnailUrl;
  final List<String> photoUrls;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final bool isDuplicate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<StatusHistoryItem> history;

  const ReportModel({
    required this.id,
    required this.trackingCode,
    required this.categoryId,
    required this.status,
    required this.priority,
    required this.title,
    this.description,
    this.photoUrl,
    this.thumbnailUrl,
    this.photoUrls = const [],
    this.address,
    this.city,
    this.lat,
    this.lng,
    required this.isDuplicate,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.history = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    final rawUrls = (j['photo_urls'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    // If photo_urls is empty but photo_url exists, synthesize it
    final urls = rawUrls.isNotEmpty
        ? rawUrls
        : (j['photo_url'] as String?) != null
            ? [j['photo_url'] as String]
            : <String>[];
    return ReportModel(
      id: j['id'] as String,
      trackingCode: j['tracking_code'] as String,
      categoryId: j['category_id'] as int,
      status: j['status'] as String,
      priority: j['priority'] as String,
      title: j['title'] as String,
      description: j['description'] as String?,
      photoUrl: j['photo_url'] as String?,
      thumbnailUrl: j['thumbnail_url'] as String?,
      photoUrls: urls,
      address: j['address'] as String?,
      city: j['city'] as String?,
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      isDuplicate: (j['is_duplicate'] as bool?) ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
      updatedAt: DateTime.parse(j['updated_at'] as String),
      resolvedAt: j['resolved_at'] != null
          ? DateTime.parse(j['resolved_at'] as String)
          : null,
      history: (j['history'] as List<dynamic>? ?? [])
          .map((h) => StatusHistoryItem.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Resolve a photo URL for display on the mobile device.
  /// Relative paths (/reports/photo/...) are prefixed with the current backend URL.
  static String resolveUrl(String url) {
    if (url.startsWith('/')) {
      final base = BackendConfig.current; // e.g. https://ngrok.../v1
      return '$base$url';
    }
    return url;
  }

  /// All display-ready photo URLs for this report.
  List<String> get displayPhotoUrls => photoUrls.map(resolveUrl).toList();

  bool get isActive => ['submitted', 'received', 'under_review', 'in_progress']
      .contains(status);
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'rejected';
}

class StatusHistoryItem {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;

  const StatusHistoryItem({
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.createdAt,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> j) =>
      StatusHistoryItem(
        fromStatus: j['from_status'] as String?,
        toStatus: j['to_status'] as String,
        note: j['note'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class ReportListResponse {
  final List<ReportModel> items;
  final int total;
  final int page;
  final int pageSize;

  const ReportListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ReportListResponse.fromJson(Map<String, dynamic> j) =>
      ReportListResponse(
        items: (j['items'] as List<dynamic>)
            .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
        page: j['page'] as int,
        pageSize: j['page_size'] as int,
      );
}
