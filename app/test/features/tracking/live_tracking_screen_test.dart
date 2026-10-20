import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/core/time/clock.dart';
import 'package:mechupp_app/features/tracking/data/fake_location_tracking_service.dart';
import 'package:mechupp_app/features/tracking/data/fake_maps_service.dart';
import 'package:mechupp_app/features/tracking/domain/location_point.dart';
import 'package:mechupp_app/features/tracking/domain/tracking_copy.dart';
import 'package:mechupp_app/features/tracking/live_tracking_screen.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 10);

  FakeLocationTrackingService seeded({required DateTime recordedAt}) {
    final svc = FakeLocationTrackingService(role: 'mechanic');
    svc.seed(
      'b1',
      LocationSnapshot(
        mechanic: LocationPoint(
          lat: 25.61,
          lng: 85.14,
          accuracyM: 20,
          recordedAt: recordedAt,
        ),
      ),
    );
    return svc;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeLocationTrackingService locations,
    FakeMapsService? maps,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationTrackingServiceProvider.overrideWithValue(locations),
          mapsServiceProvider.overrideWithValue(maps ?? FakeMapsService()),
          clockProvider.overrideWithValue(FakeClock(now)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LiveTrackingScreen(bookingId: 'b1', status: 'enRoute'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('stale label when the point is old', (tester) async {
    await pumpScreen(
      tester,
      locations: seeded(recordedAt: now.subtract(const Duration(minutes: 2))),
    );
    expect(find.textContaining(kLastSeenPrefix), findsWidgets);
  });

  testWidgets('distance and eta text when the point is fresh', (tester) async {
    await pumpScreen(tester, locations: seeded(recordedAt: now));
    expect(find.text('4.2 km'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
  });

  testWidgets('eta unavailable when maps fail and no recent cache', (tester) async {
    await pumpScreen(
      tester,
      locations: seeded(recordedAt: now),
      maps: FakeMapsService(failRoute: true),
    );
    expect(find.text(kEtaUnavailable), findsOneWidget);
  });
}
