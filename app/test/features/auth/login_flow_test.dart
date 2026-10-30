import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/config/app_config.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/auth/presentation/login_screen.dart';
import 'package:mechupp_app/features/auth/presentation/otp_screen.dart';
import 'package:mechupp_app/widgets/shared/app_widgets.dart';
import 'package:pinput/pinput.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  AppEnv env = AppEnv.dev,
  AuthProviderKind auth = AuthProviderKind.fake,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            env: env,
            apiBaseUrl: 'http://localhost:8000',
            useFirebaseEmulator: true,
            providerAuth: auth,
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.darkTheme, home: screen),
    ),
  );
  // Let entrance animations finish so no timers stay pending.
  await tester.pump(const Duration(seconds: 2));
}

bool _continueEnabled(WidgetTester tester) =>
    tester
        .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
        .onPressed !=
    null;

void main() {
  testWidgets('short_phone_does_not_enable_continue', (tester) async {
    await _pump(tester, const LoginScreen());
    expect(_continueEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump();
    expect(_continueEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.pump();
    expect(_continueEnabled(tester), isTrue);
  });

  testWidgets('google_button_is_hidden_while_the_flag_is_off', (tester) async {
    await _pump(tester, const LoginScreen());
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('otp_screen_has_six_digit_field', (tester) async {
    await _pump(tester, const OTPScreen(phone: '9876543210'));
    expect(tester.widget<Pinput>(find.byType(Pinput)).length, 6);
  });

  testWidgets('demo_hint_shows_in_dev_only', (tester) async {
    await _pump(tester, const OTPScreen(phone: '9876543210'));
    expect(find.text('Use 123456 for demo'), findsOneWidget);

    await _pump(
      tester,
      const OTPScreen(phone: '9876543210'),
      env: AppEnv.prod,
      auth: AuthProviderKind.firebase,
    );
    expect(find.text('Use 123456 for demo'), findsNothing);

    await _pump(
      tester,
      const OTPScreen(phone: '9876543210'),
      auth: AuthProviderKind.firebase,
    );
    expect(find.text('Use 123456 for demo'), findsNothing);
  });
}
