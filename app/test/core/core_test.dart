import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica_app/composition/providers.dart';
import 'package:mechanica_app/core/error/result.dart';
import 'package:mechanica_app/core/flags/feature_flags.dart';
import 'package:mechanica_app/core/logging/logger.dart';
import 'package:mechanica_app/core/time/clock.dart';

void main() {
  test('result_when_maps_ok_and_err', () {
    const Result<int> ok = Ok(2);
    const Result<int> err = Err(NotFound());
    expect(ok.when(onOk: (v) => v * 2, onErr: (_) => -1), 4);
    expect(err.when(onOk: (v) => v, onErr: (f) => f.message.length), isPositive);
  });

  test('logger_drops_sensitive_fields', () {
    final logger = RecordingLogger();
    logger.info('sign in', {'token': 'abc', 'Authorization': 'x', 'route': '/me'});
    expect(logger.entries.single.fields, {'route': '/me'});
  });

  test('unknown_flag_is_off', () {
    const flags = StaticFeatureFlags({'auth_google_enabled': true});
    expect(flags.isEnabled('auth_google_enabled'), isTrue);
    expect(flags.isEnabled('never_heard_of_it'), isFalse);
  });

  test('fake_clock_advances', () {
    final clock = FakeClock(DateTime.utc(2026, 10, 19));
    clock.advance(const Duration(minutes: 5));
    expect(clock.now(), DateTime.utc(2026, 10, 19, 0, 5));
  });

  test('composition_root_provides_core_ports', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(clockProvider), isA<SystemClock>());
    expect(container.read(loggerProvider), isA<Logger>());
    expect(container.read(featureFlagsProvider).isEnabled('x'), isFalse);
  });
}
