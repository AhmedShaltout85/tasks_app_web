import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:dio/dio.dart';

typedef OnTokensRefreshed = Future<void> Function(
    String newAccessToken, String newRefreshToken);
typedef OnSessionExpired = void Function();

class DioClient {
  // static const String _baseUrl = 'http://localhost:9999/tasks-api/api'; //LOCALHOST(LOCAL_SERVER)
  // static const String _baseUrl = 'http://172.18.0.101:9999/tasks-api/api'; //LOCALHOST(ONLINE_SERVER)
  static const String _baseUrl =
      'http://41.33.226.211:8099/tasks-api/api'; //PUBLIC_SERVER(PUBLIC_ONLINE_SERVER)
  static final DioClient instance = DioClient._();
  late final Dio _dio;
  late final Dio _dioForRefresh;
  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;
  final Queue<_PendingRequest> _pendingRequests = Queue();

  OnTokensRefreshed? _onTokensRefreshed;
  OnSessionExpired? _onSessionExpired;

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
        if (_token != null && !_isAuthEndpoint(options.path)) {
          options.headers['Authorization'] = 'Bearer $_token';
          log('TOKEN ADDED: Bearer $_token');
        } else if (_isAuthEndpoint(options.path)) {
          log('SKIPPING TOKEN for auth endpoint: ${options.path}');
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

        if ((statusCode == 401 || statusCode == 403) &&
            !_isAuthEndpoint(path)) {
          return _handleTokenRefresh(error, handler);
        }
        return handler.next(error);
      },
    ));
  }

  factory DioClient() => instance;

  Dio get dio => _dio;

  Dio get dioForRefresh => _dioForRefresh;

  void setCallbacks({
    required OnTokensRefreshed onTokensRefreshed,
    required OnSessionExpired onSessionExpired,
  }) {
    _onTokensRefreshed = onTokensRefreshed;
    _onSessionExpired = onSessionExpired;
  }

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;

  String? get token => _token;

  void setRefreshToken(String refreshToken) => _refreshToken = refreshToken;

  void clearRefreshToken() => _refreshToken = null;

  String? get refreshToken => _refreshToken;

  bool _isAuthEndpoint(String path) {
    return path == '/auth/signin' || path == '/auth/refresh-token';
  }

  Future<void> _handleTokenRefresh(
      DioException error, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _pendingRequests.add(_PendingRequest(error, handler, completer));
      return completer.future;
    }

    if (_refreshToken == null) {
      _onSessionExpired?.call();
      return handler.next(error);
    }

    _isRefreshing = true;
    try {
      log('Access token expired, attempting refresh...');
      final response = await _dioForRefresh.post('/auth/refresh-token', data: {
        'refreshToken': _refreshToken,
      });

      final data = response.data;
      final newAccessToken = data['token'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Invalid refresh response: missing tokens');
      }

      _token = newAccessToken;
      _refreshToken = newRefreshToken;
      log('Token refresh successful');

      _onTokensRefreshed?.call(newAccessToken, newRefreshToken);

      // Retry the original failed request
      try {
        error.requestOptions.headers['Authorization'] = 'Bearer $_token';
        final retryResponse = await _dio.fetch(error.requestOptions);
        handler.resolve(retryResponse);
      } on DioException catch (e) {
        handler.next(e);
      }

      // Complete all queued requests
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        try {
          pending.error.requestOptions.headers['Authorization'] =
              'Bearer $_token';
          final response = await _dio.fetch(pending.error.requestOptions);
          pending.handler.resolve(response);
        } on DioException catch (e) {
          pending.handler.next(e);
        }
        pending.completer.complete();
      }
    } on DioException catch (e) {
      log('Token refresh failed: ${e.response?.statusCode} ${e.response?.data}');
      _token = null;
      _refreshToken = null;
      _onSessionExpired?.call();

      // Fail all queued requests
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        pending.handler.next(pending.error);
        pending.completer.complete();
      }
      return handler.next(error);
    } catch (e) {
      log('Token refresh failed: $e');
      _token = null;
      _refreshToken = null;
      _onSessionExpired?.call();

      // Fail all queued requests
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        pending.handler.next(pending.error);
        pending.completer.complete();
      }
      return handler.next(error);
    } finally {
      _isRefreshing = false;
    }
  }
}

class _PendingRequest {
  final DioException error;
  final ErrorInterceptorHandler handler;
  final Completer<void> completer;

  _PendingRequest(this.error, this.handler, this.completer);
}
