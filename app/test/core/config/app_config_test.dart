import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/config/app_config.dart';

AppConfig _config({
  AppEnv env = AppEnv.staging,
  AuthProviderKind auth = AuthProviderKind.fake,
  PaymentsProviderKind payments = PaymentsProviderKind.cashfree,
  String apiBaseUrl = 'https://api.staging.example',
}) {
  return AppConfig(
    env: env,
    apiBaseUrl: apiBaseUrl,
    useFirebaseEmulator: false,
    providerAuth: auth,
    providerPayments: payments,
    useHttpApi: true,
  );
}

void main() {
  test('staging config refuses fake auth', () {
    expect(
      () => _config().ensureLaunchable(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('PROVIDER_AUTH=fake'),
        ),
      ),
    );
  });

  test('staging config refuses fake payments', () {
    expect(
      () => _config(
        auth: AuthProviderKind.firebase,
        payments: PaymentsProviderKind.fake,
      ).ensureLaunchable(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('PROVIDER_PAYMENTS=fake'),
        ),
      ),
    );
  });

  test('dev config allows fake auth', () {
    _config(
      env: AppEnv.dev,
      payments: PaymentsProviderKind.fake,
      apiBaseUrl: 'http://10.0.2.2:8000',
    ).ensureLaunchable();
  });

  test('staging firebase auth with cashfree is launchable', () {
    _config(auth: AuthProviderKind.firebase).ensureLaunchable();
  });
}
