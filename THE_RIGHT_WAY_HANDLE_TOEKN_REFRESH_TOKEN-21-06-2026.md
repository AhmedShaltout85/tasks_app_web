# The Right Way to Handle Token & Refresh Token

**Date:** 21-06-2026
**Project:** tasks_app (Flutter)
**Scope:** Issues #3, #4, #5, #6 — Proactive Refresh, Token Cleanup, Expiry Tracking, Retry Limit

---

## Table of Contents

1. [Current Architecture](#current-architecture)
2. [Issues Identified](#issues-identified)
3. [Solution Design](#solution-design)
4. [Implementation Details](#implementation-details)
5. [File Change Summary](#file-change-summary)
6. [Edge Cases](#edge-cases)
7. [Testing Checklist](#testing-checklist)

---

## Current Architecture

### Token Flow (Before Changes)

```
Login → POST /auth/signin → { token, refreshToken, ...user }
  ↓
Both tokens stored in 3 layers:
  1. UserProvider (Dart fields: _token, _refreshToken)
  2. DioClient (Dart fields: _token, _refreshToken)
  3. SharedPreferences (keys: auth_token, refresh_token)
  ↓
Also stored inside UserModel.toJson() → cached as 'current_user'
  ↓
Every API request → Dio interceptor adds "Authorization: Bearer <token>"
  ↓
On 401/403 → _handleTokenRefresh → POST /auth/refresh-token → retry
```

### Key Files

| File | Role |
|------|------|
| `lib/newtork_repos/remote_repo/api_repos/dio_client.dart` | Dio HTTP client with Bearer token interceptor and refresh logic |
| `lib/controller/user_provider.dart` | State management — single source of truth for tokens and user data |
| `lib/models/user_model.dart` | User data model (previously contained token/refreshToken) |
| `lib/controller/local_control/cache_helper.dart` | SharedPreferences wrapper for persistence |
| `lib/utils/jwt_helper.dart` | **New** — JWT payload decoder |

---

## Issues Identified

| # | Issue | Severity | Root Cause |
|---|-------|----------|------------|
| 3 | No proactive token refresh — only reactive on 401 | High UX | No JWT expiry decoding, no timer mechanism |
| 4 | `token`/`refreshToken` inside `UserModel.toJson()` — cached with user data | Medium Security | UserModel was a catch-all for auth + user data |
| 5 | No token expiry tracking on client side | Medium Reliability | Tokens treated as opaque strings |
| 6 | `_handleTokenRefresh` has no retry limit — infinite loop risk | Medium Reliability | No counter, no backoff |

---

## Solution Design

### Issue #4: Remove Tokens from UserModel

**Problem:** `UserModel.toJson()` serialized `token` and `refreshToken` into the `current_user` cache key. This meant:
- Auth tokens were stored redundantly (3 places + inside UserModel JSON)
- Any code with access to SharedPreferences could extract tokens from the user JSON
- Token updates required `copyWith(token:..., refreshToken:...)` on the user model

**Solution:** Remove `token` and `refreshToken` fields from `UserModel` entirely. Tokens are already cached independently under `auth_token` and `refresh_token` keys.

**Changes to `lib/models/user_model.dart`:**
- Remove `token` and `refreshToken` from class fields
- Remove from constructor parameters
- Remove from `fromJson()`, `toJson()`, `copyWith()`

**Impact:** Only `user_provider.dart` called `toJson()`/`copyWith()` with token fields. All UI screens (`manage_users.dart`, `manager_task_screen.dart`, `manage_complmaints_screen.dart`) only access `id`, `displayName`, `username`, `role`, `department`, `enabled` — no changes needed.

---

### Issue #5: Token Expiry Tracking

**Problem:** Tokens were opaque strings with no client-side expiry knowledge. The app couldn't know if a token was about to expire until a request failed with 401.

**Solution:** Decode the JWT payload (base64url-encoded JSON) to extract the `exp` claim. Store the expiry timestamp in SharedPreferences alongside the token.

**New file `lib/utils/jwt_helper.dart`:**
```dart
import 'dart:convert';

class JwtHelper {
  static int? extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['exp'] as int?;
    } catch (_) {
      return null;
    }
  }
}
```

**Why no external package:** The project has no JWT libraries. Adding `dart_jsonwebtoken` or `jwt_decoder` for a single `exp` extraction is unnecessary. A 17-line helper using `dart:convert` (already in Flutter SDK) is sufficient.

**Changes to `lib/controller/user_provider.dart`:**
- Add `_tokenExpiry` field and `tokenExpiry` getter
- On `signIn`: decode JWT → extract `exp` → store as `DateTime` in `_tokenExpiry` and cache (`token_expiry` key)
- On `_loadTokenFromCache`: restore `_tokenExpiry` from cache; if expired, clear all tokens
- On `updateTokens`: decode new token → update `_tokenExpiry`
- On `signOut` / `clearUserData`: clear `_tokenExpiry`
- On `_clearTokenFromCache`: remove `token_expiry` key

---

### Issue #3: Proactive Token Refresh

**Problem:** Tokens were only refreshed reactively — a request had to fail with 401 first. This caused:
- A failed request on every token expiry
- UX hiccup (loading spinner → error → retry → success)
- Race conditions if multiple requests failed simultaneously

**Solution:** Schedule a `Timer` to refresh the token 60 seconds before expiry. The proactive refresh happens in the background with no failed request.

**Changes to `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`:**

**New fields:**
```dart
Timer? _refreshTimer;
static const Duration _refreshBuffer = Duration(seconds: 60);
```

**New public method `scheduleTokenRefresh(String token)`:**
1. Cancel any existing timer
2. Decode JWT → extract `exp`
3. Calculate `refreshAt = expiry - 60s`
4. Calculate `delay = refreshAt - now`
5. If delay is negative → refresh immediately
6. Otherwise → `Timer(delay, _proactiveRefresh)`

**New private method `_proactiveRefresh()`:**
1. Guard: return if no refresh token or already refreshing
2. Set `_isRefreshing = true`
3. POST `/auth/refresh-token` via `_dioForRefresh` (bypasses interceptor)
4. Extract new `token` and `refreshToken` from response
5. Decode new token → get new expiry
6. Fire `onTokensRefreshed` callback → `UserProvider.updateTokens()` persists
7. Call `scheduleTokenRefresh(newAccessToken)` → schedule next refresh
8. Reset `_refreshRetryCount = 0` on success
9. On failure: increment `_refreshRetryCount`, check against max

**Integration points:**
- `signIn` success → `DioClient().scheduleTokenRefresh(_token!)`
- `_loadTokenFromCache` success → `DioClient().scheduleTokenRefresh(_token!)`
- Reactive refresh success → `scheduleTokenRefresh(newAccessToken)`

**Updated `OnTokensRefreshed` typedef:**
```dart
typedef OnTokensRefreshed = Future<void> Function(
    String newAccessToken, String newRefreshToken, DateTime? newExpiry);
```

---

### Issue #6: Refresh Retry Limit

**Problem:** If the refresh endpoint was temporarily down, `_handleTokenRefresh` could theoretically loop forever (each retry getting a 401, triggering another refresh attempt).

**Solution:** Add a counter with a maximum of 3 attempts. After 3 failures, force session expiry.

**Changes to `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`:**

**New fields:**
```dart
int _refreshRetryCount = 0;
static const int _maxRefreshRetries = 3;
```

**Modified `_handleTokenRefresh`:**
```
1. If _refreshRetryCount >= _maxRefreshRetries:
   → Log "Max refresh retries exceeded"
   → Clear _token, _refreshToken
   → Reset _refreshRetryCount = 0
   → Call onSessionExpired
   → Fail all queued requests
   → Return original error
2. Otherwise:
   → Increment _refreshRetryCount
   → Attempt refresh
   → On success: reset _refreshRetryCount = 0
   → On failure: (counter already incremented)
```

**Also applied to `_proactiveRefresh`:**
- Same retry logic, but on max retries → clears tokens + fires session expiry
- Reactive handler remains as fallback

---

## Implementation Details

### Step-by-Step Changes

#### Step 1: UserModel Cleanup (`lib/models/user_model.dart`)

Remove `token` and `refreshToken` from:
- [x] Class fields (lines 8-9)
- [x] Constructor parameters (lines 19-20)
- [x] `fromJson()` (lines 34-35)
- [x] `toJson()` (lines 48-49)
- [x] `copyWith()` parameters and body (lines 64-65, 73-74)

#### Step 2: JWT Helper (`lib/utils/jwt_helper.dart`)

Create new file:
- [x] `JwtHelper.extractExpiry(String token)` → `int?` (seconds-since-epoch)
- [x] Handles malformed tokens gracefully (returns null)
- [x] Uses only `dart:convert` (no external dependencies)

#### Step 3: UserProvider Updates (`lib/controller/user_provider.dart`)

- [x] Add import for `jwt_helper.dart`
- [x] Add `_tokenExpiry` field and `tokenExpiry` getter
- [x] Update `_setupCallbacks` — `onTokensRefreshed` now receives `DateTime? newExpiry`
- [x] Update `_loadTokenFromCache` — restore expiry from cache, check if expired, schedule proactive refresh
- [x] Update `_clearTokenFromCache` — also remove `token_expiry` key
- [x] Update `clearUserData` — also clear `_tokenExpiry`
- [x] Update `updateTokens` — accept `DateTime? newExpiry`, store in cache, remove `copyWith(token:...)` block
- [x] Update `signIn` — decode JWT, extract expiry, schedule proactive refresh
- [x] Update `signUp` — remove token extraction from response (tokens go through signIn)
- [x] Update `signOut` — also clear `_tokenExpiry`

#### Step 4: DioClient Updates (`lib/newtork_repos/remote_repo/api_repos/dio_client.dart`)

- [x] Add import for `jwt_helper.dart`
- [x] Update `OnTokensRefreshed` typedef to include `DateTime? newExpiry`
- [x] Add `_refreshTimer`, `_refreshBuffer`, `_refreshRetryCount`, `_maxRefreshRetries` fields
- [x] Add `scheduleTokenRefresh(String token)` public method
- [x] Add `_proactiveRefresh()` private method
- [x] Add `dispose()` method to cancel timer
- [x] Update `_handleTokenRefresh` — add retry limit check, reset counter on success, schedule refresh after successful reactive refresh

---

## File Change Summary

| File | Status | Lines Changed |
|------|--------|---------------|
| `lib/models/user_model.dart` | Modified | ~20 lines removed (token/refreshToken fields) |
| `lib/utils/jwt_helper.dart` | **New** | 17 lines |
| `lib/controller/user_provider.dart` | Modified | ~60 lines changed/added |
| `lib/newtork_repos/remote_repo/api_repos/dio_client.dart` | Modified | ~80 lines added (proactive refresh + retry limit) |

**No new dependencies** — `jwt_helper.dart` uses only `dart:convert` (Flutter SDK).

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Token has no `exp` claim | `JwtHelper.extractExpiry` returns null → proactive refresh skipped → reactive 401 handler still works |
| Refresh endpoint is down | Reactive handler retries up to 3 times, then session expires |
| Multiple 401s during refresh | Queued in `_pendingRequests` and replayed after refresh (existing behavior, preserved) |
| App killed and restarted | `_loadTokenFromCache` restores token + expiry + reschedules proactive timer |
| Token already expired on cache restore | Expiry check in `_loadTokenFromCache` clears all tokens immediately |
| Proactive refresh fails | Logged; counter incremented; reactive handler remains as fallback |
| Proactive refresh fails 3 times | Session expired (tokens cleared, user redirected to login) |
| Concurrent proactive + reactive refresh | `_isRefreshing` flag prevents duplicate refresh calls |
| Token expiry is in the past (clock skew) | `_loadTokenFromCache` detects `isBefore(DateTime.now())` and clears |

---

## Testing Checklist

### Manual Testing

- [ ] **Login flow:** Sign in → verify tokens stored in SharedPreferences (3 keys: `auth_token`, `refresh_token`, `current_user` → no token/refreshToken inside user JSON)
- [ ] **Cache restore:** Kill app → relaunch → verify auto-login works and proactive timer is scheduled
- [ ] **Token expiry:** Wait for token to expire → verify proactive refresh fires 60s before → no failed request
- [ ] **401 fallback:** Manually invalidate access token → make API call → verify reactive refresh fires → request succeeds
- [ ] **Refresh failure:** Simulate refresh endpoint down → verify max 3 retries → session expires → redirected to login
- [ ] **Logout:** Sign out → verify all 4 cache keys cleared (`auth_token`, `refresh_token`, `token_expiry`, `current_user`)
- [ ] **Expired cache:** Manually set `token_expiry` to past date → relaunch app → verify tokens cleared

### Automated Testing

- [ ] Unit test: `JwtHelper.extractExpiry` with valid JWT, malformed token, missing `exp` claim
- [ ] Unit test: `UserModel.fromJson` / `toJson` no longer contains `token`/`refreshToken`
- [ ] Unit test: `UserProvider.updateTokens` stores expiry in cache
- [ ] Unit test: `DioClient._handleTokenRefresh` respects retry limit

---

## Architecture Diagram (After Changes)

```
                    ┌─────────────────────────────────────┐
                    │              DioClient                │
                    │                                       │
                    │  _dio (with interceptor)              │
                    │    └─ onRequest: add Bearer token     │
                    │    └─ onError 401/403:                │
                    │         └─ _handleTokenRefresh()      │
                    │              ├─ retry limit check     │
                    │              ├─ POST /refresh-token   │
                    │              ├─ onTokensRefreshed()   │
                    │              └─ scheduleTokenRefresh()│
                    │                                       │
                    │  _dioForRefresh (no interceptor)      │
                    │    └─ used for refresh calls only     │
                    │                                       │
                    │  _refreshTimer (proactive)            │
                    │    └─ fires 60s before expiry         │
                    │    └─ calls _proactiveRefresh()       │
                    │                                       │
                    │  _refreshRetryCount                   │
                    │    └─ max 3 attempts                  │
                    └─────────────────────────────────────┘
                                      │
                    onTokensRefreshed  │  onSessionExpired
                                      ▼
                    ┌─────────────────────────────────────┐
                    │           UserProvider                │
                    │                                       │
                    │  _token          (in-memory)          │
                    │  _refreshToken   (in-memory)          │
                    │  _tokenExpiry    (in-memory)          │
                    │  _currentUser    (in-memory)          │
                    │                                       │
                    │  signIn()                            │
                    │    ├─ POST /auth/signin              │
                    │    ├─ JwtHelper.extractExpiry()      │
                    │    ├─ scheduleTokenRefresh()         │
                    │    └─ save to cache (4 keys)         │
                    │                                       │
                    │  updateTokens()                      │
                    │    ├─ update in-memory               │
                    │    ├─ update DioClient               │
                    │    └─ save to cache                  │
                    │                                       │
                    │  clearUserData()                     │
                    │    └─ clear all + remove cache       │
                    └─────────────────────────────────────┘
                                      │
                    SharedPreferences  │
                                      ▼
                    ┌─────────────────────────────────────┐
                    │          Cache Keys                   │
                    │                                       │
                    │  auth_token     → access token        │
                    │  refresh_token  → refresh token       │
                    │  token_expiry   → DateTime (millis)   │
                    │  current_user   → UserModel JSON      │
                    │                    (no tokens!)       │
                    └─────────────────────────────────────┘
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Separate `_dioForRefresh`** | Prevents infinite interceptor loops — refresh call itself won't trigger another 401 handler |
| **60s buffer before expiry** | Gives enough time for the refresh round-trip to complete before the token actually expires |
| **Max 3 retry attempts** | Balances resilience (transient failures) against safety (permanent failures) |
| **No external JWT library** | Only `exp` is needed — a 17-line base64 decoder is sufficient and avoids dependency bloat |
| **`_isRefreshing` flag** | Prevents concurrent refresh calls — multiple 401s are queued and replayed |
| **Timer-based proactive refresh** | More reliable than checking expiry on every request; fires exactly when needed |
| **Reactive handler as fallback** | If proactive refresh fails or is skipped, the 401 handler catches it |

---

*Document generated on 21-06-2026 for tasks_app project.*
