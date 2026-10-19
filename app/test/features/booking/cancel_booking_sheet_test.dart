import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/presentation/cancel_booking_sheet.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  testWidgets('cancel_after_arrived_shows_dispute_copy', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CancelBookingSheet(
            status: BookingStatus.arrived,
            onCancel: (_) async => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text(kCancelBlockedCopy), findsOneWidget);
    expect(find.text('Confirm Cancel'), findsNothing);
    expect(cancelled, isFalse);
  });

  testWidgets('confirmed_cancel_calls_on_cancel', (tester) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CancelBookingSheet(
            status: BookingStatus.confirmed,
            onCancel: (_) async => cancelled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Changed my plans'));
    await tester.pump();
    await tester.tap(find.text('Confirm Cancel'));
    await tester.pump();

    expect(cancelled, isTrue);
  });
}
