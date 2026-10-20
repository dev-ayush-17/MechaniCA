/// Composition root: the one place that decides which adapter is live.
///
/// The demo's mock repository providers are re-exported unchanged so existing
/// screens keep working. Each feature milestone replaces its mock binding here.
///
/// M15 admin web binds [AdminApi] in
/// `features/admin/presentation/admin_providers.dart` so `main_admin.dart`
/// never imports this file (maps/camera/RTDB stay out of the admin target).
/// Customer dispute open is [BookingApi.openDispute] on [bookingApiProvider].
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
import '../core/error/result.dart';
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
import '../features/booking/domain/booking.dart';
import '../features/booking/domain/booking_api.dart';
import '../features/home/presentation/home_controller.dart';
import '../features/profile/data/fake_address_api.dart';
import '../features/profile/data/fake_contact_api.dart';
import '../features/profile/data/http_address_api.dart';
import '../features/profile/data/http_contact_api.dart';
import '../features/profile/domain/address_api.dart';
import '../features/profile/domain/contact_api.dart';
import '../features/profile/presentation/addresses_controller.dart';
import '../features/profile/presentation/contacts_controller.dart';
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
import '../features/parts_proof/data/fake_parts_proof_repository.dart';
import '../features/parts_proof/data/http_parts_proof_repository.dart';
import '../features/parts_proof/domain/parts_proof.dart';
import '../features/reviews/data/fake_review_repository.dart';
import '../features/reviews/data/http_review_repository.dart';
import '../features/reviews/domain/review.dart';
import '../core/api/generated/bookings/bookings_client.dart';
import '../core/api/generated/catalog/catalog_client.dart';
import '../core/api/generated/messages/messages_client.dart';
import '../core/api/generated/notifications/notifications_client.dart';
import '../core/api/generated/offers/offers_client.dart';
import '../core/api/generated/quotes/quotes_client.dart';
import '../core/api/generated/tracking/tracking_client.dart';
import '../features/job_chat/data/fake_chat_service.dart';
import '../features/job_chat/data/fake_telephony.dart';
import '../features/job_chat/data/http_chat_service.dart';
import '../features/job_chat/data/http_telephony.dart';
import '../features/job_chat/data/offline_chat_service.dart';
import '../features/job_chat/data/url_launcher_dialer.dart' show Dialer, UrlLauncherDialer;
import '../features/job_chat/domain/chat_service.dart';
import '../features/job_chat/domain/telephony_port.dart';
import '../features/notifications/data/fake_notification_inbox.dart';
import '../features/notifications/data/fake_push_permission.dart';
import '../features/notifications/data/http_notification_inbox.dart';
import '../features/notifications/domain/inbox_notification.dart';
import '../features/notifications/domain/notification_inbox.dart';
import '../features/notifications/domain/pending_deep_link.dart';
import '../features/notifications/domain/push_permission.dart';
import '../features/notifications/presentation/notifications_controller.dart';
import '../features/offers/data/fake_coupon_api.dart';
import '../features/offers/data/http_coupon_api.dart';
import '../features/offers/domain/coupon_api.dart';
import '../features/offers/domain/coupon_offer.dart';
import '../features/invoice/data/fake_invoice_api.dart';
import '../features/invoice/data/http_invoice_api.dart';
import '../features/invoice/data/invoice_file_actions.dart';
import '../features/invoice/domain/invoice.dart';
import '../features/invoice/domain/invoice_api.dart';
import '../features/payments/data/fake_earnings_api.dart';
import '../features/payments/data/fake_payment_api.dart';
import '../features/payments/data/http_earnings_api.dart';
import '../features/payments/data/http_payment_api.dart';
import '../features/payments/domain/earnings.dart';
import '../features/payments/domain/earnings_api.dart';
import '../features/payments/domain/payment_api.dart';
import '../features/wallet/data/fake_wallet_api.dart';
import '../features/wallet/data/http_wallet_api.dart';
import '../features/wallet/domain/wallet_api.dart';
import '../features/wallet/presentation/wallet_controller.dart';
import '../features/tracking/data/adapters/google_maps_service.dart';
import '../features/tracking/data/adapters/rtdb_location_tracking_service.dart';
import '../features/tracking/data/cached_maps_service.dart';
import '../features/tracking/data/fake_location_tracking_service.dart';
import '../features/tracking/data/fake_maps_service.dart';
import '../features/tracking/data/fake_tracking_link_api.dart';
import '../features/tracking/data/http_tracking_link_api.dart';
import '../features/tracking/domain/location_tracking_service.dart';
import '../features/tracking/domain/maps_service.dart';
import '../features/tracking/domain/tracking_link_api.dart';
import '../features/tracking/presentation/tracking_controller.dart';

