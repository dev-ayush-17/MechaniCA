enum AppEnv { dev, staging, prod }

/// Which `AuthService` adapter the composition root binds.
enum AuthProviderKind {
  fake,
  firebase;

  static AuthProviderKind parse(String value) => AuthProviderKind.values
      .firstWhere((k) => k.name == value, orElse: () => AuthProviderKind.fake);
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
    this.firebaseEmulatorHost = '10.0.2.2',
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
        firebaseEmulatorHost: const String.fromEnvironment(
          'FIREBASE_EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        ),
      );

  final String firebaseEmulatorHost;
  final AuthProviderKind providerAuth;
  final AppEnv env;
  final String apiBaseUrl;
  final bool useFirebaseEmulator;

  bool get isProd => env == AppEnv.prod;

  /// A release build must not point at a local server (docs/prd/21-devops.md).
  bool get hasLocalApiUrl =>
      apiBaseUrl.contains('localhost') || apiBaseUrl.contains('10.0.2.2');

  static AppEnv _parseEnv(String value) => AppEnv.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppEnv.dev,
      );
}
