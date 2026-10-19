import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/payments/data/fake_earnings_api.dart';
import 'package:mechupp_app/features/payments/presentation/earnings_screen.dart';

void main() {
  testWidgets('earnings_shows_recorded_notice', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          earningsApiProvider.overrideWithValue(FakeEarningsApi()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const EarningsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Recorded earnings. Bank payout is not live yet.'),
      findsOneWidget,
    );
  });
}
