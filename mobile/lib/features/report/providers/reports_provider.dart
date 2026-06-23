import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/category_service.dart';

class ReportsProvider extends ChangeNotifier {
  final _reportService = ReportService();
  final _categoryService = CategoryService();

  List<ReportModel> _reports = [];
  ReportModel? _selectedReport;
  List<CategoryModel> _categories = [];
  bool _loading = false;
  bool _loadingDetail = false;
  String? _error;
  int _total = 0;
  int _page = 1;

  List<ReportModel> get reports => _reports;
  ReportModel? get selectedReport => _selectedReport;
  List<CategoryModel> get categories => _categories;
  bool get loading => _loading;
  bool get loadingDetail => _loadingDetail;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _reports.length < _total;

  CategoryModel? categoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      _categories = await _categoryService.listCategories();
      notifyListeners();
    } catch (_) {
      // categories are optional — ignore failure
    }
  }

  Future<void> loadMyReports({String? statusFilter, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _reports = [];
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await loadCategories();
      final response = await _reportService.listMyReports(
        status: statusFilter,
        page: _page,
        pageSize: 20,
      );
      if (refresh || _page == 1) {
        _reports = response.items;
      } else {
        _reports = [..._reports, ...response.items];
      }
      _total = response.total;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = dioMessage(e);
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage({String? statusFilter}) async {
    if (_loading || !hasMore) return;
    _page++;
    await loadMyReports(statusFilter: statusFilter);
  }

  Future<void> loadReport(String id) async {
    _loadingDetail = true;
    _error = null;
    notifyListeners();
    try {
      await loadCategories();
      _selectedReport = await _reportService.getReport(id);
      _loadingDetail = false;
      notifyListeners();
    } catch (e) {
      _error = dioMessage(e);
      _loadingDetail = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
