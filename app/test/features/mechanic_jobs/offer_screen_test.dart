import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/mechanic_jobs/presentation/offer_screen.dart';

void main() {
  testWidgets('offer screen shows job facts and accept reject', (tester) async {
    var accepted = false;
    var rejected = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: OfferScreen(
          serviceName: 'General Service',
          vehicleType: 'two_wheeler',
          distanceKm: 1.2,
          totalPaise: 76400,
          secondsLeft: 45,
          onAccept: () => accepted = true,
          onReject: () => rejected = true,
        ),
      ),
    );

    expect(find.text('General Service'), findsOneWidget);
    expect(find.text('Two wheeler'), findsOneWidget);
    expect(find.text('1.2 km away'), findsOneWidget);
    expect(find.text('₹764'), findsOneWidget);
    expect(find.text('45s left'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(accepted, isTrue);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(rejected, isTrue);
  });
}
