import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechupp_app/core/theme/app_theme.dart';
import 'package:mechupp_app/features/booking/booking_details_screen.dart';
import 'package:mechupp_app/models/booking_model.dart';

void main() {
  testWidgets('Report a problem only after arrived', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: BookingStatus.enRoute.canReportProblem
              ? ReportProblemButton(onPressed: () {})
              : const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Report a problem'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: BookingStatus.arrived.canReportProblem
              ? ReportProblemButton(onPressed: () {})
              : const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Report a problem'), findsOneWidget);
  });
}
