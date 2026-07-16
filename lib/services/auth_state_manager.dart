
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

  // FIX #3/#4: Hook that DioClient/UserProvider registers so that ANY
  // successful token save (sign-in, resume-refresh via attemptRefresh(),
  // or a manual refresh) gets broadcast to other tabs. Previously the
  // resume path (attemptRefresh -> _saveTokens) never told other tabs
  // about new tokens at all, and DioClient only broadcast when the
  // refreshing tab happened to be the elected "leader" -- so a
  // non-leader tab that refreshed reactively (401) silently desynced
  // every other open tab. Broadcasting is now decoupled from leadership:
  // whoever legitimately refreshes tells everyone.
  void Function(String accessToken, String refreshToken)? onTokensSaved;

  // FIX #4: Hook so an explicit sign-out in this tab notifies other tabs.
  void Function()? onSessionCleared;

  Stream<AuthStatus> get statusStream => _statusController.stream;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  DateTime? get sessionStartTime => _sessionStartTime;
  bool get isInitialized => _isInitialized;

  // FIX #5: treat an empty-string refresh token the same as null.
  // Previously `refreshToken ?? ''` from sign-in meant a backend response
  // missing refreshToken produced _refreshToken == '' (not null), which
  // passed every `_refreshToken == null` guard and caused a doomed
  // network call to /auth/refresh-token with an empty string instead of
  // failing fast.
  bool get isAuthenticated =>
      _token != null && _refreshToken != null && _refreshToken!.isNotEmpty;

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
    if (savedRefresh != null && savedRefresh.isNotEmpty) {
      _refreshToken = savedRefresh;
      _api.setRefreshToken(_refreshToken!);
    }

    final savedExpiry = CacheHelper.getInt(key: _kTokenExpiry);
    if (savedExpiry != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(savedExpiry);
    }

    final savedSessionStart = CacheHelper.getInt(key: _kSessionStartTime);
    if (savedSessionStart != null) {
      _sessionStartTime =
          DateTime.fromMillisecondsSinceEpoch(savedSessionStart);
    }

    // With the fix in setTokensFromSignIn below, savedSessionStart should
    // now always be present after a real sign-in. If it's still missing
    // (e.g. pre-fix cached data from before this patch), give the session
    // the benefit of the doubt for one load instead of nuking it, by
    // seeding sessionStartTime to "now" rather than treating it as expired.
    if (savedSessionStart == null && savedToken.isNotEmpty) {
      log('No cached session_start_time found (pre-fix data); seeding it now');
      _sessionStartTime = DateTime.now();
      await CacheHelper.saveData(
          key: _kSessionStartTime,
          value: _sessionStartTime!.millisecondsSinceEpoch);
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
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return RefreshResult.rejected;
    }
    if (isSessionExpired()) {
      log('Session exceeded max lifetime, refusing to refresh');
      return RefreshResult.rejected;
    }

    // FIX #2/#3 support: remember which refresh token this call used. If by
    // the time this call fails, _refreshToken has already changed (because
    // another tab broadcast a newer pair while this request was in
    // flight), the failure is stale -- don't treat it as a real rejection.
    final tokenUsedForThisCall = _refreshToken;

    try {
      final response = await _api.refreshToken(refreshToken: _refreshToken!);
      final newAccessToken = response['token'] as String?;
      final newRefreshToken = response['refreshToken'] as String?;
      if (newAccessToken == null) return RefreshResult.rejected;

      await _saveTokens(newAccessToken, newRefreshToken);
      return RefreshResult.success;
    } catch (e) {
      log('Refresh attempt failed: $e');
      if (_refreshToken != tokenUsedForThisCall) {
        log('Refresh token was superseded by another tab mid-flight; ignoring stale failure');
        return RefreshResult.success;
      }
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) return RefreshResult.rejected;
      }
      return RefreshResult.transient;
    }
  }

  Future<void> _saveTokens(String accessToken, String? newRefreshToken) async {
    _token = accessToken;
    _api.setToken(accessToken);
    await CacheHelper.saveData(key: _kAuthToken, value: accessToken);

    // FIX #5: only accept a non-empty refresh token.
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
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
    }
    // FIX #1: previously this only persisted _sessionStartTime the first
    // time it was ever set to non-null in this process's lifetime, because
    // setTokensFromSignIn() pre-assigned _sessionStartTime = DateTime.now()
    // BEFORE calling _saveTokens(), so this guard was always false and
    // session_start_time was never written to CacheHelper. That meant
    // every user was logged out on the very next app restart, since
    // isSessionExpired() treats a missing sessionStartTime as expired.
    // Persist unconditionally now -- it's a cheap write and guarantees
    // correctness regardless of call order elsewhere.
    await CacheHelper.saveData(
        key: _kSessionStartTime,
        value: _sessionStartTime!.millisecondsSinceEpoch);

    // FIX #3/#4: notify listeners (DioClient) so other tabs learn about
    // the new tokens regardless of which tab performed the refresh.
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      onTokensSaved?.call(_token!, _refreshToken!);
    }
  }

  // FIX #5: refreshToken is now nullable/optional here, matching the
  // reality that a backend can omit it. Previously the caller passed
  // `refreshToken ?? ''`, which this method then stored as a session
  // with isAuthenticated == true but a useless empty refresh token.
  Future<void> setTokensFromSignIn(
      String accessToken, String? refreshToken) async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    // FIX #1: do NOT pre-assign _sessionStartTime here. Leave it null so
    // that _saveTokens' own "if (_sessionStartTime == null)" branch fires
    // and the value actually gets computed and persisted in one place.
    _sessionStartTime = null;
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

  Future<void> clearSession({bool broadcast = true}) async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _sessionStartTime = null;
    _api.clearToken();
    _api.clearRefreshToken();
    await _clearCache();

    // FIX #4: previously an explicit sign-out never told other open tabs
    // the session ended -- only DioClient's own internal
    // session-expired paths broadcast 'EXPIRED'. A user hitting "Sign
    // out" in one tab left every other tab silently authenticated.
    if (broadcast) {
      onSessionCleared?.call();
    }
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
