import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../utils/jwt_helper.dart';

typedef OnTokensRefreshed = Future<void> Function(
    String newAccessToken, String newRefreshToken, DateTime? newExpiry);
typedef OnSessionExpired = Future<void> Function();

class DioClient {
  // static const String _baseUrl = 'http://localhost:9999/tasks-api/api'; //LOCALHOST(LOCAL_SERVER)
  // static const String _baseUrl = 'http://172.18.0.101:9999/tasks-api/api'; //LOCALHOST(ONLINE_SERVER)
  static const String _baseUrl =
      'http://41.33.226.211:8099/tasks-api/api'; //PUBLIC_SERVER(PUBLIC_ONLINE_SERVER)
  static const Duration _refreshBuffer = Duration(seconds: 60);
  static const int _maxRefreshRetries = 3;

  static final DioClient instance = DioClient._();
  late final Dio _dio;
  late final Dio _dioForRefresh;
  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;
  int _refreshRetryCount = 0;
  Timer? _refreshTimer;
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

  // --- Proactive Token Refresh ---

  void scheduleTokenRefresh(String token) {
    _refreshTimer?.cancel();
    final expiry = JwtHelper.extractExpiry(token);
    if (expiry == null) {
      log('No exp claim in token, proactive refresh disabled');
      return;
    }

    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    final refreshAt = expiryDateTime.subtract(_refreshBuffer);
    final delay = refreshAt.difference(DateTime.now());

    if (delay.isNegative) {
      log('Token already expired or about to expire, refreshing immediately');
      _proactiveRefresh();
      return;
    }

    log('Scheduling proactive token refresh in ${delay.inSeconds}s (at $refreshAt)');
    _refreshTimer = Timer(delay, _proactiveRefresh);
  }

  Future<void> _proactiveRefresh() async {
    if (_refreshToken == null || _isRefreshing) return;

    _isRefreshing = true;
    try {
      log('Proactive token refresh triggered');
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
      _refreshRetryCount = 0;

      final newExpiry = JwtHelper.extractExpiry(newAccessToken);
      final expiryDateTime = newExpiry != null
          ? DateTime.fromMillisecondsSinceEpoch(newExpiry * 1000)
          : null;

      await _onTokensRefreshed?.call(
          newAccessToken, newRefreshToken, expiryDateTime);
      scheduleTokenRefresh(newAccessToken);
      log('Proactive token refresh successful');
    } catch (e) {
      log('Proactive refresh failed: $e');
      _refreshRetryCount++;
      if (_refreshRetryCount >= _maxRefreshRetries) {
        log('Max proactive refresh retries exceeded, clearing tokens');
        _token = null;
        _refreshToken = null;
        _refreshRetryCount = 0;
        await _onSessionExpired?.call();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // --- Reactive Token Refresh (401/403 handler) ---

  Future<void> _handleTokenRefresh(
      DioException error, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _pendingRequests.add(_PendingRequest(error, handler, completer));
      return completer.future;
    }

    if (_refreshToken == null) {
      await _onSessionExpired?.call();
      return handler.next(error);
    }

    if (_refreshRetryCount >= _maxRefreshRetries) {
      log('Max refresh retries ($_maxRefreshRetries) exceeded');
      _token = null;
      _refreshToken = null;
      _refreshRetryCount = 0;
      await _onSessionExpired?.call();

      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        pending.handler.next(pending.error);
        pending.completer.complete();
      }
      return handler.next(error);
    }

    _isRefreshing = true;
    _refreshRetryCount++;
    try {
      log('Access token expired, attempting refresh... (attempt $_refreshRetryCount/$_maxRefreshRetries)');
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
      _refreshRetryCount = 0;
      log('Token refresh successful');

      final newExpiry = JwtHelper.extractExpiry(newAccessToken);
      final expiryDateTime = newExpiry != null
          ? DateTime.fromMillisecondsSinceEpoch(newExpiry * 1000)
          : null;

      await _onTokensRefreshed?.call(
          newAccessToken, newRefreshToken, expiryDateTime);
      scheduleTokenRefresh(newAccessToken);

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
      log('Token refresh failed - DioException: status=${e.response?.statusCode}, data=${e.response?.data}');
      _token = null;
      _refreshToken = null;
      await _onSessionExpired?.call();

      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        pending.handler.next(pending.error);
        pending.completer.complete();
      }
      return handler.next(error);
    } catch (e) {
      log('Token refresh failed - Unexpected error: $e');
      _token = null;
      _refreshToken = null;
      await _onSessionExpired?.call();

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

  void dispose() {
    _refreshTimer?.cancel();
  }
}

class _PendingRequest {
  final DioException error;
  final ErrorInterceptorHandler handler;
  final Completer<void> completer;

  _PendingRequest(this.error, this.handler, this.completer);
}
