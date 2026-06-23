import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  /// Check stored token and load user. Returns true if already authenticated.
  Future<bool> tryAutoLogin() async {
    if (!await hasToken()) return false;
    try {
      _user = await _service.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Future<bool> loginWithPassword(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.loginWithPassword(identifier, password);
      _user = await _service.getMe();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = dioMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    String? phone,
    String? email,
    required String password,
    String preferredLanguage = 'fr',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        preferredLanguage: preferredLanguage,
      );
      _user = await _service.getMe();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = dioMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> requestOtp(String phone) async {
    await _service.requestOtp(phone);
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.verifyOtp(phone, code);
      _user = await _service.getMe();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = dioMessage(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
