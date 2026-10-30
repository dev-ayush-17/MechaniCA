import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/payments/data/fake_payment_api.dart';
import 'package:mechupp_app/features/payments/presentation/pay_step.dart';

void main() {
  testWidgets('client_sdk_success_is_not_paid', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentApiProvider.overrideWithValue(FakePaymentApi()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: PayStep(
              bookingId: 'bkg_1',
              method: 'upi',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pay'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Waiting for confirmation'), findsOneWidget);
    expect(find.text('Paid'), findsNothing);
  });
}
