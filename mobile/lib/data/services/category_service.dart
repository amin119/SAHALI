import '../models/category_model.dart';
import '../../core/network/api_client.dart';

class CategoryService {
  final _dio = ApiClient.instance.dio;

  Future<List<CategoryModel>> listCategories() async {
    final res = await _dio.get('/categories');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
