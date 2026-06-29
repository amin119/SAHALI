import '../models/user_model.dart';
import '../../core/network/api_client.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<void> loginWithPassword(String identifier, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
    await saveTokens(
      res.data['access_token'] as String,
      res.data['refresh_token'] as String,
    );
  }

  Future<void> register({
    required String fullName,
    String? phone,
    String? email,
    required String password,
    String preferredLanguage = 'fr',
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'password': password,
      'preferred_language': preferredLanguage,
    });
    await saveTokens(
      res.data['access_token'] as String,
      res.data['refresh_token'] as String,
    );
  }

  Future<void> requestOtp(String phone) async {
    await _dio.post('/auth/otp/request', data: {'phone': phone});
  }

  Future<void> verifyOtp(String phone, String code) async {
    final res = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
    });
    await saveTokens(
      res.data['access_token'] as String,
      res.data['refresh_token'] as String,
    );
  }

  /// Sends email verification code. Returns debug_code in dev mode.
  Future<String?> sendEmailVerification(String email) async {
    final res = await _dio.post('/auth/verify-email/send', data: {'email': email});
    return res.data['debug_code'] as String?;
  }

  /// Confirms email verification. Returns true on success.
  Future<void> confirmEmailVerification(String email, String code) async {
    await _dio.post('/auth/verify-email/confirm', data: {
      'email': email,
      'code': code,
    });
  }

  /// Sends forgot password code. Returns debug_code in dev mode.
  Future<String?> forgotPassword(String identifier) async {
    final res = await _dio.post('/auth/forgot-password', data: {'identifier': identifier});
    return res.data['debug_code'] as String?;
  }

  /// Resets password with code. Returns true on success.
  Future<void> resetPassword(String identifier, String code, String newPassword) async {
    await _dio.post('/auth/reset-password', data: {
      'identifier': identifier,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await clearTokens();
  }
}
