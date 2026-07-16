# Unfinished Tasks — 16 July 2026

## Project: tasks_app_web

---

## Session Summary

### Goal
Ensure the project plan in `LOGIN_EVERY_3_MONTHS.md` is properly achieved — a suite of 7 enhancements to make the token/session system robust, with a 90-day max session lifetime ("login every 3 months").

### Audit Result
6 of 7 enhancements are already implemented in code. 4 gaps remain:

| # | Enhancement | Files | Status | Remaining Gap |
|---|---|---|---|---|
| 1 | Smart polling interval | `dio_client.dart` | ✅ Done | — |
| 2 | Cross-tab synchronization | `dio_client.dart` | ⚠️ Broken | Leader election is fake — each tab always declares itself leader. Need real BroadcastChannel ping coordination. |
| 3 | Pre-emptive refresh | `dio_client.dart` | ✅ Done | — |
| 4 | Token status stream | `auth_status.dart`, `auth_state_manager.dart`, `user_provider.dart`, `dio_client.dart` | ✅ Done | — |
| 5 | Migrate `dart:html` → `package:web` | `web_helper_web.dart`, `dio_client.dart` | ⚠️ Partial | `web_helper_web.dart` uses `dart:js_interop` instead of `package:web`. `dio_client.dart` BroadcastChannel is raw JS interop, not `package:web`. |
| 6 | Centralized auth state machine | `auth_state_manager.dart`, `user_provider.dart`, `dio_client.dart` | ✅ Done | — |
| 7 | 90-day max session lifetime | `auth_state_manager.dart` (static), `dio_client.dart` (enforced) | ✅ Done | — |
| — | UI indicator for auth status | — | ❌ Missing | `UserProvider.authStatus` exists but no widget reads it. Plan Step 9 says show a `RefreshIndicator()` when refreshing. |

### Gaps to Fix

1. **Fix leader election** (`dio_client.dart:424-438`): Replace per-tab `_lastLeaderHeartbeat` with a shared heartbeat via a second BroadcastChannel (`'auth_leader'`). Leader sends `LEADER_PING|<id>` every 15s; followers demote themselves if they see a higher-priority leader within 25s.

2. **Migrate `web_helper_web.dart` to `package:web`**: Rewrite using `package:web/web.dart as web` — use `web.window.onFocus`, `onBlur`, `document.onVisibilityChange`.

3. **Migrate `dio_client.dart` BroadcastChannel to `package:web` + harden decoder**: Replace `@JS('BroadcastChannel') extension type` with `package:web`'s `web.BroadcastChannel`. Fix `onmessage` to use typed `MessageEvent` with `String` payload guard.

4. **Add UI auth-status indicator**: Wrap `home: const SplashScreen()` in `main.dart` with a `_AuthStatusOverlay` widget (Consumer<UserProvider>) that shows a thin progress bar when `authStatus == refreshing` and a subtle warning strip when `expiring` or `transientError`.

### Next Steps
Exit plan mode, then implement the 4 fixes in this order:
1. web_helper_web.dart migration (independent)
2. dio_client.dart: BroadcastChannel migration + leader election fix + decoder hardening (touches same area)
3. main.dart: UI indicator (independent)
4. `flutter analyze` to verify

---

## Token Notes

- **ChatId**: This conversation
- **Package**: `tasks_app` (Flutter Web)
- **Dart SDK**: ^3.5.3
- **Key files**:
  - `lib/services/auth_state_manager.dart` (207 lines) — centralized auth
  - `lib/newtork_repos/remote_repo/api_repos/dio_client.dart` (458 lines) — HTTP client + polling + cross-tab
  - `lib/controller/user_provider.dart` (475 lines) — state provider + status stream listener
  - `lib/utils/auth_status.dart` (24 lines) — enum
  - `lib/utils/web_helper/web_helper_web.dart` (49 lines) — web interop
  - `lib/utils/web_helper/web_helper_stub.dart` (13 lines) — stub
- **`pubspec.yaml` line 56**: Already has `web: ^1.1.0`

