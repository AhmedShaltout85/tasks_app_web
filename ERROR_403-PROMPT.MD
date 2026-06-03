# Fix 403 Error - Token Expiry (24 Hours)

## Problem
The JWT token expires after 24 hours and there is no refresh token mechanism on the backend. When the token expires, all API calls fail with a 403 error, forcing the user to re-login manually.

## Backend Constraint
- No refresh token endpoint available (`/auth/refresh` does not exist)
- Backend only issues a single JWT token on login with 24h expiry

## Solution: Auto Re-Login on 403
When a 403 is received, automatically re-login using stored credentials and retry the failed request transparently.

---

## Changes Made

### 1. `dio_client.dart` - Auto re-login interceptor

**File:** `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`

- Added callback types: `CredentialsGetter`, `OnTokenRefreshed`, `OnReLoginFailed`
- Created a separate `_dioForRefresh` Dio instance for re-login (avoids interceptor loop)
- Added `_isRefreshing` lock to prevent concurrent re-login attempts
- In `onError` interceptor:
  - Catches `403` status code (excluding `/auth/signin` path)
  - Calls `_tryRefreshToken()` which uses saved credentials to re-login
  - If successful, retries the original request with new token
  - If failed, triggers `onReLoginFailed` callback (logs user out)
- Added `setCallbacks()` method for UserProvider to inject dependencies

### 2. `user_provider.dart` - Credential management

**File:** `lib/controller/user_provider.dart`

- Added import for `DioClient`
- Added `_setupCallbacks()` in constructor to wire DioClient callbacks
- Added `_saveCredentialsToCache(username, password)` - saves credentials on login
- Added `getSavedCredentials()` - returns saved username/password for auto re-login
- Updated `_clearTokenFromCache()` to also clear `saved_username` and `saved_password`
- Updated `signIn()` to call `_saveCredentialsToCache()` after successful login
- Updated `signOut()` to call `_clearTokenFromCache()` (clears credentials)
- Added `onTokenRefreshed` callback: updates token, user, cache, and notifies listeners
- Added `onReLoginFailed` callback: calls `clearUserData()` to redirect to login

---

## Flow

```
1. User logs in
   → credentials saved to SharedPreferences
   → token saved to cache

2. Token expires after 24h
   → API returns 403

3. Dio interceptor catches 403
   → reads saved credentials from SharedPreferences
   → calls /auth/signin with credentials
   → gets new token

4. Original request retried
   → new token attached automatically
   → user sees no interruption

5. If re-login fails
   → clearUserData() called
   → user redirected to login screen
```

## Files Modified
- `lib/newtork_repos/remote_repo/api_repos/dio_client.dart`
- `lib/controller/user_provider.dart`
