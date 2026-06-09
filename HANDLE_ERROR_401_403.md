# Plan: Handle 401/403 Errors in Flutter App

## Root Cause

When an expired/invalid JWT is presented, the backend may return **HTTP 403** (Spring Security default) or **HTTP 401**. The current DioClient interceptor only catches **401**, so 403 errors bypass the refresh token logic entirely and the user sees a raw error.

Additionally, the Bearer token is injected into auth endpoints (like `/auth/signin` and `/auth/refresh-token`) which can cause issues, and the settings screen logout uses `clearUserData()` instead of `signOut()` so the refresh token is never revoked server-side.

---

## Files to Modify (2 files)

### 1. `dio_client.dart` — Catch 403 + skip token for auth endpoints

**Path:** `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

**Change A — `onError` interceptor (line 64):**
Catch 403 in addition to 401 for robustness:

```dart
// Before:
if (statusCode == 401 && !_isAuthEndpoint(path)) {

// After:
if ((statusCode == 401 || statusCode == 403) && !_isAuthEndpoint(path)) {
```

**Change B — `onRequest` interceptor (line 46):**
Skip adding Bearer token for auth endpoints to avoid sending an expired access token to `/auth/signin` or `/auth/refresh-token`:

```dart
// Before:
if (_token != null) {
  options.headers['Authorization'] = 'Bearer $_token';
  log('TOKEN ADDED: Bearer $_token');
} else {
  log('NO TOKEN - Request may be unauthorized');
}

// After:
if (_token != null && !_isAuthEndpoint(options.path)) {
  options.headers['Authorization'] = 'Bearer $_token';
  log('TOKEN ADDED: Bearer $_token');
} else if (_isAuthEndpoint(options.path)) {
  log('SKIPPING TOKEN for auth endpoint: ${options.path}');
} else {
  log('NO TOKEN - Request may be unauthorized');
}
```

---

### 2. `settings_screen.dart` — Use `signOut()` for proper revocation

**Path:** `lib/screens/settings/settings_screen.dart`

**Change at line 699:**
Use `signOut()` instead of `clearUserData()` so the refresh token is sent to the server for revocation:

```dart
// Before:
userProvider.clearUserData();

// After:
await userProvider.signOut();
```

Note: The `onPressed` callback is already `async`, so `await` works directly.

---

## Implementation Order

| Step | File | Action |
|------|------|--------|
| 1 | `dio_client.dart` | Add 403 to error interceptor condition |
| 2 | `dio_client.dart` | Skip Bearer token injection for auth endpoints |
| 3 | `settings_screen.dart` | Replace `clearUserData()` with `signOut()` |
| 4 | Verify | Run `flutter analyze` |

---

## Verification

1. **After Steps 1-2:** Test Flutter app with expired token against backend returning 403 — should auto-refresh via `/auth/refresh-token`
2. **After Step 3:** Test logout from settings screen — refresh token should be revoked server-side (POST `/auth/signout` with `{"refreshToken": "..."}`)
3. **After all:** Run `flutter analyze` — no new errors
