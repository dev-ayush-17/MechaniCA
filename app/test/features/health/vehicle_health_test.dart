import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/data/fake_booking_api.dart';
import 'package:mechupp_app/features/booking/domain/booking.dart';
import 'package:mechupp_app/features/health/domain/vehicle_health.dart';
import 'package:mechupp_app/features/health/health_score_screen.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  test('health_good_within_90_days', () {
    final now = DateTime(2026, 10, 20);
    final health = healthFromLastService(
      now.subtract(const Duration(days: 45)),
      now: now,
    );
    expect(health.band, HealthBand.good);
    expect(health.score, 90);
    expect(
      healthFromLastService(
        now.subtract(const Duration(days: 200)),
        now: now,
      ).band,
      HealthBand.poor,
    );
  });

  testWidgets('health mentions last service', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingApiProvider.overrideWithValue(
            FakeBookingApi(
              seed: [
                Booking(
                  id: 'bk_old',
                  displayNumber: 'MCOLD',
                  status: BookingStatus.paid,
                  serviceCode: 'general_service',
                  mode: 'instant',
                  urgency: 'normal',
                  totalPaise: 76464,
                  cancelFeePaise: 0,
                  version: 1,
                  scheduledStart: DateTime.now().subtract(const Duration(days: 200)),
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HealthScoreScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('last service'), findsWidgets);
    expect(find.text('Poor'), findsWidgets);
  });
}
