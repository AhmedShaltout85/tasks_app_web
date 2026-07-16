
import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import '../../../services/auth_state_manager.dart';
import '../../../utils/auth_status.dart';
import '../../../utils/jwt_helper.dart';
import '../../../utils/web_helper/web_helper.dart';

typedef OnTokensRefreshed = Future<void> Function(
    String newAccessToken, String newRefreshToken, DateTime? newExpiry);
typedef OnSessionExpired = Future<void> Function();

class DioClient {
  static const String _baseUrl = 'http://41.33.226.211:8099/tasks-api/api';
  static const Duration _refreshBuffer = Duration(seconds: 60);

  static final DioClient instance = DioClient._();
  late final Dio _dio;
  late final Dio _dioForRefresh;
  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;
  Timer? _periodicTimer;
  final Queue<_PendingRequest> _pendingRequests = Queue();
  late final AuthStateManager _authState = AuthStateManager.instance;

  StreamSubscription<void>? _focusSub;
  StreamSubscription<void>? _visibilitySub;
  web.BroadcastChannel? _authChannel;
  web.BroadcastChannel? _leaderChannel;
  bool _isLeader = false;
  String _leaderId = DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  DateTime _lastLeaderPingReceived = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _leaderPingTimer;

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
      onRequest: (options, handler) async {
        log('REQUEST: ${options.method} ${options.path}');
        log('DATA: ${options.data}');
        if (_token != null && !_isAuthEndpoint(options.path)) {
          await _preemptiveRefreshIfNeeded();
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

    _initCrossTabSync();

    // NOTE: FIX #3/#4's hook wiring (AuthStateManager.onTokensSaved /
    // onSessionCleared -> this client's broadcastTokens/broadcastExpired)
    // used to live here, inside the constructor. That caused a circular
    // singleton-construction crash: touching _authState here forces
    // AuthStateManager.instance to build, whose constructor builds
    // ApiNetworkUserReposImpl(), whose constructor calls back into
    // DioClient() -- while THIS constructor's own `static final instance =
    // DioClient._()` assignment is still in progress, which Dart's `late
    // final` semantics reject (LateInitializationError: "Field 'instance'
    // has been assigned during initialization").
    //
    // The wiring now happens in UserProvider._setupCallbacks() instead,
    // which runs after both singletons' fields are already fully built.
    // _authState here goes back to being purely lazy, exactly as in the
    // original pre-patch code, so DioClient's own construction never
    // reaches into AuthStateManager.
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

  // --- Smart Polling ---

  Duration _calculatePollInterval(DateTime expiry) {
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    if (remaining.inHours > 6) return const Duration(minutes: 30);
    if (remaining.inHours > 1) return const Duration(minutes: 10);
    if (remaining.inMinutes > 10) return const Duration(minutes: 5);
    if (remaining.inMinutes > 1) return const Duration(minutes: 1);
    return Duration.zero;
  }

  void scheduleTokenRefresh(String token) {
    _periodicTimer?.cancel();

    final expiry = JwtHelper.extractExpiry(token);
    if (expiry == null) {
      log('No exp claim in token, proactive refresh disabled');
      return;
    }

    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    final interval = _calculatePollInterval(expiryDateTime);
    final remainingMin = expiryDateTime.difference(DateTime.now()).inMinutes;
    log('Token valid for ${remainingMin}min, next poll in ${interval.inMinutes}min');

    if (interval == Duration.zero) {
      // FIX #6: previously this was fire-and-forget with no follow-up
      // scheduling at all. If _checkAndRefresh() bailed early (e.g.
      // because _isRefreshing happened to be true from a concurrent
      // reactive/401 refresh), the polling loop died silently and never
      // rearmed itself. Chain the reschedule after the attempt completes
      // so the loop always continues regardless of outcome.
      _checkAndRefresh().then((_) {
        if (_token != null) {
          scheduleTokenRefresh(_token!);
        }
      });
      return;
    }

    _periodicTimer = Timer(interval, () async {
      // FIX #6: await instead of fire-and-forget, so the reschedule below
      // uses the post-refresh token/state rather than racing it, and so a
      // guard-bailout still results in a clean reschedule.
      await _checkAndRefresh();
      if (_token != null) scheduleTokenRefresh(_token!);
    });
  }

  Future<void> _preemptiveRefreshIfNeeded() async {
    if (_token == null || _isRefreshing) return;
    final expiry = JwtHelper.extractExpiry(_token!);
    if (expiry == null) return;
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    final remaining = expiryDateTime.difference(DateTime.now());
    if (remaining < _refreshBuffer) {
      log('Token in buffer zone, preemptive refresh');
      _authState.emitStatus(AuthStatus.expiring);
      // Preemptive refresh must run regardless of leadership -- it's
      // blocking an outgoing request, so we cannot wait for a leader's
      // broadcast to arrive. _isRefreshing + the stale-failure check in
      // _proactiveRefresh keep this safe even if another tab is also
      // refreshing concurrently.
      await _proactiveRefresh();
    }
  }

  Future<void> _checkAndRefresh() async {
    if (_refreshToken == null || _isRefreshing || _token == null) return;
    if (_authState.isSessionExpired()) {
      log('Session exceeded max lifetime, clearing');
      _token = null;
      _refreshToken = null;
      _periodicTimer?.cancel();
      broadcastExpired();
      await _onSessionExpired?.call();
      return;
    }

    // FIX #2: this is the SCHEDULED/periodic proactive check. Only the
    // elected leader tab performs the actual network refresh here.
    // Non-leader tabs skip and rely on the leader's broadcast (via
    // AuthStateManager.onTokensSaved -> broadcastTokens) to pick up new
    // tokens. This avoids every open tab independently hitting
    // /auth/refresh-token near-simultaneously, which is dangerous if the
    // backend rotates (invalidates) refresh tokens on use. Reactive
    // (401) and preemptive (per-request) refreshes are NOT gated this
    // way, since those must succeed in the tab that actually needs them
    // right now.
    if (!_isLeader) {
      log('Not leader; skipping scheduled refresh, waiting for leader broadcast');
      return;
    }

    final expiry = JwtHelper.extractExpiry(_token!);
    if (expiry == null) return;
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    final remaining = expiryDateTime.difference(DateTime.now());
    if (remaining < _refreshBuffer) {
      log('Periodic check: token in buffer zone, refreshing (leader)');
      _authState.emitStatus(AuthStatus.expiring);
      await _proactiveRefresh();
    }
  }

  Future<void> _proactiveRefresh() async {
    if (_refreshToken == null || _isRefreshing) return;
    if (_authState.isSessionExpired()) {
      log('Session exceeded max lifetime, refusing proactive refresh');
      _token = null;
      _refreshToken = null;
      _periodicTimer?.cancel();
      broadcastExpired();
      await _onSessionExpired?.call();
      return;
    }
    _isRefreshing = true;
    _authState.emitStatus(AuthStatus.refreshing);

    // FIX #2/#3 race guard: remember which refresh token this call is
    // using. If the call fails and by then _refreshToken has already
    // changed underneath us (another tab broadcast fresher tokens while
    // this request was in flight), the failure is stale, not a real
    // rejection -- ignore it instead of nuking a session that is
    // actually still valid.
    final tokenUsedForThisCall = _refreshToken;

    try {
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
      final newExpiry = JwtHelper.extractExpiry(newAccessToken);
      final expiryDateTime = newExpiry != null
          ? DateTime.fromMillisecondsSinceEpoch(newExpiry * 1000)
          : null;
      await _onTokensRefreshed?.call(
          newAccessToken, newRefreshToken, expiryDateTime);
      scheduleTokenRefresh(newAccessToken);
      // FIX #3: broadcast regardless of leadership -- any tab that just
      // legitimately refreshed must tell the others, or they'll be
      // silently left holding a stale/rotated-out refresh token.
      broadcastTokens(newAccessToken, newRefreshToken);
      _authState.emitStatus(AuthStatus.refreshed);
      log('Proactive token refresh successful');
    } on DioException catch (e) {
      log('Proactive refresh failed: ${e.response?.statusCode}');
      if (_refreshToken != tokenUsedForThisCall) {
        log('Refresh token superseded mid-flight by another tab; ignoring stale failure');
        return;
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        log('Refresh token rejected by server, clearing session');
        _token = null;
        _refreshToken = null;
        _periodicTimer?.cancel();
        broadcastExpired();
        await _onSessionExpired?.call();
        return;
      }
      _authState.emitStatus(AuthStatus.transientError);
      log('Transient refresh error, will retry on next periodic check');
    } catch (e) {
      log('Proactive refresh unexpected error: $e');
      _authState.emitStatus(AuthStatus.transientError);
    } finally {
      _isRefreshing = false;
    }
  }

  // --- Reactive Token Refresh ---

  Future<void> _handleTokenRefresh(
      DioException error, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _pendingRequests.add(_PendingRequest(error, handler, completer));
      return completer.future;
    }
    if (_refreshToken == null) {
      log('No refresh token available, session expired');
      await _onSessionExpired?.call();
      return handler.next(error);
    }
    _isRefreshing = true;
    _authState.emitStatus(AuthStatus.refreshing);

    // FIX #2/#3 race guard, same as _proactiveRefresh.
    final tokenUsedForThisCall = _refreshToken;

    try {
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
      final newExpiry = JwtHelper.extractExpiry(newAccessToken);
      final expiryDateTime = newExpiry != null
          ? DateTime.fromMillisecondsSinceEpoch(newExpiry * 1000)
          : null;
      await _onTokensRefreshed?.call(
          newAccessToken, newRefreshToken, expiryDateTime);
      scheduleTokenRefresh(newAccessToken);
      // FIX #3: broadcast regardless of leadership.
      broadcastTokens(newAccessToken, newRefreshToken);
      _authState.emitStatus(AuthStatus.refreshed);

      try {
        error.requestOptions.headers['Authorization'] = 'Bearer $_token';
        final retryResponse = await _dio.fetch(error.requestOptions);
        handler.resolve(retryResponse);
      } on DioException catch (e) {
        handler.next(e);
      }

      final pendingCount = _pendingRequests.length;
      var processedCount = 0;
      while (_pendingRequests.isNotEmpty && processedCount < pendingCount) {
        processedCount++;
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
      final statusCode = e.response?.statusCode;
      log('Token refresh failed: status=$statusCode');

      if (_refreshToken != tokenUsedForThisCall) {
        // FIX #2/#3: another tab already refreshed successfully while
        // this request was in flight. Don't clear the session -- retry
        // the original failed request and any queued ones with the
        // now-current token instead of treating this as a rejection.
        log('Refresh token superseded mid-flight by another tab; retrying with fresher token instead of expiring session');
        try {
          error.requestOptions.headers['Authorization'] = 'Bearer $_token';
          final retryResponse = await _dio.fetch(error.requestOptions);
          handler.resolve(retryResponse);
        } on DioException catch (retryErr) {
          handler.next(retryErr);
        }
        while (_pendingRequests.isNotEmpty) {
          final pending = _pendingRequests.removeFirst();
          try {
            pending.error.requestOptions.headers['Authorization'] =
                'Bearer $_token';
            final response = await _dio.fetch(pending.error.requestOptions);
            pending.handler.resolve(response);
          } on DioException catch (retryErr) {
            pending.handler.next(retryErr);
          }
          pending.completer.complete();
        }
        return;
      }

      if (statusCode == 401 || statusCode == 403) {
        log('Refresh token rejected, clearing session');
        _token = null;
        _refreshToken = null;
        _periodicTimer?.cancel();
        broadcastExpired();
        await _onSessionExpired?.call();
      } else {
        _authState.emitStatus(AuthStatus.transientError);
        log('Transient refresh error, keeping session alive');
      }
      while (_pendingRequests.isNotEmpty) {
        final pending = _pendingRequests.removeFirst();
        pending.handler.next(pending.error);
        pending.completer.complete();
      }
      return handler.next(error);
    } catch (e) {
      log('Token refresh unexpected error: $e');
      _authState.emitStatus(AuthStatus.transientError);
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

  // --- Cross-Tab Sync ---

  void _initCrossTabSync() {
    _focusSub = onWindowFocus(() {
      if (_isLeader) return;
      _checkLeadership();
    });
    _visibilitySub = onVisibilityChange((visible) {
      if (visible && !_isLeader) _checkLeadership();
    });
    _setupChannels();
    _startLeaderElection();
  }

  void _setupChannels() {
    try {
      _authChannel = web.BroadcastChannel('auth_tokens');
      _authChannel!.onmessage = ((JSObject event) {
        try {
          final dataProp = event.getProperty('data'.toJS);
          if (dataProp != null && !dataProp.isNull && !dataProp.isUndefined) {
            final str = (dataProp as JSString).toDart;
            _handleBroadcastMessage(str);
          }
        } catch (e) {
          log('Error handling auth broadcast: $e');
        }
      }).toJS;
    } catch (e) {
      log('Auth BroadcastChannel not available: $e');
    }

    try {
      _leaderChannel = web.BroadcastChannel('auth_leader');
      _leaderChannel!.onmessage = ((JSObject event) {
        try {
          final dataProp = event.getProperty('data'.toJS);
          if (dataProp != null && !dataProp.isNull && !dataProp.isUndefined) {
            final str = (dataProp as JSString).toDart;
            _onLeaderMessage(str);
          }
        } catch (e) {
          log('Error handling leader broadcast: $e');
        }
      }).toJS;
    } catch (e) {
      log('Leader BroadcastChannel not available: $e');
    }
  }

  void _handleBroadcastMessage(String message) {
    // Note: this used to `if (_isLeader) return;` here, meaning the
    // leader tab would ignore token updates broadcast by anyone else.
    // Now that non-leader tabs can also legitimately refresh (reactive
    // 401) and broadcast, the leader must accept newer tokens too, so
    // that its own next scheduled refresh doesn't use a stale/rotated
    // refresh token. We only skip if the incoming token is literally
    // identical to what we already have.
    final parts = message.split('|');
    if (parts.isEmpty) return;

    if (parts[0] == 'TOKENS' && parts.length >= 3) {
      final newAccess = parts[1];
      final newRefresh = parts[2];
      if (newAccess != _token) {
        log('Received new tokens from another tab');
        _token = newAccess;
        _refreshToken = newRefresh;
        _onTokensRefreshed?.call(newAccess, newRefresh, null);
        if (newAccess.isNotEmpty) {
          scheduleTokenRefresh(newAccess);
        }
      }
    } else if (parts[0] == 'EXPIRED') {
      log('Another tab reported session expired/signed out');
      _token = null;
      _refreshToken = null;
      _periodicTimer?.cancel();
      _onSessionExpired?.call();
    }
  }

  void _onLeaderMessage(String message) {
    final parts = message.split('|');
    if (parts.isEmpty) return;

    if (parts[0] == 'LEADER_PING') {
      final remoteId = parts.length > 1 ? parts[1] : '';
      _lastLeaderPingReceived = DateTime.now();

      if (_isLeader && remoteId != _leaderId) {
        if (remoteId.compareTo(_leaderId) < 0) {
          log('Yielding leadership to tab $remoteId (lower ID)');
          _isLeader = false;
          _leaderPingTimer?.cancel();
        }
      }
    }
  }

  // FIX #3: made public and NO LONGER gated on _isLeader. Broadcasting
  // new tokens is safe and necessary from any tab that just performed a
  // legitimate refresh -- gating it to the leader only was the root
  // cause of non-leader reactive refreshes silently desyncing other
  // tabs. Leadership now only controls who runs the *scheduled* proactive
  // poll (see _checkAndRefresh), not who is allowed to broadcast.
  void broadcastTokens(String access, String refresh) {
    if (_authChannel == null) return;
    try {
      _authChannel!.postMessage('TOKENS|$access|$refresh'.toJS);
    } catch (e) {
      log('Failed to broadcast tokens: $e');
    }
  }

  // FIX #3/#4: made public and no longer gated on _isLeader, so that (a)
  // any tab detecting a genuine session rejection can tell the others,
  // and (b) an explicit sign-out (via AuthStateManager.onSessionCleared)
  // can broadcast too.
  void broadcastExpired() {
    if (_authChannel == null) return;
    try {
      _authChannel!.postMessage('EXPIRED'.toJS);
    } catch (e) {
      log('Failed to broadcast expired: $e');
    }
  }

  void _startLeaderElection() {
    if (_leaderChannel == null) return;

    Timer(const Duration(seconds: 10), () {
      if (_isLeader) return;
      if (_lastLeaderPingReceived == DateTime.fromMillisecondsSinceEpoch(0)) {
        log('No existing leader heard after grace period, claiming leadership');
        _claimLeadership();
      }
    });

    Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isLeader &&
          DateTime.now().difference(_lastLeaderPingReceived) >
              const Duration(seconds: 30)) {
        log('No leader ping for 30s, claiming leadership');
        _claimLeadership();
      }
    });
  }

  void _claimLeadership() {
    if (_isLeader) return;
    _isLeader = true;
    log('Tab $_leaderId is now the leader');
    _sendLeaderPing();
    _leaderPingTimer?.cancel();
    _leaderPingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendLeaderPing();
    });
    // A brand-new leader should immediately check whether the current
    // token needs refreshing rather than waiting up to 30 min for the
    // next scheduled poll (relevant right after a leadership handoff).
    if (_token != null) {
      _checkAndRefresh();
    }
  }

  void _sendLeaderPing() {
    if (_leaderChannel == null) return;
    try {
      _leaderChannel!.postMessage('LEADER_PING|$_leaderId'.toJS);
    } catch (e) {
      log('Failed to send leader ping: $e');
    }
  }

  void _checkLeadership() {
    if (_leaderChannel == null || _isLeader) return;
    if (DateTime.now().difference(_lastLeaderPingReceived) >
        const Duration(seconds: 30)) {
      _claimLeadership();
    }
  }

  void cancelTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void dispose() {
    cancelTimer();
    _leaderPingTimer?.cancel();
    _focusSub?.cancel();
    _visibilitySub?.cancel();
    _authChannel?.close();
    _leaderChannel?.close();
  }
}

class _PendingRequest {
  final DioException error;
  final ErrorInterceptorHandler handler;
  final Completer<void> completer;
  _PendingRequest(this.error, this.handler, this.completer);
}
