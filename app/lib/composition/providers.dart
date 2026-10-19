/// Composition root: the one place that decides which adapter is live.
///
/// The demo's mock repository providers are re-exported unchanged so existing
/// screens keep working. Each feature milestone replaces its mock binding here.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/generated/export.dart' show RestClient;
import '../core/config/app_config.dart';
import '../core/flags/feature_flags.dart';
import '../core/logging/logger.dart';
import '../core/time/clock.dart';
import '../features/auth/data/adapters/firebase_auth_service.dart';
import '../features/auth/data/fake_account_api.dart';
import '../features/auth/data/fake_auth_service.dart';
import '../features/auth/data/fake_session_store.dart';
import '../features/auth/data/http_account_api.dart';
import '../features/auth/domain/account_api.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/mechanic_onboarding/data/fake_mechanic_repository.dart';
import '../features/mechanic_onboarding/data/http_mechanic_repository.dart';
import '../features/mechanic_onboarding/domain/mechanic_repository.dart';

export '../features/auth/presentation/auth_controller.dart';
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
    AuthProviderKind.fake => FakeAuthService(
        env: config.env,
        clock: ref.watch(clockProvider),
        store: SharedPrefsFakeSessionStore(ref.watch(loggerProvider)),
      ),
    AuthProviderKind.firebase =>
      FirebaseAuthService(config: config, clock: ref.watch(clockProvider)),
  };
});

final restClientProvider = Provider<RestClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  return RestClient(dio, baseUrl: config.apiBaseUrl);
});

/// The offline fake follows the fake auth binding so the demo runs with no
/// server. With Firebase auth the account calls go to the real API.
final accountApiProvider = Provider<AccountApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeAccountApi(),
    AuthProviderKind.firebase => HttpAccountApi(
        client: ref.watch(restClientProvider),
        auth: ref.watch(authServiceProvider),
      ),
  };
});

final mechanicRepositoryProvider = Provider<MechanicRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeMechanicRepository(),
    AuthProviderKind.firebase => HttpMechanicRepository(
        client: ref.watch(restClientProvider),
      ),
  };
});
