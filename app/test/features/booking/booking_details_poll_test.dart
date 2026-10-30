import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/booking_details_screen.dart';
import 'package:mechupp_app/features/booking/data/fake_booking_api.dart';
import 'package:mechupp_app/features/booking/domain/booking.dart';
import 'package:mechupp_app/models/booking_model.dart';

Booking _seed({BookingStatus status = BookingStatus.confirmed}) => Booking(
      id: 'b1',
      displayNumber: 'MCABCDEF12',
      status: status,
      serviceCode: 'general_service',
      mode: 'instant',
      urgency: 'normal',
      totalPaise: 76464,
      cancelFeePaise: 0,
      version: 1,
      serviceName: 'General Service',
    );

void main() {
  testWidgets('details_get_by_id_does_not_stack_polls', (tester) async {
    final api = FakeBookingApi(
      seed: [_seed()],
      getDelay: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BookingDetailsScreen(bookingId: 'b1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    expect(api.getCalls, greaterThanOrEqualTo(1));
    expect(api.maxInFlightGets, 1);
    expect(find.text('Finding a mechanic'), findsOneWidget);
  });

  testWidgets('paid_booking_stops_polling', (tester) async {
    final api = FakeBookingApi(seed: [_seed(status: BookingStatus.paid)]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BookingDetailsScreen(bookingId: 'b1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(api.getCalls, 1);
  });
}
