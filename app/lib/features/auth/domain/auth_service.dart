import '../../../core/error/result.dart';

/// A signed-in caller. The token is held in memory only; the Auth SDK owns
/// persistence (docs/prd/11-authentication.md).
class Session {
  const Session({
    required this.userId,
    required this.idToken,
    required this.expiresAt,
    required this.role,
  });

  final String userId;
  final String idToken;
  final DateTime expiresAt;

  /// `customer` or `mechanic`. The server decides; the client only displays it.
  final String role;
}

/// Phone sign-in. Vendors implement this; widgets never import a vendor SDK
/// (docs/prd/08-port-catalog.md).
abstract interface class AuthService {
  /// Sends a one-time code to [phoneE164], for example `+919876543210`.
  Future<Result<void>> requestOtp(String phoneE164);

  Future<Result<Session>> verifyOtp(String phoneE164, String code);

  /// Disabled until `auth_google_enabled` is on. Adapters answer
  /// `Unavailable` with the message `provider_disabled`.
  Future<Result<Session>> signInWithGoogle();

  Future<Result<void>> signOut();

  /// The locally stored session, or null. Async because platform storage is.
  Future<Session?> currentSession();
}
