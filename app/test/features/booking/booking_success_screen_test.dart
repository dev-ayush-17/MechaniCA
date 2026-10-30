import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/booking_success_screen.dart';
import 'package:mechupp_app/features/booking/domain/booking.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  testWidgets('success_screen_shows_created_booking_without_mock_list', (tester) async {
    const created = Booking(
      id: 'b-created',
      displayNumber: 'MC99AA11',
      status: BookingStatus.confirmed,
      serviceCode: 'general_service',
      mode: 'instant',
      urgency: 'normal',
      totalPaise: 76464,
      cancelFeePaise: 0,
      version: 1,
      serviceName: 'General Service',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BookingSuccessScreen(
            bookingId: 'b-created',
            booking: created,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MC99AA11'), findsOneWidget);
    expect(find.text('General Service'), findsOneWidget);
    expect(find.text('Pay after the visit'), findsOneWidget);
  });
}
