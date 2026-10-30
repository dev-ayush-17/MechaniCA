import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/data/fake_booking_api.dart';
import 'package:mechupp_app/features/booking/domain/booking.dart';
import 'package:mechupp_app/features/mechanic_jobs/data/fake_offer_api.dart';
import 'package:mechupp_app/features/mechanic_jobs/domain/job_offer.dart';
import 'package:mechupp_app/features/mechanic_jobs/presentation/mechanic_jobs_screen.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  testWidgets('jobs_list_shows_incoming_offer_and_active_job', (tester) async {
    final offers = FakeOfferApi(
      seed: JobOffer(
        id: 'off-1',
        bookingId: 'b1',
        serviceName: 'General Service',
        vehicleType: 'two_wheeler',
        distanceKm: 1.2,
        totalPaise: 76400,
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        attempt: 1,
      ),
    );
    final bookings = FakeBookingApi(
      seed: [
        const Booking(
          id: 'job-1',
          displayNumber: 'MCABCDEF12',
          status: BookingStatus.enRoute,
          serviceCode: 'general_service',
          mode: 'instant',
          urgency: 'normal',
          totalPaise: 76400,
          cancelFeePaise: 0,
          version: 1,
          serviceName: 'Oil change',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offerApiProvider.overrideWithValue(offers),
          bookingApiProvider.overrideWithValue(bookings),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MechanicJobsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Incoming offer'), findsOneWidget);
    expect(find.text('General Service'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Oil change'), findsOneWidget);
  });
}