export '../features/auth/presentation/auth_controller.dart';
export '../providers/app_providers.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final trackingRoleProvider = Provider<String>((ref) => 'customer');

final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.providerLocation == LocationProviderKind.rtdb &&
      config.providerAuth == AuthProviderKind.firebase) {
    return createRtdbLocationTrackingService(
      config: config,
      role: ref.watch(trackingRoleProvider),
    );
  }
  return FakeLocationTrackingService(role: ref.watch(trackingRoleProvider));
});

final mapsServiceProvider = Provider<MapsService>((ref) {
  final config = ref.watch(appConfigProvider);
  final inner =
      config.providerMaps == MapsProviderKind.google && config.mapsApiKey.isNotEmpty
          ? GoogleMapsService(
              dio: Dio(
                BaseOptions(
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                ),
              ),
              apiKey: config.mapsApiKey,
            )
          : FakeMapsService();
  return CachedMapsService(inner: inner, clock: ref.watch(clockProvider));
});

final trackingLinkApiProvider = Provider<TrackingLinkApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeTrackingLinkApi(),
    AuthProviderKind.firebase => HttpTrackingLinkApi(
        client: TrackingClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () => _idToken(ref),
      ),
  };
});

final trackingControllerProvider = StateNotifierProvider.autoDispose
    .family<TrackingController, TrackingUiState, TrackingArgs>((ref, args) {
  return TrackingController(
    bookingId: args.bookingId,
    status: args.status,
    urgency: args.urgency,
    destLat: args.destLat,
    destLng: args.destLng,
    locations: ref.watch(locationTrackingServiceProvider),
    maps: ref.watch(mapsServiceProvider),
    clock: ref.watch(clockProvider),
    links: ref.watch(trackingLinkApiProvider),
  );
});

final loggerProvider = Provider<Logger>((ref) => const DeveloperLogger());

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final config = ref.watch(appConfigProvider);
  return StaticFeatureFlags({
    'masked_call_enabled': config.env != AppEnv.prod,
  });
});

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

final partsProofRepositoryProvider = Provider<PartsProofRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakePartsProofRepository(),
    AuthProviderKind.firebase => HttpPartsProofRepository(
        client: ref.watch(restClientProvider),
      ),
  };
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeReviewRepository(),
    AuthProviderKind.firebase => HttpReviewRepository(
        client: ref.watch(restClientProvider),
      ),
  };
});

final homeBookingsProvider =
    StateNotifierProvider<HomeController, AsyncValue<List<Booking>>>(
  (ref) => HomeController(ref.watch(bookingApiProvider)),
);

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

final chatServiceProvider = Provider<ChatService>((ref) {
  final config = ref.watch(appConfigProvider);
  final ChatService remote = switch (config.providerAuth) {
    AuthProviderKind.fake => FakeChatService(),
    AuthProviderKind.firebase => HttpChatService(
        client: MessagesClient(
          Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
          baseUrl: config.apiBaseUrl,
        ),
        token: () async =>
            (await ref.read(authServiceProvider).currentSession())?.idToken,
      ),
  };
  return OfflineChatService(
    remote: remote,
    isOnline: () => ref.read(networkOnlineProvider),
  );
});

