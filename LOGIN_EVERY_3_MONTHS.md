Good. Now let me present the detailed implementation plan for all 7 enhancements.

Detailed Implementation Plan: All 7 Enhancements
Overview
#	Enhancement	Files	New Files
1	Smart polling interval	dio_client.dart	—
2	Cross-tab synchronization	dio_client.dart, web_helper*	—
3	Pre-emptive refresh	dio_client.dart	—
4	Token status stream	dio_client.dart, user_provider.dart	lib/utils/auth_status.dart
5	Migrate dart:html → package:web	web_helper_web.dart, pubspec.yaml	—
6	Centralized auth state machine	dio_client.dart, user_provider.dart	lib/services/auth_state_manager.dart
7	Max refresh token lifetime (90 days)	user_provider.dart, dio_client.dart	—
Step 1: Add Dependencies & Create New Files
1a. Update pubspec.yaml
Add web: ^1.1.0 (for Enhancement 5):

dependencies:
  ...
  web: ^1.1.0
1b. Create lib/utils/auth_status.dart (Enhancement 4)
enum AuthStatus {
  authenticated,
  refreshing,
  refreshed,
  expiring,         // Token within 5 min of expiry
  expired,          // Session cleared
  transientError,   // Network error, will retry
}
Step 2: Migrate dart:html → package:web (Enhancement 5)
2a. Rewrite lib/utils/web_helper/web_helper_web.dart
import 'dart:async';
import 'package:web/web.dart' as web;

StreamSubscription<void> onWindowFocus(void Function() callback) {
  return web.window.onFocus.listen((_) => callback());
}

StreamSubscription<void> onWindowBlur(void Function() callback) {
  return web.window.onBlur.listen((_) => callback());
}

StreamSubscription<void> onVisibilityChange(void Function(bool visible) callback) {
  return web.document.onVisibilityChange.listen((_) {
    callback(!web.document.hidden);
  });
}
2b. Update lib/utils/web_helper/web_helper_stub.dart
Add stub implementations for onWindowBlur and onVisibilityChange for non-web platforms.

Step 3: Implement Smart Polling (Enhancement 1)
Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart
Replace the fixed 5-minute interval with a dynamic one:

Duration _calculatePollInterval(DateTime expiry) {
  final remaining = expiry.difference(DateTime.now());
  if (remaining.inHours > 6) return const Duration(minutes: 30);
  if (remaining.inHours > 1) return const Duration(minutes: 10);
  if (remaining.inMinutes > 10) return const Duration(minutes: 5);
  if (remaining.inMinutes > 1) return const Duration(minutes: 1);
  return Duration.zero; // refresh now
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
  log('Next poll in ${interval.inMinutes}min (token expires in ${expiryDateTime.difference(DateTime.now()).inMinutes}min)');
  
  _periodicTimer = Timer(interval, () {
    _checkAndRefresh();
    scheduleTokenRefresh(token); // reschedule with new interval
  });
  
  _checkAndRefresh(); // immediate check
}
Step 4: Add Token Status Stream (Enhancement 4)
Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart
Add a broadcast stream and emit events at key points:

final StreamController<AuthStatus> _statusController = StreamController<AuthStatus>.broadcast();
Stream<AuthStatus> get statusStream => _statusController.stream;

void _emitStatus(AuthStatus status) {
  _statusController.add(status);
}

// Emit "refreshing" at start of _proactiveRefresh and _handleTokenRefresh
// Emit "refreshed" on success
// Emit "expiring" when within 5 min of expiry (in _checkAndRefresh)
// Emit "transientError" on network errors
// Emit "expired" on _onSessionExpired
Step 5: Pre-emptive Refresh in onRequest (Enhancement 3)
Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart
onRequest: (options, handler) async {
  if (_token != null && !_isAuthEndpoint(options.path)) {
    final expiry = JwtHelper.extractExpiry(_token!);
    if (expiry != null) {
      final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
      final remaining = expiryDateTime.difference(DateTime.now());
      if (remaining < _refreshBuffer && !_isRefreshing) {
        // Token about to expire — block request, refresh first
        _emitStatus(AuthStatus.refreshing);
        await _proactiveRefresh();
      }
    }
    options.headers['Authorization'] = 'Bearer $_token';
  }
  return handler.next(options);
},
Step 6: Cross-Tab Synchronization (Enhancement 2)
Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart
Add a BroadcastChannel to coordinate refresh across tabs:

// Use dart:html BroadcastChannel or localStorage events
// Only one tab "leads" the refresh
// Other tabs listen for the result and update their tokens

String? _leaderId; // unique tab ID

