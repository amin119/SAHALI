import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── BACKEND URL ──────────────────────────────────────────────────────────────
// • Android emulator  → http://10.0.2.2:8000/v1   (default, maps to host)
// • Physical device   → set URL at runtime via Profile → Server URL
//   e.g. https://abc123.ngrok-free.app/v1  (ngrok)
//        http://192.168.X.X:8000/v1        (same-WiFi)
// ─────────────────────────────────────────────────────────────────────────────
const String _kDefaultBackendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8000/v1',
);

// Mutable at runtime — updated by BackendConfig.setUrl()
String _runtimeBackendUrl = _kDefaultBackendUrl;

String get _baseUrl => _runtimeBackendUrl;

/// Manages the backend URL at runtime (stored in SharedPreferences).
class BackendConfig {
  static const String _key = 'sahali_backend_url';

  /// Load stored URL before runApp(). No-op if nothing stored.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      _runtimeBackendUrl = stored;
    }
  }

  /// Persist a new URL and immediately update the live Dio instance.
  static Future<void> setUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), '');
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    _runtimeBackendUrl = trimmed;
    ApiClient.instance.dio.options.baseUrl = trimmed;
  }

  /// Reset to the compile-time default.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _runtimeBackendUrl = _kDefaultBackendUrl;
    ApiClient.instance.dio.options.baseUrl = _kDefaultBackendUrl;
  }

  static String get current => _runtimeBackendUrl;
  static String get defaultUrl => _kDefaultBackendUrl;
}

const _storage = FlutterSecureStorage();

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': '1', // skip ngrok interstitial page
      },
    ));
    d.interceptors.add(_AuthInterceptor(d));
    return d;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_refreshing) {
      _refreshing = true;
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          await _clearTokens();
          return handler.next(err);
        }
        final res = await _dio.post('/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: Options(headers: {'Authorization': null}));
        final newAccess = res.data['access_token'] as String;
        final newRefresh = res.data['refresh_token'] as String;
        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);

        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retry = await _dio.fetch(err.requestOptions);
        return handler.resolve(retry);
      } catch (_) {
        await _clearTokens();
        return handler.next(err);
      } finally {
        _refreshing = false;
      }
    }
    handler.next(err);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

/// Persists tokens after a successful login/register
Future<void> saveTokens(String access, String refresh) async {
  await _storage.write(key: 'access_token', value: access);
  await _storage.write(key: 'refresh_token', value: refresh);
}

Future<void> clearTokens() async {
  await _storage.delete(key: 'access_token');
  await _storage.delete(key: 'refresh_token');
}

Future<bool> hasToken() async {
  final t = await _storage.read(key: 'access_token');
  return t != null;
}

/// Wraps DioException to a clean error message
String dioMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }
    return 'Erreur réseau (${e.response?.statusCode ?? 'timeout'})';
  }
  return e.toString();
}
