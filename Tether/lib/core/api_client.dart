import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keys shared with the Workmanager background isolate.
const String apiAccessTokenKey = 'api_access_token';
const String apiBaseUrlKey = 'api_base_url';

/// On a physical Android device, localhost means the phone itself — not the
/// laptop running NestJS. Use the laptop's local network IP instead.
/// On emulators, 10.0.2.2 maps to the host machine's localhost.
const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

String get _defaultBaseUrl {
  if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
  if (kReleaseMode) {
    throw StateError(
      'API_BASE_URL is not set. Build release apps with '
      '--dart-define=API_BASE_URL=https://your-api-host',
    );
  }
  if (Platform.isAndroid) {
    debugPrint(
      '[ApiClient] API_BASE_URL not set — using http://10.0.2.2:3001 '
      '(Android emulator only). Physical phones cannot reach 10.0.2.2; '
      'restart with:\n'
      '  flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3001\n'
      'Example: http://192.168.0.107:3001',
    );
    return 'http://10.0.2.2:3001';
  }
  return 'http://localhost:3001';
}

class ApiClient {
  final Dio _dio;
  String? _accessToken;

  /// Default timeouts for most routes.
  static const defaultConnectTimeout = Duration(seconds: 15);
  static const defaultReceiveTimeout = Duration(seconds: 30);

  /// Feed/share and workout sync can be slow on a dev laptop + remote DB.
  static const socialConnectTimeout = Duration(seconds: 20);
  static const socialReceiveTimeout = Duration(seconds: 45);

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _defaultBaseUrl,
          connectTimeout: defaultConnectTimeout,
          receiveTimeout: defaultReceiveTimeout,
        ),
      ) {
    _setupInterceptors();
    _persistBaseUrl();
    // Restore any persisted token immediately; Supabase session takes
    // precedence once the user is signed in.
    loadPersistedAuth();
  }

  /// Restores token and base URL for background sync (no Riverpod).
  static Future<ApiClient> createForBackground() async {
    final client = ApiClient();
    await client.loadPersistedAuth();
    return client;
  }

  Future<void> _persistBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiBaseUrlKey, _dio.options.baseUrl);
  }

  Future<void> loadPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(apiAccessTokenKey);
    // Compile-time API_BASE_URL always wins over a stale SharedPreferences value
    // (e.g. a previous run that pointed at the wrong host/port).
    if (_configuredBaseUrl.isNotEmpty) {
      _dio.options.baseUrl = _configuredBaseUrl;
      await prefs.setString(apiBaseUrlKey, _configuredBaseUrl);
      return;
    }
    final baseUrl = prefs.getString(apiBaseUrlKey);
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
  }

  void _applyTimeouts(RequestOptions options) {
    final path = options.path;
    final isSlowRoute = path.startsWith('/social') ||
        path.startsWith('/workouts/sessions') ||
        path.startsWith('/workouts/sets');
    options
      ..connectTimeout =
          isSlowRoute ? socialConnectTimeout : defaultConnectTimeout
      ..receiveTimeout =
          isSlowRoute ? socialReceiveTimeout : defaultReceiveTimeout;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _applyTimeouts(options);
          await _attachAuthHeader(options);
          if (options.path.startsWith('/social')) {
            debugPrint('[ApiClient] ${options.method} ${options.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.requestOptions.path.startsWith('/social')) {
            debugPrint(
              '[ApiClient] ${response.statusCode} ${response.requestOptions.path}',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.requestOptions.path.startsWith('/social')) {
            debugPrint(
              '[ApiClient] social request failed '
              '${error.response?.statusCode ?? 'network'} '
              '${error.requestOptions.path}: ${error.message}',
            );
          }

          final statusCode = error.response?.statusCode;
          final alreadyRetried =
              error.requestOptions.extra['_authRetried'] == true;

          if (statusCode == 401 && !alreadyRetried) {
            final refreshed = await _refreshSupabaseSession();
            if (refreshed) {
              error.requestOptions.extra['_authRetried'] = true;
              await _attachAuthHeader(error.requestOptions);
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (retryError) {
                if (retryError is DioException) {
                  return handler.next(retryError);
                }
                return handler.next(error);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Prefer the live Supabase session token — it auto-refreshes in the SDK.
  /// Safe in background isolates where Supabase may not be initialized.
  Future<void> _attachAuthHeader(RequestOptions options) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _accessToken = session.accessToken;
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        return;
      }
    } catch (_) {
      // Background isolate / pre-init — fall through to persisted token.
    }
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  Future<bool> _refreshSupabaseSession() async {
    try {
      final result = await Supabase.instance.client.auth.refreshSession();
      final session = result.session;
      if (session == null) return false;
      await setAccessToken(session.accessToken);
      debugPrint('[ApiClient] refreshed Supabase access token');
      return true;
    } catch (e) {
      debugPrint('[ApiClient] Supabase refresh failed: $e');
      return false;
    }
  }

  /// Ensures the persisted API token matches Supabase before critical calls.
  Future<void> ensureFreshToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await setAccessToken(session.accessToken);
        return;
      }
      await _refreshSupabaseSession();
    } catch (e) {
      debugPrint('[ApiClient] ensureFreshToken skipped: $e');
    }
  }

  Future<void> setBaseUrl(String url) async {
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiBaseUrlKey, url);
  }

  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiAccessTokenKey, token);
  }

  Future<void> clearAccessToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(apiAccessTokenKey);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Dio get dio => _dio;
}
