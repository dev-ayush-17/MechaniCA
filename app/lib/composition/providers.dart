/// Composition root: the one place that decides which adapter is live.
///
/// The demo's mock repository providers are re-exported unchanged so existing
/// screens keep working. Each feature milestone replaces its mock binding here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/flags/feature_flags.dart';
import '../core/logging/logger.dart';
import '../core/time/clock.dart';
import '../features/auth/data/fake_auth_service.dart';
import '../features/auth/domain/auth_service.dart';

export '../providers/app_providers.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final loggerProvider = Provider<Logger>((ref) => const DeveloperLogger());

final featureFlagsProvider =
    Provider<FeatureFlags>((ref) => const StaticFeatureFlags());

/// `PROVIDER_AUTH` picks the adapter. Rollback is the fake binding.
final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake =>
      FakeAuthService(env: config.env, clock: ref.watch(clockProvider)),
    AuthProviderKind.firebase => throw UnsupportedError(
        'PROVIDER_AUTH=firebase is added in a later commit'),
  };
});
