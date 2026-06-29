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
    _set(loading: true, error: null);
    try {
      await _service.loginWithPassword(identifier, password);
      _user = await _service.getMe();
      _set(loading: false);
      return true;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
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
    _set(loading: true, error: null);
    try {
      await _service.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        preferredLanguage: preferredLanguage,
      );
      _user = await _service.getMe();
      _set(loading: false);
      return true;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
      return false;
    }
  }

  Future<void> requestOtp(String phone) async {
    await _service.requestOtp(phone);
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _set(loading: true, error: null);
    try {
      await _service.verifyOtp(phone, code);
      _user = await _service.getMe();
      _set(loading: false);
      return true;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
      return false;
    }
  }

  /// Returns debug_code in dev mode (non-null), null in production.
  Future<String?> sendEmailVerification(String email) async {
    _set(loading: true, error: null);
    try {
      final code = await _service.sendEmailVerification(email);
      _set(loading: false);
      return code;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
      return null;
    }
  }

  Future<bool> confirmEmailVerification(String email, String code) async {
    _set(loading: true, error: null);
    try {
      await _service.confirmEmailVerification(email, code);
      _set(loading: false);
      return true;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
      return false;
    }
  }

  /// Returns debug_code in dev mode. Always returns a non-error response
  /// even if the account doesn't exist (security: no user enumeration).
  Future<String?> forgotPassword(String identifier) async {
    _set(loading: true, error: null);
    try {
      final code = await _service.forgotPassword(identifier);
      _set(loading: false);
      return code;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
      return null;
    }
  }

  Future<bool> resetPassword(String identifier, String code, String newPassword) async {
    _set(loading: true, error: null);
    try {
      await _service.resetPassword(identifier, code, newPassword);
      _set(loading: false);
      return true;
    } catch (e) {
      _set(loading: false, error: dioMessage(e));
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

  void _set({bool? loading, String? error}) {
    if (loading != null) _loading = loading;
    if (error != null) _error = error;
    if (loading == false && error == null) _error = null;
    notifyListeners();
  }
}
