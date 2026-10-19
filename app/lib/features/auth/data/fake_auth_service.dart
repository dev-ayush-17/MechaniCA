import '../../../core/config/app_config.dart';
import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../domain/auth_service.dart';

/// Dev and test stand-in for the vendor OTP service. It accepts the demo code
/// [demoOtp] only when the app is not running as prod, and it enforces the
/// same abuse limits as the real flow (docs/prd/11-authentication.md).
class FakeAuthService implements AuthService {
  FakeAuthService({required this.env, required Clock clock}) : _clock = clock;

  static const demoOtp = '123456';
  static const resendCooldown = Duration(seconds: 30);
  static const maxSendsPerHour = 5;
  static const maxFailedVerifies = 5;
  static const lockDuration = Duration(minutes: 15);

  final AppEnv env;
  final Clock _clock;

  final Map<String, List<DateTime>> _sends = {};
  final Map<String, int> _failures = {};
  final Map<String, DateTime> _lockedUntil = {};
  Session? _session;

  static final _e164 = RegExp(r'^\+[1-9]\d{9,14}$');

  @override
  Future<Result<void>> requestOtp(String phoneE164) async {
    if (!_e164.hasMatch(phoneE164)) {
      return const Err(InvalidInput('Enter valid mobile number'));
    }
    final now = _clock.now();
    final recent = (_sends[phoneE164] ?? [])
        .where((t) => now.difference(t) < const Duration(hours: 1))
        .toList();
    if (recent.isNotEmpty && now.difference(recent.last) < resendCooldown) {
      return Err(RateLimited(
        'Please wait before requesting another code.',
        retryAfter: resendCooldown - now.difference(recent.last),
      ));
    }
    if (recent.length >= maxSendsPerHour) {
      return const Err(
          RateLimited('Too many codes requested. Try again later.'));
    }
    _sends[phoneE164] = [...recent, now];
    return const Ok(null);
  }

  @override
  Future<Result<Session>> verifyOtp(String phoneE164, String code) async {
    if (env == AppEnv.prod) {
      // The demo code must never work in a prod build.
      return const Err(Unavailable('Sign-in is not available right now.'));
    }
    final now = _clock.now();
    final lockedUntil = _lockedUntil[phoneE164];
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      return Err(RateLimited(
        'Too many wrong codes. Try again in 15 minutes.',
        retryAfter: lockedUntil.difference(now),
      ));
    }
    if (code != demoOtp) {
      final failures = (_failures[phoneE164] ?? 0) + 1;
      if (failures >= maxFailedVerifies) {
        _failures.remove(phoneE164);
        _lockedUntil[phoneE164] = now.add(lockDuration);
        return const Err(RateLimited(
          'Too many wrong codes. Try again in 15 minutes.',
          retryAfter: lockDuration,
        ));
      }
      _failures[phoneE164] = failures;
      return const Err(InvalidInput('That code is incorrect.'));
    }
    _failures.remove(phoneE164);
    _lockedUntil.remove(phoneE164);
    final session = Session(
      userId: 'fake_${phoneE164.replaceAll('+', '')}',
      // Same shape the backend FakeAuth accepts. Carries no secret.
      idToken: 'fake:fake_${phoneE164.replaceAll('+', '')}:$phoneE164',
      expiresAt: now.add(const Duration(hours: 1)),
      role: 'customer',
    );
    _session = session;
    return Ok(session);
  }

  @override
  Future<Result<Session>> signInWithGoogle() async =>
      const Err(Unavailable('provider_disabled'));

  @override
  Future<Result<void>> signOut() async {
    _session = null;
    return const Ok(null);
  }

  @override
  Future<Session?> currentSession({bool forceRefresh = false}) async =>
      _session;
}
