import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/config/app_config.dart';
import 'package:mechupp_app/core/error/result.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/auth/data/fake_auth_service.dart';

const _phone = '+919876543210';

FakeAuthService _service(AppEnv env, FakeClock clock) =>
    FakeAuthService(env: env, clock: clock);

void main() {
  late FakeClock clock;

  setUp(() => clock = FakeClock(DateTime.utc(2026, 10, 19, 8)));

  test('demo_otp_signs_in_when_dev', () async {
    final result =
        await _service(AppEnv.dev, clock).verifyOtp(_phone, '123456');
    final session = result.when(onOk: (s) => s, onErr: (_) => null);
    expect(session?.role, 'customer');
  });

  test('prod_config_rejects_demo_otp', () async {
    final service = _service(AppEnv.prod, clock);
    final result = await service.verifyOtp(_phone, '123456');
    expect(result, isA<Err<dynamic>>());
    expect(await service.currentSession(), isNull);
  });

  test('otp_lockout_after_five_failures', () async {
    final service = _service(AppEnv.dev, clock);
    for (var i = 0; i < 4; i++) {
      final r = await service.verifyOtp(_phone, '000000');
      expect((r as Err).failure, isA<InvalidInput>());
    }
    final fifth = await service.verifyOtp(_phone, '000000');
    expect((fifth as Err).failure, isA<RateLimited>());

    // Even the right code is refused while locked.
    final locked = await service.verifyOtp(_phone, '123456');
    expect((locked as Err).failure, isA<RateLimited>());

    clock.advance(FakeAuthService.lockDuration + const Duration(seconds: 1));
    final after = await service.verifyOtp(_phone, '123456');
    expect(after, isA<Ok<dynamic>>());
  });

  test('resend_is_rate_limited_per_phone', () async {
    final service = _service(AppEnv.dev, clock);
    expect(await service.requestOtp(_phone), isA<Ok<dynamic>>());

    final tooSoon = await service.requestOtp(_phone);
    expect((tooSoon as Err).failure, isA<RateLimited>());

    for (var i = 0; i < 4; i++) {
      clock.advance(FakeAuthService.resendCooldown);
      expect(await service.requestOtp(_phone), isA<Ok<dynamic>>());
    }
    clock.advance(FakeAuthService.resendCooldown);
    final sixth = await service.requestOtp(_phone);
    expect((sixth as Err).failure, isA<RateLimited>());
  });

  test('sign_out_clears_the_session', () async {
    final service = _service(AppEnv.dev, clock);
    await service.verifyOtp(_phone, '123456');
    expect(await service.currentSession(), isNotNull);
    await service.signOut();
    expect(await service.currentSession(), isNull);
  });
}
