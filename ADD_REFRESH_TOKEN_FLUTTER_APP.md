# Plan: Add Refresh Token Support to Flutter App

## Overview

Update the Flutter `tasks_app` to work with the new refresh token flow on the `tasks-api` backend. The backend now issues a 24-hour access token + 7-day refresh token. The Flutter app must automatically refresh expired access tokens and persist the refresh token across app restarts.

### Decisions
- **Token refresh**: Auto-refresh on 401 (Dio interceptor intercepts 401, calls `/auth/refresh-token`, retries original request)
- **Refresh token storage**: Persisted in SharedPreferences (survives app restart)
- **Sign-out**: Send refresh token to server for revocation

---

## Architecture Change

**Current flow:**
```
Login -> Store access token in SharedPreferences -> Use token for all requests -> Token expires (30 days) -> Re-login
```

**New flow:**
```
Login -> Store access token + refresh token in SharedPreferences -> Use access token for requests
  -> If 401 received -> Dio interceptor calls /auth/refresh-token with refresh token
    -> If refresh succeeds -> Update stored tokens -> Retry original request
    -> If refresh fails -> Clear tokens -> Redirect to login
```

---

## Files to Modify (5 files)

### 1. `DioClient` - `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

**Current state:** Singleton Dio client with `_token` field. Interceptors log requests and add Bearer token. `onError` just logs and passes through.

**Changes:**
- Add `_refreshToken` field alongside `_token`
- Add `setRefreshToken(String)` and `get refreshToken` methods
- Add `clearRefreshToken()` method
- Add `_isRefreshing` flag to prevent concurrent refresh calls
- Add a `Queue<_PendingRequest>` to queue requests while refresh is in progress
- In `onError` interceptor: if status code is 401 AND path is NOT `/auth/refresh-token` AND NOT `/auth/signin`:
  1. Pause the failed request
  2. If not already refreshing, call `/auth/refresh-token` with current refresh token
  3. On success: update `_token` and `_refreshToken`, invoke callback to persist, retry original request
  4. On failure: clear tokens, invoke `onSessionExpired` callback
- Add `Function(String newAccessToken, String newRefreshToken)? onTokensRefreshed` callback (set by UserProvider)
- Add `VoidCallback? onSessionExpired` callback (set by UserProvider)

**Key implementation detail:**
```dart
// In onError interceptor
if (error.response?.statusCode == 401 &&
    !_isAuthEndpoint(error.requestOptions.path)) {
  return _handleTokenRefresh(error, handler);
}
```

---

### 2. `UserModel` - `lib/models/user_model.dart`

**Changes:**
- Add `final String? refreshToken;` field
- Update `fromJson` to parse `json['refreshToken']`
- Update `toJson` to include `refreshToken`
- Update `copyWith` to accept `refreshToken`

---

### 3. `UserProvider` - `lib/controller/user_provider.dart`

**Changes:**
- Add `_refreshToken` field and `String? get refreshToken` getter
- Update `_loadTokenFromCache()`: also load `refresh_token` from SharedPreferences
- Update `_saveTokenToCache()`: also save refresh token under key `refresh_token`
- Update `_clearTokenFromCache()`: also clear `refresh_token`
- Update `signIn()`: extract `refreshToken` from response, store it, pass to DioClient
- Update `signOut()`: pass refresh token to API call for revocation, clear refresh token locally
- Add `updateTokens(String newAccessToken, String newRefreshToken)` method: called by DioClient after successful refresh to update state + cache
- In constructor/init: register DioClient callbacks:
  - `onTokensRefreshed`: calls `updateTokens`
  - `onSessionExpired`: calls `clearUserData`

**Key cache keys:**
- `auth_token` -> access token (existing)
- `refresh_token` -> refresh token (new)
- `current_user` -> user JSON (existing)

---

### 4. `ApiNetworkUserRepos` (abstract) - `lib/newtork_repos/remote_repo/api_repos/api_network_user_repos.dart`

**Changes:**
- Add abstract method: `Future<Map<String, dynamic>> refreshToken({required String refreshToken});`
- Update `signOut` signature: `Future<void> signOut({String? refreshToken});`

---

### 5. `ApiNetworkUserReposImpl` - `lib/newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart`

**Changes:**
- Implement `refreshToken()`: POST `/auth/refresh-token` with `{"refreshToken": "..."}` body, return response data
- Update `signOut()`: accept optional `refreshToken` parameter, send it in request body if provided

---

## Files NOT Modified

| File | Reason |
|------|--------|
| `AuthWrapper` | Already checks `userProvider.token` - no change needed |
| `LoginScreen` | Already calls `userProvider.signIn()` - no change needed |
| `main.dart` | No new providers needed |
| `CacheHelper` | Already supports string storage - no change needed |
| `Screens` (all) | No UI changes needed |

---

## Implementation Order

| Step | File | Action |
|------|------|--------|
| 1 | `UserModel` | Add `refreshToken` field, update `fromJson`/`toJson`/`copyWith` |
| 2 | `ApiNetworkUserRepos` | Add `refreshToken()` abstract method, update `signOut` signature |
| 3 | `ApiNetworkUserReposImpl` | Implement `refreshToken()`, update `signOut()` to send refresh token |
| 4 | `DioClient` | Add refresh token field, 401 interceptor with auto-refresh logic |
| 5 | `UserProvider` | Store/load refresh token, register DioClient callbacks, update signIn/signOut |
| 6 | Build & verify | `flutter analyze` |

---

## DioClient 401 Handler - Detailed Logic

```
onError triggered with 401:
  +-- Is path /auth/signin or /auth/refresh-token? -> pass through (don't loop)
  +-- Is _isRefreshing == true? -> queue this request, wait for result
  +-- Is _isRefreshing == false?
       +-- Set _isRefreshing = true
       +-- Save original request
       +-- Call POST /auth/refresh-token with current _refreshToken
       |   +-- Success (200):
       |   |   +-- Extract new accessToken + refreshToken
       |   |   +-- Update _token, _refreshToken
       |   |   +-- Call onTokensRefreshed callback (to persist)
       |   |   +-- Retry original request with new token
       |   |   +-- Complete all queued requests
       |   |   +-- Set _isRefreshing = false
       |   +-- Failure (401/other):
       |       +-- Clear _token, _refreshToken
       |       +-- Call onSessionExpired callback
       |       +-- Fail all queued requests
       |       +-- Set _isRefreshing = false
```

---

## Risk Assessment

- **No breaking UI changes**: All screens continue to work as-is. Refresh is transparent.
- **Concurrent request safety**: Queue mechanism prevents multiple simultaneous refresh calls.
- **Server restart handling**: Refresh tokens are in-memory on server. After server restart, all clients must re-login. The 401 interceptor will catch this and redirect to login.
- **Infinite loop prevention**: `/auth/refresh-token` and `/auth/signin` paths are excluded from 401 handling.
