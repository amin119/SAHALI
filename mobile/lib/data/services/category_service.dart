import '../models/category_model.dart';
import '../../core/network/api_client.dart';

class CategoryService {
  final _dio = ApiClient.instance.dio;

  /// Optional [lat]/[lng] let the backend exclude categories the citizen's
  /// own municipality has disabled locally, resolving to the nearest
  /// municipality the same way report submission does.
  Future<List<CategoryModel>> listCategories({double? lat, double? lng}) async {
    final res = await _dio.get('/categories', queryParameters: {
      if (lat != null && lng != null) 'lat': lat,
      if (lat != null && lng != null) 'lng': lng,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
