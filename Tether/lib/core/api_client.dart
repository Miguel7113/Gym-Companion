import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys shared with the Workmanager background isolate.
const String apiAccessTokenKey = 'api_access_token';
const String apiBaseUrlKey = 'api_base_url';

/// On a physical Android device, localhost means the phone itself — not the
/// laptop running NestJS. Use the laptop's local network IP instead.
/// On emulators, 10.0.2.2 maps to the host machine's localhost.
String get _defaultBaseUrl {
  if (Platform.isAndroid) {
    // Physical device: use your laptop's local network IP
    // Change this if your IP changes (run: hostname -I | awk '{print $1}')
    return 'http://192.168.0.107:3000';
  }
  if (Platform.isLinux) {
    return 'http://localhost:3000';
  }
  return 'http://localhost:3000';
}

class ApiClient {
  final Dio _dio;
  String? _accessToken;
  
  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: _defaultBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )) {
    _setupInterceptors();
    _persistBaseUrl();
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
    final baseUrl = prefs.getString(apiBaseUrlKey);
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _dio.options.baseUrl = baseUrl;
    }
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle unauthorized - token refresh or logout
          _accessToken = null;
        }
        return handler.next(error);
      },
    ));
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
  
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
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
