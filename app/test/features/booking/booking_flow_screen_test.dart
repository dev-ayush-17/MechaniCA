import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/booking_flow_screen.dart';

void main() {
  testWidgets('booking_flow_starts_on_bike_step', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BookingFlowScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Book Service'), findsOneWidget);
    expect(find.text('Step 1: Bike'), findsOneWidget);
  });
}
