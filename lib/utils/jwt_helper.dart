import 'dart:convert';

class JwtHelper {
  /// Extracts the 'exp' claim (expiry as seconds-since-epoch) from a JWT.
  /// Returns null if the token is malformed or has no exp claim.
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
