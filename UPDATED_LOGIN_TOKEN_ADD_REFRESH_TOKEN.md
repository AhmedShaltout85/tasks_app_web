# Implementation Plan: Add Refresh Token Support to Flutter App

## Overview

Update the Flutter `tasks_app` to work with the new refresh token flow on the `tasks-api` backend. The backend now issues a 24-hour access token + 7-day refresh token. The Flutter app must automatically refresh expired access tokens and persist the refresh token across app restarts.

### Decisions
- **Token refresh**: Auto-refresh on 401 (Dio interceptor intercepts 401, calls `/auth/refresh-token`, retries original request)
- **Refresh token storage**: Persisted in SharedPreferences (survives app restart)
- **Sign-out**: Send refresh token to server for revocation in request body
- **Old credential re-login**: Removed entirely (no more stored username/password)
- **Request queuing**: Full queue implementation to handle concurrent requests during refresh

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

### 1. `UserModel` - `lib/models/user_model.dart`

**Changes:**
- Add `final String? refreshToken;` field
- Update constructor to accept `this.refreshToken`
- Update `fromJson` to parse `json['refreshToken']`
- Update `toJson` to include `'refreshToken': refreshToken`
- Update `copyWith` to accept `refreshToken` parameter

---

### 2. `ApiNetworkUserRepos` (abstract) - `lib/newtork_repos/remote_repo/api_repos/api_network_user_repos.dart`

**Changes:**
- Add abstract method: `Future<Map<String, dynamic>> refreshToken({required String refreshToken});`
- Update `signOut` signature: `Future<void> signOut({String? refreshToken});`

---

### 3. `ApiNetworkUserReposImpl` - `lib/newtork_repos/remote_repo/api_repos/api_network_user_repos_impl.dart`

**Changes:**
- Implement `refreshToken()`: POST `/auth/refresh-token` with `{"refreshToken": "..."}` body, return response data
- Update `signOut()`: accept optional `String? refreshToken` parameter, send it in request body if provided

---

### 4. `DioClient` - `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

**Remove:**
- `CredentialsGetter` typedef
- `OnReLoginFailed` typedef
- `_credentialsGetter` field
- Old `_tryRefreshToken()` method (credential-based re-login)

**Add/Change:**
- `String? _refreshToken` field
- `setRefreshToken(String)`, `get refreshToken`, `clearRefreshToken()` methods
- New typedefs: `OnTokensRefreshed` and `OnSessionExpired`
- `OnTokensRefreshed? _onTokensRefreshed` and `OnSessionExpired? _onSessionExpired` fields
- Updated `setCallbacks()` to accept `onTokensRefreshed` and `onSessionExpired`
- Queue mechanism for pending requests during refresh

**Change `onError` interceptor:**
- Check for `statusCode == 401` (not 403)
- Exclude `/auth/signin` and `/auth/refresh-token` paths
- Implement `_handleTokenRefresh()`:
  1. If `_isRefreshing == true` → queue request, await completer
  2. If `_isRefreshing == false` → set flag, call `POST /auth/refresh-token` via `_dioForRefresh`
  3. On success → update `_token` + `_refreshToken`, call `_onTokensRefreshed`, retry original request, complete queued requests
  4. On failure → clear tokens, call `_onSessionExpired`, fail queued requests

---

### 5. `UserProvider` - `lib/controller/user_provider.dart`

**Remove:**
- `getSavedCredentials()` method
- `_saveCredentialsToCache()` method
- `saved_username` / `saved_password` cache keys usage

**Add:**
- `_refreshToken` field and `String? get refreshToken` getter
- `updateTokens(String newAccessToken, String newRefreshToken)` method

**Update:**
- `_loadTokenFromCache()`: also load `refresh_token` from SharedPreferences
- `_saveTokenToCache()`: also save refresh token
- `_clearTokenFromCache()`: also clear `refresh_token`
- `signIn()`: extract `refreshToken` from response, store locally + pass to DioClient
- `signOut()`: pass `_refreshToken` to `_api.signOut(refreshToken: _refreshToken)`, clear refresh token
- `_setupCallbacks()`: replace old callbacks with new `onTokensRefreshed` → `updateTokens`, `onSessionExpired` → `clearUserData`

**Key cache keys:**
- `auth_token` -> access token (existing)
- `refresh_token` -> refresh token (new)
- `current_user` -> user JSON (existing)

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
| 4 | `DioClient` | Add refresh token field, 401 interceptor with auto-refresh logic + queue |
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
