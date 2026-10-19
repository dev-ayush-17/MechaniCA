import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/config/app_config.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/auth/data/fake_account_api.dart';
import 'package:mechupp_app/features/auth/data/fake_auth_service.dart';
import 'package:mechupp_app/features/auth/data/fake_session_store.dart';
import 'package:mechupp_app/features/auth/domain/account_api.dart';
import 'package:mechupp_app/features/auth/domain/auth_service.dart';
import 'package:mechupp_app/features/auth/presentation/splash_screen.dart';

const _phone = '+919876543210';

FakeAuthService _service(FakeSessionStore store, {AppEnv env = AppEnv.dev}) =>
    FakeAuthService(
      env: env,
      clock: FakeClock(DateTime.utc(2026, 10, 19, 8)),
      store: store,
    );

class _StubAccounts implements AccountApi {
  _StubAccounts(this._result);

  final Result<Account> _result;

  @override
  Future<Result<Account>> bootstrap(
    Session session, {
    required AccountIntent intent,
    String? name,
  }) async =>
      _result;

  @override
  Future<Result<Account>> me(Session session) async => _result;
}

const _account = Account(
  id: 'fake_919876543210',
  role: 'customer',
  name: '',
  phoneE164: _phone,
);

void main() {
  group('fake session persistence', () {
    test('a_signed_in_phone_is_restored_by_a_new_service', () async {
      final store = MemoryFakeSessionStore();
      await _service(store).verifyOtp(_phone, '123456');

      final restored = await _service(store).currentSession();

      expect(restored?.userId, 'fake_919876543210');
    });

    test('sign_out_forgets_the_session', () async {
      final store = MemoryFakeSessionStore();
      final first = _service(store);
      await first.verifyOtp(_phone, '123456');
      await first.signOut();

      expect(await _service(store).currentSession(), isNull);
    });

    test('prod_never_restores_a_fake_session', () async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);

      expect(await _service(store, env: AppEnv.prod).currentSession(), isNull);
    });
  });

  group('AuthNotifier.restore', () {
    test('no_stored_session_means_signed_out', () async {
      final notifier =
          AuthNotifier(_service(MemoryFakeSessionStore()), FakeAccountApi());

      expect(await notifier.restore(), isFalse);
      expect(notifier.state.isLoggedIn, isFalse);
    });

    test('valid_session_restores_and_loads_the_account', () async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);
      final notifier =
          AuthNotifier(_service(store), _StubAccounts(const Ok(_account)));

      expect(await notifier.restore(), isTrue);
      expect(notifier.state.account?.id, 'fake_919876543210');
    });

    test('missing_account_is_bootstrapped_again', () async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);
      final notifier = AuthNotifier(_service(store), FakeAccountApi());

      expect(await notifier.restore(), isTrue);
      expect(notifier.state.account?.role, 'customer');
    });

    test('offline_launch_keeps_the_session', () async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);
      final notifier = AuthNotifier(
        _service(store),
        _StubAccounts(const Err(Unavailable())),
      );

      expect(await notifier.restore(), isTrue);
      expect(notifier.state.account, isNull);
    });

    test('rejected_session_signs_out_locally', () async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);
      final service = _service(store);
      final notifier =
          AuthNotifier(service, _StubAccounts(const Err(Unauthenticated())));

      expect(await notifier.restore(), isFalse);
      expect(await service.currentSession(), isNull);
    });
  });

  group('splash', () {
    Future<void> pumpSplash(WidgetTester tester, FakeSessionStore store) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
          GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
          GoRoute(
              path: '/onboarding',
              builder: (_, __) => const Text('ONBOARDING')),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(_service(store)),
            accountApiProvider.overrideWithValue(FakeAccountApi()),
          ],
          child: MaterialApp.router(
              theme: AppTheme.darkTheme, routerConfig: router),
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    testWidgets('restored_session_skips_onboarding', (tester) async {
      final store = MemoryFakeSessionStore();
      await store.writePhone(_phone);

      await pumpSplash(tester, store);

      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('ONBOARDING'), findsNothing);
    });

    testWidgets('no_session_shows_onboarding', (tester) async {
      await pumpSplash(tester, MemoryFakeSessionStore());

      expect(find.text('ONBOARDING'), findsOneWidget);
    });
  });
}
