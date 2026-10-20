import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/data/fake_booking_api.dart';
import 'package:mechupp_app/features/history/history_screen.dart';
import 'package:mechupp_app/features/home/domain/home_copy.dart';
import 'package:mechupp_app/features/home/home_screen.dart';
import 'package:mechupp_app/features/wallet/data/fake_wallet_api.dart';

void main() {
  void ignoreOverflowErrors() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    ignoreOverflowErrors();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingApiProvider.overrideWithValue(FakeBookingApi()),
          walletApiProvider.overrideWithValue(FakeWalletApi()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('empty home does not show a mock job', (tester) async {
    await pumpHome(tester);

    expect(find.text(kBookAService), findsOneWidget);
    expect(find.text('Upcoming Booking'), findsNothing);
    expect(find.text('General Service'), findsNothing);
    expect(find.text('Track Booking'), findsNothing);
  });

  testWidgets('home_does_not_invent_a_wallet_total', (tester) async {
    await pumpHome(tester);

    expect(find.textContaining('₹250'), findsNothing);
    expect(find.text('Wallet'), findsOneWidget);
  });

  testWidgets('empty history shows the current empty copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingApiProvider.overrideWithValue(FakeBookingApi()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(kNoServicesYet), findsWidgets);
  });
}
