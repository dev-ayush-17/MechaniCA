import '../../../core/error/result.dart';
import '../domain/account_api.dart';
import '../domain/auth_service.dart';

/// Offline stand-in for the API so the demo works when no server is running.
/// Same rules as the real bootstrap: idempotent, and a second intent conflicts.
class FakeAccountApi implements AccountApi {
  final Map<String, Account> _accounts = {};

  @override
  Future<Result<Account>> bootstrap(
    Session session, {
    required AccountIntent intent,
    String? name,
  }) async {
    final role = intent == AccountIntent.mechanic ? 'mechanic' : 'customer';
    final existing = _accounts[session.userId];
    if (existing != null) {
      if (existing.role != role) {
        return const Err(Conflict(
          'This phone is already registered with another role.',
          code: 'role_exists',
        ));
      }
      return Ok(existing);
    }
    final account = Account(
      id: session.userId,
      role: role,
      name: (name ?? '').trim(),
      phoneE164: session.userId.replaceFirst('fake_', '+'),
    );
    _accounts[session.userId] = account;
    return Ok(account);
  }

  @override
  Future<Result<Account>> me(Session session) async {
    final account = _accounts[session.userId];
    return account == null
        ? const Err(NotFound('Finish sign-in first.'))
        : Ok(account);
  }
}