final telephonyPortProvider = Provider<TelephonyPort>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeTelephony(),
    AuthProviderKind.firebase => HttpTelephony(
        client: MessagesClient(
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

final dialerProvider = Provider<Dialer>((ref) => UrlLauncherDialer());

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

Future<String?> _idToken(Ref ref) async {
  return (await ref.read(authServiceProvider).currentSession())?.idToken;
}

final paymentApiProvider = Provider<PaymentApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakePaymentApi(),
    AuthProviderKind.firebase => HttpPaymentApi(
        client: ref.watch(restClientProvider).payments,
        token: () => _idToken(ref),
      ),
  };
});

final walletApiProvider = Provider<WalletApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeWalletApi(),
    AuthProviderKind.firebase => HttpWalletApi(
        client: ref.watch(restClientProvider).wallet,
        token: () => _idToken(ref),
      ),
  };
});

final walletLedgerProvider =
    StateNotifierProvider<WalletLedgerNotifier, WalletLedgerState>(
  (ref) => WalletLedgerNotifier(ref.watch(walletApiProvider)),
);

final couponApiProvider = Provider<CouponApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeCouponApi(),
    AuthProviderKind.firebase => HttpCouponApi(
        client: ref.watch(restClientProvider).coupons,
        token: () => _idToken(ref),
      ),
  };
});

final couponsProvider = FutureProvider<List<CouponOffer>>((ref) async {
  final result = await ref.watch(couponApiProvider).list();
  return result.when(
    onOk: (items) => items,
    onErr: (failure) => throw Exception(failure.message),
  );
});

final earningsApiProvider = Provider<EarningsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeEarningsApi(),
    AuthProviderKind.firebase => HttpEarningsApi(
        client: ref.watch(restClientProvider).mechanic,
        token: () => _idToken(ref),
      ),
  };
});

final earningsProvider = FutureProvider<EarningsList>((ref) async {
  final result = await ref.watch(earningsApiProvider).list();
  return result.when(
    onOk: (items) => items,
    onErr: (failure) => throw Exception(failure.message),
  );
});

final invoiceApiProvider = Provider<InvoiceApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeInvoiceApi(demoFallback: true),
    AuthProviderKind.firebase => HttpInvoiceApi(
        client: ref.watch(restClientProvider).invoices,
        dio: Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )),
        token: () => _idToken(ref),
      ),
  };
});

final invoiceProvider =
    FutureProvider.family<Result<Invoice>, String>((ref, bookingId) {
  return ref.watch(invoiceApiProvider).get(bookingId);
});

typedef SaveInvoicePdf = Future<String> Function(
  String bookingId,
  List<int> bytes,
);
typedef ShareInvoicePdf = Future<void> Function(String path);

final saveInvoicePdfProvider = Provider<SaveInvoicePdf>(
  (ref) => saveInvoicePdf,
);

final shareInvoicePdfProvider = Provider<ShareInvoicePdf>(
  (ref) => shareInvoicePdf,
);

final addressApiProvider = Provider<AddressApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeAddressApi(),
    AuthProviderKind.firebase => HttpAddressApi(
        client: ref.watch(restClientProvider).addresses,
        token: () => _idToken(ref),
      ),
  };
});

final addressesControllerProvider =
    StateNotifierProvider<AddressesController, AddressesState>(
  (ref) => AddressesController(ref.watch(addressApiProvider)),
);

final contactApiProvider = Provider<ContactApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return switch (config.providerAuth) {
    AuthProviderKind.fake => FakeContactApi(),
    AuthProviderKind.firebase => HttpContactApi(
        client: ref.watch(restClientProvider).me,
        token: () => _idToken(ref),
      ),
  };
});

final contactsControllerProvider =
    StateNotifierProvider<ContactsController, ContactsState>(
  (ref) => ContactsController(ref.watch(contactApiProvider)),
);
