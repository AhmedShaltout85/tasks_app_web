import 'package:dio/dio.dart';
import 'dart:developer';

typedef CredentialsGetter = Future<Map<String, String>?> Function();
typedef OnTokenRefreshed = Future<void> Function(
    String token, Map<String, dynamic> userData);
typedef OnReLoginFailed = void Function();

class DioClient {
  // static const String _baseUrl = 'http://localhost:9999/tasks-api/api'; //LOCALHOST(LOCAL_SERVER)
  // static const String _baseUrl = 'http://172.18.0.101:9999/tasks-api/api'; //LOCALHOST(ONLINE_SERVER)
  static const String _baseUrl =
      'http://41.33.226.211:8099/tasks-api/api'; //PUBLIC_SERVER(PUBLIC_ONLINE_SERVER)
  static final DioClient instance = DioClient._();
  late final Dio _dio;
  late final Dio _dioForRefresh;
  String? _token;
  bool _isRefreshing = false;

  CredentialsGetter? _credentialsGetter;
  OnTokenRefreshed? _onTokenRefreshed;
  OnReLoginFailed? _onReLoginFailed;

  DioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dioForRefresh = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        log('REQUEST: ${options.method} ${options.path}');
        log('DATA: ${options.data}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
          log('TOKEN ADDED: Bearer $_token');
        } else {
          log('NO TOKEN - Request may be unauthorized');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final path = error.requestOptions.path;
        log('ERROR: $statusCode $path');
        log('ERROR DATA: ${error.response?.data}');

        if (statusCode == 403 && path != '/auth/signin' && !_isRefreshing) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              error.requestOptions.headers['Authorization'] = 'Bearer $_token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  factory DioClient() => instance;

  Dio get dio => _dio;

  void setCallbacks({
    required CredentialsGetter credentialsGetter,
    required OnTokenRefreshed onTokenRefreshed,
    required OnReLoginFailed onReLoginFailed,
  }) {
    _credentialsGetter = credentialsGetter;
    _onTokenRefreshed = onTokenRefreshed;
    _onReLoginFailed = onReLoginFailed;
  }

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;

  String? get token => _token;

  Future<bool> _tryRefreshToken() async {
    if (_credentialsGetter == null) return false;

    _isRefreshing = true;
    try {
      final credentials = await _credentialsGetter!();
      if (credentials == null) {
        log('No saved credentials for auto re-login');
        _onReLoginFailed?.call();
        return false;
      }

      log('Token expired, attempting auto re-login...');
      final response = await _dioForRefresh.post('/auth/signin', data: {
        'username': credentials['username'],
        'password': credentials['password'],
      });

      final newToken = response.data['token'];
      if (newToken != null) {
        _token = newToken;
        log('Auto re-login successful');
        _onTokenRefreshed?.call(newToken, response.data);
        return true;
      }

      log('Auto re-login failed: no token in response');
      _onReLoginFailed?.call();
      return false;
    } on DioException catch (e) {
      log('Auto re-login failed: ${e.response?.statusCode} ${e.response?.data}');
      _onReLoginFailed?.call();
      return false;
    } catch (e) {
      log('Auto re-login failed: $e');
      _onReLoginFailed?.call();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
