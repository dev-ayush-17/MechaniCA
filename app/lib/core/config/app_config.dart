enum AppEnv { dev, staging, prod }

/// Which `AuthService` adapter the composition root binds.
enum AuthProviderKind {
  fake,
  firebase;

  static AuthProviderKind parse(String value) => AuthProviderKind.values
      .firstWhere((k) => k.name == value, orElse: () => AuthProviderKind.fake);
}

enum LocationProviderKind {
  fake,
  rtdb;

  static LocationProviderKind parse(String value) =>
      LocationProviderKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => LocationProviderKind.fake,
      );
}

enum MapsProviderKind {
  fake,
  google;

  static MapsProviderKind parse(String value) => MapsProviderKind.values
      .firstWhere((k) => k.name == value, orElse: () => MapsProviderKind.fake);
}

enum PaymentsProviderKind {
  fake,
  cashfree;

  static PaymentsProviderKind parse(String value) =>
      PaymentsProviderKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => PaymentsProviderKind.fake,
      );
}

/// Build-time configuration. Business code reads this, never `String.fromEnvironment`.
///
/// Set with `--dart-define-from-file=config/dev.json`.
class AppConfig {
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.useFirebaseEmulator,
    this.providerAuth = AuthProviderKind.fake,
    this.providerLocation = LocationProviderKind.fake,
    this.providerMaps = MapsProviderKind.fake,
    this.providerPayments = PaymentsProviderKind.fake,
    this.mapsApiKey = '',
    this.firebaseEmulatorHost = '10.0.2.2',
    this.useHttpApi = false,
  });

  factory AppConfig.fromEnvironment() => AppConfig(
        env: _parseEnv(
            const String.fromEnvironment('APP_ENV', defaultValue: 'dev')),
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000',
        ),
        useFirebaseEmulator: const bool.fromEnvironment('USE_FIREBASE_EMULATOR',
            defaultValue: true),
        providerAuth: AuthProviderKind.parse(
          const String.fromEnvironment('PROVIDER_AUTH', defaultValue: 'fake'),
        ),
        providerLocation: LocationProviderKind.parse(
          const String.fromEnvironment(
            'PROVIDER_LOCATION',
            defaultValue: 'fake',
          ),
        ),
        providerMaps: MapsProviderKind.parse(
          const String.fromEnvironment('PROVIDER_MAPS', defaultValue: 'fake'),
        ),
        providerPayments: PaymentsProviderKind.parse(
          const String.fromEnvironment(
            'PROVIDER_PAYMENTS',
            defaultValue: 'fake',
          ),
        ),
        mapsApiKey: const String.fromEnvironment('MAPS_API_KEY', defaultValue: ''),
        firebaseEmulatorHost: const String.fromEnvironment(
          'FIREBASE_EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        ),
        useHttpApi: const bool.fromEnvironment('USE_HTTP_API', defaultValue: false),
      );

  final String firebaseEmulatorHost;
  final AuthProviderKind providerAuth;
  final LocationProviderKind providerLocation;
  final MapsProviderKind providerMaps;
  final PaymentsProviderKind providerPayments;
  final String mapsApiKey;
  final AppEnv env;
  final String apiBaseUrl;
  final bool useFirebaseEmulator;
  final bool useHttpApi;

  /// Fake OTP can still talk to FastAPI so Spark Firestore stays the source of truth.
  bool get useRemoteApi =>
      useHttpApi || providerAuth == AuthProviderKind.firebase;

  bool get isProd => env == AppEnv.prod;

  /// A release build must not point at a local server (docs/prd/21-devops.md).
  bool get hasLocalApiUrl =>
      apiBaseUrl.contains('localhost') || apiBaseUrl.contains('10.0.2.2');

  static AppEnv _parseEnv(String value) => AppEnv.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppEnv.dev,
      );
}