bool _tryAcquireLeadership() {
  // Use localStorage with timestamp to elect a leader
  // Leader is the tab with the most recent heartbeat
}

void _listenForTokenUpdates() {
  // On message, parse new tokens and call _onTokensRefreshed
}
Note: This is complex. I'll use package:web's BroadcastChannel API.

Step 7: Centralized Auth State Manager (Enhancement 6)
Create lib/services/auth_state_manager.dart
A new class that owns:

Token storage/retrieval (CacheHelper)
Refresh logic (calls DioClient)
Status stream (forwards DioClient status)
Persistence
DioClient becomes a pure HTTP client. UserProvider consumes AuthStateManager.

class AuthStateManager {
  final DioClient _dioClient = DioClient();
  final StreamController<AuthStatus> _statusController = StreamController.broadcast();
  
  // Token storage
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  DateTime? _sessionStartTime;
  static const Duration _maxSessionLifetime = Duration(days: 90);
  
  // Public API
  Stream<AuthStatus> get statusStream => _statusController.stream;
  bool get isAuthenticated => _token != null;
  
  Future<void> initialize() async { /* load from cache */ }
  Future<void> signIn(String username, String password) async { /* ... */ }
  Future<void> signOut() async { /* ... */ }
  Future<void> clearSession() async { /* ... */ }
  Future<bool> refreshTokens() async { /* ... */ }
  bool isSessionExpired() { /* check 90-day limit */ }
}
Refactor lib/controller/user_provider.dart
Delegate token management to AuthStateManager
Keep user data management in UserProvider
Refactor lib/newtork_repos/remote_repo/api_repos/dio_client.dart
Remove token storage (now in AuthStateManager)
Keep only HTTP concerns + interceptor logic
setToken / setRefreshToken calls go through AuthStateManager
Step 8: Max Session Lifetime — 90 Days (Enhancement 7)
Modify lib/services/auth_state_manager.dart
static const Duration _maxSessionLifetime = Duration(days: 90);

bool isSessionExpired() {
  if (_sessionStartTime == null) return true;
  return DateTime.now().difference(_sessionStartTime!) > _maxSessionLifetime;
}

// In signIn: set _sessionStartTime = DateTime.now()
// In refreshTokens: check isSessionExpired() — if true, clear session
// Persist _sessionStartTime to cache
Add cache key: session_start_time (millisecondsSinceEpoch)
Step 9: Wire Status Stream to UI (Enhancement 4)
Modify lib/controller/user_provider.dart
class UserProvider with ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.authenticated;
  AuthStatus get authStatus => _authStatus;
  
  UserProvider() {
    _authStateManager.statusStream.listen((status) {
      _authStatus = status;
      notifyListeners();
    });
  }
}
The UI can now show a subtle indicator:

Consumer<UserProvider>(
  builder: (context, user, _) {
    if (user.authStatus == AuthStatus.refreshing) {
      return RefreshIndicator();
    }
    return MainContent();
  },
)
Verification Plan
After implementation, verify with:

fvm flutter analyze — 0 errors
Smart polling test: Sign in → check console for "Next poll in 30min" → wait 30 min → check for "Next poll in 10min"
Pre-emptive refresh test: Set token to expire in 30s → make API call → should refresh first (no 401)
Cross-tab test: Open 2 tabs → sign in on tab 1 → trigger refresh → tab 2 should also have new tokens
Max lifetime test: Manually set session_start_time to 91 days ago → try to refresh → should clear session
Status stream test: Open app → sign in → trigger refresh → check UI shows "Refreshing..." indicator
File Summary
File	Action
pubspec.yaml	Add web: ^1.1.0
lib/utils/auth_status.dart	NEW — enum
lib/utils/web_helper/web_helper_web.dart	Rewrite with package:web
lib/utils/web_helper/web_helper_stub.dart	Add stub methods
lib/services/auth_state_manager.dart	NEW — centralized auth
lib/newtork_repos/remote_repo/api_repos/dio_client.dart	Smart polling, pre-emptive refresh, cross-tab, status stream
lib/controller/user_provider.dart	Delegate to AuthStateManager, expose status
lib/screens/splash/splash_screen.dart	Initialize AuthStateManager
Risk & Tradeoffs
Concern	Mitigation
Cross-tab sync is complex	Fallback: if BroadcastChannel not available (older browsers), use localStorage events
Centralized state machine is a large refactor	Can be done incrementally — start with smart polling, then add status stream, then refactor
Pre-emptive refresh adds latency	Only triggers when within 60s buffer — only the first request after expiry is affected
90-day max lifetime	Configurable via static const in AuthStateManager — easy to adjust
Ready to implement when you exit plan mode. Should I proceed?
