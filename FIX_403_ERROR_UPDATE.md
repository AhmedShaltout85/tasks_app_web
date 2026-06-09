# Plan: Fix 403 Error with Expired JWT Tokens

## Root Cause

The backend returns **HTTP 403** when an expired/invalid JWT is presented, but the Flutter DioClient interceptor only catches **HTTP 401**. This means the refresh token logic never triggers, and the user sees a 403 error.

Spring Security 6.x with stateless sessions and no custom `AuthenticationEntryPoint` returns 403 by default for unauthenticated requests.

---

## Files to Modify (4 files)

### 1. `SecurityConfig.java` (CRITICAL)
**Path**: `tasks-api/src/main/java/com/ao8r/tasks_api/config/security/SecurityConfig.java`

**Change**: Add custom `AuthenticationEntryPoint` to return 401 instead of default 403.

```java
.exceptionHandling(ex -> ex
    .authenticationEntryPoint((request, response, authException) -> {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\": \"Unauthorized\"}");
    })
)
```

Add import: `import jakarta.servlet.http.HttpServletResponse;`

---

### 2. `dio_client.dart` (HIGH)
**Path**: `tasks_app/lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

**Change at line 57**: Catch 403 in addition to 401 for robustness.

```dart
if ((error.response?.statusCode == 401 || error.response?.statusCode == 403) &&
    !_isAuthEndpoint(error.requestOptions.path)) {
```

---

### 3. `settings_screen.dart` (MEDIUM)
**Path**: `tasks_app/lib/screens/settings/settings_screen.dart`

**Change at line 744**: Use `signOut()` instead of `clearUserData()` for proper server-side token revocation.

```dart
// Before:
userProvider.clearUserData();

// After:
await userProvider.signOut();
```

---

### 4. `dio_client.dart` - Interceptor (LOW)
**Path**: `tasks_app/lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

**Change in `onRequest` interceptor**: Skip adding Bearer token for auth endpoints.

```dart
if (_token != null && !_isAuthEndpoint(options.path)) {
    options.headers['Authorization'] = 'Bearer $_token';
}
```

---

## Implementation Order

| Step | File | Action | Status |
|------|------|--------|--------|
| 1 | `SecurityConfig.java` | Add `AuthenticationEntryPoint` to return 401 | ✅ DONE |
| 2 | `dio_client.dart` | Catch 403 in addition to 401 | ✅ DONE |
| 3 | `settings_screen.dart` | Use `signOut()` instead of `clearUserData()` | ✅ DONE |
| 4 | `dio_client.dart` | Skip token injection for auth endpoints | ✅ DONE |

---

## Verification

1. After Step 1: Restart backend, test with expired JWT via curl/Postman - should return 401
2. After Step 2: Test Flutter app with expired token - should auto-refresh
3. After Step 3: Test logout from settings screen - refresh token should be revoked server-side
4. After Step 4: Test refresh token endpoint - should not have expired access token in header
