import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/presentation/dispatch_status_copy.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  testWidgets('customer failed-copy on booking details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: DispatchStatusCopy(status: BookingStatus.failed),
        ),
      ),
    );
    expect(find.text(kDispatchFailedCopy), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: DispatchStatusCopy(status: BookingStatus.failed, sos: true),
        ),
      ),
    );
    expect(find.text(kSosDispatchFailedCopy), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: DispatchStatusCopy(status: BookingStatus.confirmed),
        ),
      ),
    );
    expect(find.text(kFindingMechanicCopy), findsOneWidget);
  });
}
