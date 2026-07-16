# Token & Refresh Token Lifecycle

## Architecture Overview

There are **3 layers** involved in token management:

| Layer | File | Role |
|-------|------|------|
| **Storage & State** | `auth_state_manager.dart` | Single source of truth for tokens. Manages cache, emits status events. |
| **HTTP & Refresh** | `dio_client.dart` | Intercepts requests, triggers refreshes, handles cross-tab sync. |
| **UI Bridge** | `user_provider.dart` | Connects auth state to Flutter widgets, handles sign-in/out flows. |

---

## 1. Sign-In — How Tokens Are Born

**`user_provider.dart:244-293`** — `signIn()`:
1. Calls `POST /auth/signin` with username/password
2. Server returns `{ token, refreshToken, ... }`
3. Validates `token` has a valid `exp` claim via `JwtHelper.extractExpiry()`
4. Calls `_auth.setTokensFromSignIn(token, refreshToken)` which:
   - Sets `_sessionStartTime = DateTime.now()` (90-day countdown begins)
   - Persists both tokens + expiry + session start to `CacheHelper` (localStorage)
   - Pushes tokens into `DioClient` via `_api.setToken()` / `_api.setRefreshToken()`
5. Calls `DioClient().scheduleTokenRefresh(token)` to start the smart polling timer

**Storage keys** (all in localStorage via `CacheHelper`):
- `auth_token` — access token (JWT string)
- `refresh_token` — refresh token (opaque string)
- `token_expiry` — milliseconds since epoch
- `session_start_time` — milliseconds since epoch

---

## 2. Every API Request — Token Injection

**`dio_client.dart:62-76`** — Dio interceptor `onRequest`:
1. Checks if `_token != null` and the endpoint is not `/auth/signin` or `/auth/refresh-token`
2. Calls `_preemptiveRefreshIfNeeded()` — if token is within 60 seconds of expiry, refreshes it *before* the request fires
3. Sets `Authorization: Bearer $_token` on the outgoing request

---

## 3. Token Refresh — Two Paths

### Path A: Proactive (Scheduled Polling)

**`dio_client.dart:125-158`** — Smart polling:
- After each refresh, `scheduleTokenRefresh()` is called
- `_calculatePollInterval()` dynamically chooses the check interval:
  - >6 hours left → poll every **30 min**
  - >1 hour left → poll every **10 min**
  - >10 min left → poll every **5 min**
  - >1 min left → poll every **1 min**
  - <1 min left → refresh **now**
- Timer fires `_checkAndRefresh()` which checks if token is within the 60-second buffer zone, and if so, calls `_proactiveRefresh()`

### Path B: Reactive (401/403 Interceptor)

**`dio_client.dart:81-92, 252-344`** — Dio interceptor `onError`:
1. A request returns 401/403 → calls `_handleTokenRefresh()`
2. If another refresh is already in flight (`_isRefreshing == true`), the request joins a **pending queue** (`Queue<_PendingRequest>`)
3. Posts `{ refreshToken }` to `POST /auth/refresh-token` using a **separate Dio instance** (`_dioForRefresh` — avoids interceptor recursion)
4. Server returns new `{ token, refreshToken }` pair
5. Updates `_token` and `_refreshToken` in-memory
6. Calls `_onTokensRefreshed` callback → which flows to `AuthStateManager.notifyTokenRefreshed()` → saves to cache
7. Re-schedules the smart polling timer with the new token
8. Broadcasts new tokens to other tabs (if leader)
9. **Retries the original failed request** with the new token
10. **Drains the pending queue** — all queued requests also get retried with the new token

---

## 4. Refresh Failure Handling

**`dio_client.dart:230-244, 312-331`**:
- **401/403 from refresh endpoint** → refresh token is rejected by server → `_token` and `_refreshToken` nulled → `_onSessionExpired()` called → `AuthStateManager.notifySessionExpired()` emits `AuthStatus.expired` + clears cache → UI redirects to login
- **Network error / 5xx** → `AuthStatus.transientError` emitted → session kept alive → smart polling timer will retry on next cycle

---

## 5. Cross-Tab Synchronization

**`dio_client.dart:348-505`**:
- Uses `BroadcastChannel('auth_tokens')` and `BroadcastChannel('auth_leader')`
- **Leader election**: the tab with the lowest `_leaderId` wins. Leader pings every 15s. If no ping for 30s, another tab claims leadership.
- **Leader refreshes**, then broadcasts `TOKENS|accessToken|refreshToken` on the auth channel
- **Non-leader tabs** receive the message, update their in-memory `_token`/`_refreshToken`, call `_onTokensRefreshed` to persist to their own localStorage, and reschedule their timers
- On session expiry, leader broadcasts `EXPIRED` → all tabs clear state

---

## 6. Resume / Focus Recovery

**`user_provider.dart:70-104`** — `_checkTokenOnResume()`:
- Triggered by both `AppLifecycleState.resumed` (mobile) and `onWindowFocus` (web)
- If token expired while app was inactive → calls `_auth.attemptRefresh()` directly (not through DioClient)
- If refresh succeeds → restores user from cache
- If refresh rejected → clears everything (`clearUserData()`)
- If token still valid → reschedules the proactive timer

---

## 7. Sign-Out / Session Clear

**`user_provider.dart:295-302`** — `signOut()`:
1. Calls `POST /auth/signout` with the refresh token (server-side invalidation)
2. Calls `clearUserData()` which:
   - Nulls `_currentUser`, `_users`, `_error`
   - `_auth.clearSession()` → nulls all token fields + clears all 4 localStorage keys + calls `_api.clearToken()` / `_api.clearRefreshToken()` on DioClient
   - `DioClient().cancelTimer()` stops the polling timer

**`auth_state_manager.dart:187-195`** — `clearSession()`:
```dart
_token = null;  →  _api.clearToken()   →  CacheHelper.removeData('auth_token')
_refreshToken = null;  →  _api.clearRefreshToken()  →  CacheHelper.removeData('refresh_token')
_tokenExpiry = null;  →  CacheHelper.removeData('token_expiry')
_sessionStartTime = null;  →  CacheHelper.removeData('session_start_time')
```

---

## 8. Max Session Lifetime (90 Days)

**`auth_state_manager.dart:17, 49-52`**:
- `_maxSessionLifetime = Duration(days: 90)`
- `isSessionExpired()` checks `DateTime.now().difference(_sessionStartTime) > 90 days`
- Checked in 4 places:
  1. `_loadFromCache()` on startup — if expired, clears session immediately
  2. `_checkAndRefresh()` before periodic refresh — refuses to refresh, clears session
  3. `_proactiveRefresh()` before proactive refresh — refuses to refresh, clears session
  4. `attemptRefresh()` — refuses refresh if session is too old

---

## Visual Flow

```
SignIn → [token, refreshToken] → AuthStateManager (cache + memory)
                                       ↓
                               DioClient (in-memory)
                                       ↓
                          ┌─── Smart Timer (proactive refresh)
                          │
Every Request ──→ Interceptor ──→ token < 60s? ──→ refresh first
                          │
                          └─── 401/403? ──→ reactive refresh
                                       ↓
                              New [token, refreshToken]
                                       ↓
                    ┌──────────────────┼──────────────────┐
                    ↓                  ↓                  ↓
              AuthStateManager    BroadcastChannel    Re-queue pending
              (save to cache)     (notify other tabs) (retry failed reqs)
```
