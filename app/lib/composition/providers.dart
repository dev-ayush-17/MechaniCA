/// Composition root: the one place that decides which adapter is live.
///
/// The demo's mock repository providers are re-exported unchanged so existing
/// screens keep working. Each feature milestone replaces its mock binding here.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/generated/export.dart' show RestClient;
import '../core/api/generated/vehicles/vehicles_client.dart';
import '../data/local/app_database.dart';
import '../features/vehicles/data/fake_vehicle_repository.dart';
import '../features/vehicles/data/offline_vehicle_repository.dart';
import '../features/vehicles/data/vehicle_local_store.dart';
import '../features/vehicles/data/vehicle_remote_data_source.dart';
import '../features/vehicles/data/vehicle_sync_worker.dart';
import '../features/vehicles/domain/vehicle_repository.dart';
import '../features/vehicles/presentation/vehicles_controller.dart';
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
import '../features/booking/data/fake_booking_api.dart';
import '../features/booking/data/http_booking_api.dart';
import '../features/booking/domain/booking_api.dart';
import '../features/booking/domain/quote_api.dart';
import '../features/catalog/data/cached_quote_api.dart';
import '../features/catalog/data/catalog_local_store.dart';
import '../features/catalog/data/fake_catalog_repository.dart';
import '../features/catalog/data/fake_quote_api.dart';
import '../features/catalog/data/http_catalog_repository.dart';
import '../features/catalog/data/http_quote_api.dart';
import '../features/catalog/data/offline_catalog_repository.dart';
import '../features/catalog/domain/catalog_repository.dart';
import '../features/catalog/domain/catalog_snapshot.dart';
import '../features/mechanic_jobs/data/fake_job_transition_api.dart';
import '../features/mechanic_jobs/data/fake_offer_api.dart';
import '../features/mechanic_jobs/data/http_job_transition_api.dart';
import '../features/mechanic_jobs/data/http_offer_api.dart';
import '../features/mechanic_jobs/domain/job_transition_api.dart';
import '../features/mechanic_jobs/domain/offer_api.dart';
import '../features/mechanic_onboarding/data/fake_mechanic_repository.dart';
import '../features/mechanic_onboarding/data/http_mechanic_repository.dart';
import '../features/mechanic_onboarding/domain/mechanic_repository.dart';
import '../core/api/generated/bookings/bookings_client.dart';
import '../core/api/generated/catalog/catalog_client.dart';
import '../core/api/generated/notifications/notifications_client.dart';
import '../core/api/generated/offers/offers_client.dart';
import '../core/api/generated/quotes/quotes_client.dart';
import '../features/notifications/data/fake_notification_inbox.dart';
import '../features/notifications/data/fake_push_permission.dart';
import '../features/notifications/data/http_notification_inbox.dart';
import '../features/notifications/domain/inbox_notification.dart';
import '../features/notifications/domain/notification_inbox.dart';
import '../features/notifications/domain/pending_deep_link.dart';
import '../features/notifications/domain/push_permission.dart';
import '../features/notifications/presentation/notifications_controller.dart';

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
/// Test and demo hooks can flip this to exercise the offline queue.
final networkOnlineProvider = StateProvider<bool>((ref) => true);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(AppDatabase.openConnection());
  ref.onDispose(db.close);
  return db;
});

final vehicleLocalStoreProvider = Provider<VehicleLocalStore>(
  (ref) => VehicleLocalStore(ref.watch(appDatabaseProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeVehicleRepository(),
    AuthProviderKind.firebase => OfflineVehicleRepository(
        local: ref.watch(vehicleLocalStoreProvider),
        remote: VehicleRemoteDataSource(
          client: VehiclesClient(
            Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
            baseUrl: config.apiBaseUrl,
          ),
          token: () async =>
              (await ref.read(authServiceProvider).currentSession())?.idToken,
        ),
        syncWorker: VehicleSyncWorker(
          local: ref.watch(vehicleLocalStoreProvider),
          remote: VehicleRemoteDataSource(
            client: VehiclesClient(
              Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
              baseUrl: config.apiBaseUrl,
            ),
            token: () async =>
                (await ref.read(authServiceProvider).currentSession())?.idToken,
          ),
        ),
        isOnline: () => ref.read(networkOnlineProvider),
      ),
  };
});

final vehiclesControllerProvider =
    StateNotifierProvider<VehiclesController, VehiclesState>(
  (ref) => VehiclesController(ref.watch(vehicleRepositoryProvider)),
);

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

final jobTransitionApiProvider = Provider<JobTransitionApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeJobTransitionApi(),
    AuthProviderKind.firebase => HttpJobTransitionApi(
        client: BookingsClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
});

final offerApiProvider = Provider<OfferApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeOfferApi(),
    AuthProviderKind.firebase => HttpOfferApi(
        client: OffersClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
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

final catalogLocalStoreProvider = Provider<CatalogLocalStore>(
  (ref) => CatalogLocalStore(ref.watch(appDatabaseProvider)),
);

CatalogRepository _remoteCatalog(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeCatalogRepository(),
    AuthProviderKind.firebase => HttpCatalogRepository(
        client: CatalogClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
}

QuoteApi _remoteQuoteApi(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeQuoteApi(catalog: _remoteCatalog(ref)),
    AuthProviderKind.firebase => HttpQuoteApi(
        client: QuotesClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return OfflineCatalogRepository(
    remote: _remoteCatalog(ref),
    local: ref.watch(catalogLocalStoreProvider),
    isOnline: () => ref.read(networkOnlineProvider),
    clock: ref.watch(clockProvider),
  );
});

final quoteApiProvider = Provider<QuoteApi>((ref) {
  return CachedQuoteApi(
    remote: _remoteQuoteApi(ref),
    local: ref.watch(catalogLocalStoreProvider),
    isOnline: () => ref.read(networkOnlineProvider),
    clock: ref.watch(clockProvider),
  );
});

final bookingApiProvider = Provider<BookingApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeBookingApi(),
    AuthProviderKind.firebase => HttpBookingApi(
        client: BookingsClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
});

final notificationInboxProvider = Provider<NotificationInbox>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeNotificationInbox(),
    AuthProviderKind.firebase => HttpNotificationInbox(
        client: NotificationsClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
});

final notificationsControllerProvider = StateNotifierProvider<
    NotificationsController, AsyncValue<List<InboxNotification>>>(
  (ref) => NotificationsController(ref.watch(notificationInboxProvider)),
);

final pushPermissionProvider =
    Provider<PushPermission>((ref) => FakePushPermission());

final pendingDeepLinkProvider = Provider<PendingDeepLinkStore>(
  (ref) => PendingDeepLinkStore(),
);

final catalogServicesProvider = FutureProvider<CatalogSnapshot>((ref) async {
  final result =
      await ref.watch(catalogRepositoryProvider).listActiveServices();
  final updatedAt = await ref.watch(catalogLocalStoreProvider).lastCachedAt();
  return result.when(
    onOk: (items) => CatalogSnapshot(services: items, updatedAt: updatedAt),
    onErr: (failure) => throw Exception(failure.message),
  );
});