======================
Detailed Plan — Fix All Gaps
Gap 1: Real Leader Election (Critical)
Replace the broken per-tab _lastLeaderHeartbeat with a shared heartbeat via a second BroadcastChannel 'auth_leader'.

New file: lib/newtork_repos/remote_repo/api_repos/_leader_election.dart (small helper)

Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart:

Generate _leaderId once per DioClient instance: a random '<timestamp>-<random>' string.
Add a second _BroadcastChannel _leaderChannel = _BroadcastChannel('auth_leader').
Replace _checkLeadership():
If a LEADER_PING|<id> from another tab arrives and _leaderId < id (string compare by timestamp prefix), set _isLeader = false and update _lastLeaderSeen = now.
If no leader ping for >25s, promote self to leader.
Leader sends LEADER_PING|<_leaderId> every 15s.
Rename _lastLeaderHeartbeat → _lastLeaderSeen (timestamp of remote pings) and _lastSelfPing (timestamp of our pings).
Remove the immediate _checkLeadership() call that runs at startup — wait 25s grace period, otherwise the first tab always wins by timing.
Gap 2: Migrate to package:web
Modify lib/utils/web_helper/web_helper_web.dart to use web.window.onFocus / onBlur / document.onVisibilityChange directly (plan section 2a).

Modify lib/newtork_repos/remote_repo/api_repos/dio_client.dart:

Delete the @JS('BroadcastChannel') extension type _BroadcastChannel block (lines 14-20).
Import package:web/web.dart as web and use web.BroadcastChannel('auth_tokens') / 'auth_leader'.
onmessage becomes (web.MessageEvent event) { ... } — typed payload via event.data (already a JSAny? we can cast).
postMessage(message) with a String Dart value.
Gap 3: Harden Broadcast Payload Decoder
With package:web, MessageEvent.data is typed. The current decoder casts blindly to JSString. New decoder:

final raw = event.data;
if (raw is! String) return;     // type-safe
_handleBroadcastMessage(raw);
Same _handleBroadcastMessage logic (TOKENS|a|r / EXPIRED||) — keep simple string protocol.

Gap 4: UI Refreshing Indicator
Modify lib/screens/splash/splash_screen.dart — no change needed (animation only).

Modify lib/main.dart: wrap home: const SplashScreen() so a Consumer<UserProvider> overlays a thin top banner. Concretely:

home: const _AuthStatusOverlay(child: SplashScreen()),
where _AuthStatusOverlay is a small StatelessWidget in main.dart (or a new file) that uses Consumer<UserProvider> and shows a 2-px LinearProgressIndicator(minHeight: 2) when user.authStatus == AuthStatus.refreshing (and a yellow strip when AuthStatus.expiring or AuthStatus.transientError). This covers both the splash and any subsequent route because the overlay sits above the navigator.

Optional micro-tweak: also reset _authStatus to authenticated after a short delay (2 s) so the indicator doesn't linger on refreshed.

Files Touched
File	Change
lib/newtork_repos/remote_repo/api_repos/dio_client.dart	Real leader election, migrate to package:web BroadcastChannel, harden decoder
lib/utils/web_helper/web_helper_web.dart	Rewrite using package:web/web.dart
lib/main.dart	Wrap home with auth-status overlay
No new files (or one optional small overlay file).

Verification (after exiting plan mode)
fvm flutter analyze — 0 errors.
Manual cross-tab test: open 2 tabs signed in → wait for leader election (15-25s) → in tab A console proactive refresh → confirm only tab A posts TOKENS|... and tab B picks it up; no ping-pong (tab B should not echo back).
Manually corrupt localStorage auth_token so it expires in 30s → reload → first API call should preemptively refresh; banner should flash.
Inspect _BroadcastChannel console logs — should see exactly one This tab is now the leader per heartbeat cycle, not per tab.
Risk
Migrating to package:web may pull in a new transitive dep — pubspec.yaml already has web: ^1.1.0, so flutter pub get is the only step.
Leader election's 25s grace period means cross-tab refresh may be slightly delayed after a fresh page load. Acceptable because the per-tab _periodicTimer still runs independently until the leader takes over.
Ready to implement when you exit plan mode.