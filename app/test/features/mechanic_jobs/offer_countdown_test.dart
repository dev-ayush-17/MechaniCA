import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/composition/providers.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/mechanic_jobs/data/fake_offer_api.dart';
import 'package:mechupp_app/features/mechanic_jobs/domain/job_offer.dart';
import 'package:mechupp_app/features/mechanic_jobs/presentation/offer_route_screen.dart';

void main() {
  testWidgets('offer_countdown_ticks', (tester) async {
    final api = FakeOfferApi(
      seed: JobOffer(
        id: 'off-1',
        bookingId: 'b1',
        serviceName: 'General Service',
        vehicleType: 'two_wheeler',
        distanceKm: 1.2,
        totalPaise: 76400,
        expiresAt: DateTime.now().add(const Duration(seconds: 8)),
        attempt: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [offerApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OfferRouteScreen(offerId: 'off-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('s left'), findsOneWidget);
    final first = tester.widget<Text>(find.textContaining('s left')).data;

    await tester.pump(const Duration(seconds: 2));
    final later = tester.widget<Text>(find.textContaining('s left')).data;
    expect(later, isNot(first));
  });
}
