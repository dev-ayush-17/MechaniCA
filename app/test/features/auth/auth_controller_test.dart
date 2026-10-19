import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/config/app_config.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/auth/data/fake_account_api.dart';
import 'package:mechupp_app/features/auth/data/fake_auth_service.dart';
import 'package:mechupp_app/features/auth/domain/account_api.dart';
import 'package:mechupp_app/features/auth/domain/auth_service.dart';
import 'package:mechupp_app/features/auth/presentation/auth_controller.dart';

class _FailingAccounts implements AccountApi {
  @override
  Future<Result<Account>> bootstrap(
    Session session, {
    required AccountIntent intent,
    String? name,
  }) async =>
      const Err(Unavailable('Could not reach the server.'));

  @override
  Future<Result<Account>> me(Session session) async => const Err(Unavailable());
}

AuthNotifier _notifier(AccountApi accounts, FakeAuthService service) =>
    AuthNotifier(service, accounts);

FakeAuthService _service() => FakeAuthService(
      env: AppEnv.dev,
      clock: FakeClock(DateTime.utc(2026, 10, 19, 8)),
    );

void main() {
  test('verify_then_bootstrap_signs_in', () async {
    final service = _service();
    final notifier = _notifier(FakeAccountApi(), service);

    final ok = await notifier.verifyOtp('9876543210', '123456');

    expect(ok, isTrue);
    expect(notifier.state.isLoggedIn, isTrue);
    expect(notifier.state.account?.role, 'customer');
  });

  test('bootstrap_failure_drops_the_session_and_shows_the_message', () async {
    final service = _service();
    final notifier = _notifier(_FailingAccounts(), service);

    final ok = await notifier.verifyOtp('9876543210', '123456');

    expect(ok, isFalse);
    expect(notifier.state.isLoggedIn, isFalse);
    expect(notifier.state.error, 'Could not reach the server.');
    expect(await service.currentSession(), isNull);
  });

  test('wrong_code_keeps_the_user_signed_out', () async {
    final notifier = _notifier(FakeAccountApi(), _service());

    final ok = await notifier.verifyOtp('9876543210', '000000');

    expect(ok, isFalse);
    expect(notifier.state.error, 'That code is incorrect.');
  });

  test('logout_clears_the_state', () async {
    final notifier = _notifier(FakeAccountApi(), _service());
    await notifier.verifyOtp('9876543210', '123456');

    await notifier.logout();

    expect(notifier.state.isLoggedIn, isFalse);
  });
}
