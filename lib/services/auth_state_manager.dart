import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart';
import '../utils/auth_status.dart';
import '../utils/jwt_helper.dart';
import '../controller/local_control/cache_helper.dart';

enum RefreshResult { success, rejected, transient }

class AuthStateManager {
  AuthStateManager._();
  static final AuthStateManager instance = AuthStateManager._();

  static const Duration _maxSessionLifetime = Duration(days: 90);
  static const String _kAuthToken = 'auth_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kTokenExpiry = 'token_expiry';
  static const String _kSessionStartTime = 'session_start_time';

  final ApiNetworkUserReposImpl _api = ApiNetworkUserReposImpl();
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  DateTime? _sessionStartTime;
  bool _isInitialized = false;

  Stream<AuthStatus> get statusStream => _statusController.stream;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  DateTime? get sessionStartTime => _sessionStartTime;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _refreshToken != null;

  void _emitStatus(AuthStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void emitStatus(AuthStatus status) => _emitStatus(status);

  bool isSessionExpired() {
    if (_sessionStartTime == null) return true;
    return DateTime.now().difference(_sessionStartTime!) > _maxSessionLifetime;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadFromCache();
    _isInitialized = true;
    log('AuthStateManager initialized: authenticated=$isAuthenticated');
  }

  Future<void> _loadFromCache() async {
    final savedToken = CacheHelper.getString(key: _kAuthToken);
    if (savedToken == null) {
      log('No cached auth token');
      return;
    }

    if (JwtHelper.extractExpiry(savedToken) == null) {
      log('Cached token malformed, clearing');
      await clearSession();
      return;
    }

    _token = savedToken;
    _api.setToken(_token!);

    final savedRefresh = CacheHelper.getString(key: _kRefreshToken);
    if (savedRefresh != null) {
      _refreshToken = savedRefresh;
      _api.setRefreshToken(_refreshToken!);
    }

    final savedExpiry = CacheHelper.getInt(key: _kTokenExpiry);
    if (savedExpiry != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry);
    }

    final savedSessionStart = CacheHelper.getInt(key: _kSessionStartTime);
    if (savedSessionStart != null) {
      _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(savedSessionStart);
    }

    if (isSessionExpired()) {
      log('Session exceeded max lifetime (${_maxSessionLifetime.inDays} days), clearing');
      await clearSession();
      return;
    }

    if (_tokenExpiry != null && _tokenExpiry!.isBefore(DateTime.now())) {
      log('Token expired, attempting refresh on startup');
      final result = await attemptRefresh();
      if (result == RefreshResult.success) {
        log('Startup refresh successful');
      } else if (result == RefreshResult.rejected) {
        log('Startup refresh rejected, clearing session');
        await clearSession();
      } else {
        log('Startup refresh transient, keeping session');
      }
    }
  }

  Future<RefreshResult> attemptRefresh() async {
    if (_refreshToken == null) return RefreshResult.rejected;
    if (isSessionExpired()) {
      log('Session exceeded max lifetime, refusing to refresh');
      return RefreshResult.rejected;
    }
    try {
      final response = await _api.refreshToken(refreshToken: _refreshToken!);
      final newAccessToken = response['token'] as String?;
      final newRefreshToken = response['refreshToken'] as String?;
      if (newAccessToken == null) return RefreshResult.rejected;

      await _saveTokens(newAccessToken, newRefreshToken);
      return RefreshResult.success;
    } catch (e) {
      log('Refresh attempt failed: $e');
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) return RefreshResult.rejected;
      }
      return RefreshResult.transient;
    }
  }

  Future<void> _saveTokens(
      String accessToken, String? newRefreshToken) async {
    _token = accessToken;
    _api.setToken(accessToken);
    await CacheHelper.saveData(key: _kAuthToken, value: accessToken);

    if (newRefreshToken != null) {
      _refreshToken = newRefreshToken;
      _api.setRefreshToken(newRefreshToken);
      await CacheHelper.saveData(key: _kRefreshToken, value: newRefreshToken);
    }

    final exp = JwtHelper.extractExpiry(accessToken);
    if (exp != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      await CacheHelper.saveData(
          key: _kTokenExpiry, value: _tokenExpiry!.millisecondsSinceEpoch);
    }

    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      await CacheHelper.saveData(
          key: _kSessionStartTime,
          value: _sessionStartTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> setTokensFromSignIn(String accessToken, String refreshToken) async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _sessionStartTime = DateTime.now();
    await _saveTokens(accessToken, refreshToken);
  }

  Future<void> notifyTokenRefreshed(
      String accessToken, String refreshToken, DateTime? expiry) async {
    await _saveTokens(accessToken, refreshToken);
    _emitStatus(AuthStatus.refreshed);
  }

  Future<void> notifySessionExpired() async {
    _emitStatus(AuthStatus.expired);
    await clearSession();
  }

  Future<void> notifyTransientError() async {
    _emitStatus(AuthStatus.transientError);
  }

  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _sessionStartTime = null;
    _api.clearToken();
    _api.clearRefreshToken();
    await _clearCache();
  }

  Future<void> _clearCache() async {
    await CacheHelper.removeData(key: _kAuthToken);
    await CacheHelper.removeData(key: _kRefreshToken);
    await CacheHelper.removeData(key: _kTokenExpiry);
    await CacheHelper.removeData(key: _kSessionStartTime);
  }

  void dispose() {
    _statusController.close();
  }
}
