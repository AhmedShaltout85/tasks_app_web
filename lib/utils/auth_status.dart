/// Represents the current state of the authentication/token system.
/// Emitted via [AuthStateManager.statusStream] so the UI can react accordingly.
enum AuthStatus {
  /// User has a valid token. No refresh in progress.
  authenticated,

  /// A token refresh is currently in progress (proactive or reactive).
  refreshing,

  /// A token refresh just completed successfully.
  refreshed,

  /// Token is approaching expiry (within 5 minutes).
  /// UI may want to show a "session expiring soon" warning.
  expiring,

  /// Session was cleared (refresh token rejected by server, max lifetime exceeded, or explicit sign-out).
  /// UI should redirect to login.
  expired,

  /// A transient error occurred (network, timeout, 5xx).
  /// Session is kept alive; the periodic timer will retry.
  transientError,
}
