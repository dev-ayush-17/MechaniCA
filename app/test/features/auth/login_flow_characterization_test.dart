import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica_app/core/theme/app_theme.dart';
import 'package:mechanica_app/features/auth/login_screen.dart';
import 'package:mechanica_app/features/auth/otp_screen.dart';
import 'package:pinput/pinput.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.darkTheme, home: screen),
    ),
  );
  // Let entrance animations finish so no timers stay pending.
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('login_short_phone_shows_validation_message', (tester) async {
    await _pump(tester, const LoginScreen());

    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter valid mobile number'), findsOneWidget);
  });

  testWidgets('otp_screen_has_six_digit_field_and_demo_hint', (tester) async {
    await _pump(tester, const OTPScreen(phone: '9206061999'));

    expect(tester.widget<Pinput>(find.byType(Pinput)).length, 6);
    expect(find.text('Use 123456 for demo'), findsOneWidget);
    expect(find.text('Verify OTP'), findsWidgets);
  });
}
