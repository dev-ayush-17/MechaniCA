import '../../../core/error/result.dart';
import 'auth_service.dart';

/// Which app is signing in. The server turns this into a role; the client never
/// sends a role (docs/prd/11-authentication.md).
enum AccountIntent { customer, mechanic }

class Account {
  const Account({
    required this.id,
    required this.role,
    required this.name,
    required this.phoneE164,
  });

  final String id;
  final String role;
  final String name;
  final String phoneE164;
}

/// The caller's account on our API: `POST /v1/me/bootstrap` and `GET /v1/me`.
abstract interface class AccountApi {
  /// Creates the account on first sign-in. Repeating the call is safe.
  Future<Result<Account>> bootstrap(
    Session session, {
    required AccountIntent intent,
    String? name,
  });

  Future<Result<Account>> me(Session session);
}
